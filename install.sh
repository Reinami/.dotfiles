DOTFILE_TARGETS=("neovim" "git")
NOTIFICATIONS=false
BASH_RC="$HOME/.bashrc"
SKIP_NOTIFICATIONS=false
GIT_SETUP=false
GIT_SSH_KEY=""
WSL_DETECTED=false

setup() {
    print_cyan "Starting dev environment setup"
    sleep 2
    
    print_yellow "Dealing with WSL shenanigans"
    sleep 2 
    handle_wsl

    print_yellow "Setting up Nix for package management"
    sleep 2
    setup_nix

    print_yellow "Installing packages"
    sleep 2
    install_packages

    print_yellow "Setting up packages"
    sleep 2
    setup_packages "$@"

    print_yellow "Setting up bash"
    sleep 2
    setup_bash

    print_yellow "Setting up nvm"
    sleep 2
    setup_nvm

    print_yellow "Setting up dotfiles"
    sleep 2
    setup_dotfiles

    print_notifications

    print_cyan "Done"
}

setup_nvm() {
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

    nvm install node
    nvm use node
}

setup_dotfiles() {
    local dotfiles_dir="$HOME/.dotfiles"

    if [[ ! -d "$dotfiles_dir" ]]; then
        echo "Error: this is impossible, yay"
        exit 1
    fi

    for target in "${DOTFILE_TARGETS[@]}"; do
        if [[ -d "$dotfiles_dir/$target" ]]; then
            echo "Stowing $target..."
            stow --dir="$dotfiles_dir" --target="$HOME" "$target"
        else
            echo "Warning: $dotfiles_dir/$target does not exist. Skipping."
        fi
    done
}

setup_bash() {
    local git_prompt_line="PROMPT_COMMAND='PS1_CMD1=\$(__git_ps1 \" (%s)\")'; PS1='[\\[\\e[32m\\]\\u\\[\\e[0m\\]@\\[\\e[95m\\]\\h\\[\\e[0m\\] \\[\\e[96m\\]\\w\\[\\e[0m\\]]\\[\\e[90m\\]\${PS1_CMD1}\\[\\e[0m\\] \\[\\e[91m\\]λ\\[\\e[0m\\] '"
    local git_source_line="source ~/.git-prompt.sh"
    local alias_vim_line="alias oldvim='vim'"
    local alias_nvim_line="alias vim='nvim'"
    local system_32_line='export PATH=$PATH:/mnt/c/Windows/System32'

    echo "git_prompt_line: $git_prompt_line"
    echo "git_source_line: $git_source_line"
    echo "alias_vim_line: $alias_vim_line"
    echo "alias_nvim_line: $alias_nvim_line"
    echo "system_32_line: $system_32_line"

    append_to_bashrc "$git_prompt_line"
    append_to_bashrc "$git_source_line"
    append_to_bashrc "$alias_vim_line"
    append_to_bashrc "$alias_nvim_line"
    append_to_bashrc "$system_32_line"
}

setup_packages() {
    local include_git_flag=false
    local include_docker_flag=false

    # Parse arguments for setup_packages
    for arg in "$@"; do
        case $arg in
            --include-git)
                include_git_flag=true
                ;;
            --include-docker)
                include_docker_flag=true
                ;;
        esac
    done

    setup_cron

    if $include_git_flag; then
        setup_git
    fi

    if $include_docker_flag; then
        setup_docker
    fi
}

setup_cron() {
    sudo systemctl start cron
    sudo systemctl enable cron
}

setup_git() {
    if [[ ! -d "$HOME/.ssh" ]]; then
        echo "Creating .ssh directory..."
        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"  # Secure permissions
    fi

    while true; do
        echo 
        read -p "Enter your name on git: " name
        echo    
        read -p "Enter your email on git: " email

        echo "You entered: "
        echo "Name: $name"
        echo "Email: $email"
        
        echo
        read -p "Is this correct? (y/n): " confirm
        
        if [[ $confirm == [yY] ]]; then
            break
        fi    
    done

    ssh-keygen -t rsa -b 4096 -C "$email" -f "$HOME/.ssh/id_rsa_$name" -N ""
    if [ $? -eq 0 ]; then
        echo "SSH Key Generated"
        echo "Public key is located at: $HOME/.ssh/id_rsa_$name.pub"
    else
        echo "Failed to generate SSH Key"
        exit 1
    fi

    git config --global user.name "$name"
    git config --global user.email "$email"

    # Add ssh-agent startup block to ~/.bashrc if it doesn't exist
    ssh_agent_block="# Start ssh-agent if not already running\nif ! pgrep -u \"\$USER\" ssh-agent > /dev/null; then\n    eval \"\$(ssh-agent -s)\"\nfi"

    if ! grep -Fxq "# Start ssh-agent if not already running" "$HOME/.bashrc"; then
        echo -e "\n$ssh_agent_block" >> "$HOME/.bashrc"
    fi

    echo "SSH key setup complete"
    echo "Name: $name"
    echo "Email: $email"
    echo "Filepath: $HOME/.ssh/id_rsa_$name"
    
    GIT_SETUP=true
    GIT_SSH_KEY="$HOME/.ssh/id_rsa_$name.pub"
}

setup_docker() {
    sudo addgroup --system docker
    sudo adduser $USER docker
    newgrp docker
    
    echo "Changing docker.sock permissions"
    sudo chown root:docker /var/run/docker.sock
    sudo chmod g+w /var/run/docker.sock
}   

install_packages() {
    nix-env -iA nixpkgs.neovim
    nix-env -iA nixpkgs.git
    nix-env -iA nixpkgs.gcc
    nix-env -iA nixpkgs.cron
    nix-env -iA nixpkgs.jq
    nix-env -iA nixpkgs.bat
    nix-env -iA nixpkgs.stow
    nix-env -iA nixpkgs.go
}

setup_nix() {
    if command -v nix &>/dev/null; then
        echo "Nix already installed, skipping installation"
    else
        echo "Installing Nix"
        sh <(curl -L https://nixos.org/nix/install) --no-daemon
        . ~/.nix-profile/etc/profile.d/nix.sh    
    fi
}

handle_wsl() {
    if check_wsl; then
        echo "Detected WSL. Running fixes"
        fix_wsl
    else
        echo "Not running on WSL, skipping fixes"
    fi
}

fix_wsl() {
    local wsl_conf="/etc/wsl.conf"
    local temp_file="/tmp/wsl_conf.tmp"
    local path_fix='export PATH=`echo $PATH | tr ":" "\n" | grep -v /mnt/ | tr "\n" ":"`'

    if [[ ! -f "$wsl_conf" ]]; then
        echo "Creating $wsl_conf file"
        sudo touch "$wsl_conf"
    fi

    if grep -q "^\[interop\]" "$wsl_conf"; then
        if grep -q "^appendWindowsPath *= *true" "$wsl_conf"; then
            sudo sed -i 's/^appendWindowsPath *= *true/appendWindowsPath = false/' "$wsl_conf"
        elif ! grep -q "^appendWindowsPath *= *false" "$wsl_conf"; then
            sudo awk '/^\[interop\]/{print; print "appendWindowsPath = false"; next}1' "$wsl_conf" > "$temp_file"
            sudo mv "$temp_file" "$wsl_conf"
        fi
    else
        echo -e "\n[interop]\nappendWindowsPath = false" | sudo tee -a "$wsl_conf" > /dev/null
    fi
    
    # if ! grep -Fq "$path_line" ~/.bashrc; then
    #     echo "$path_line" >> ~/.bashrc
    # fi

    echo "Fixed WSL"
}

check_wsl() {
    local is_wsl=false

    # check /proc/sys/kernel/osrelease
    if grep -qEi "(microsoft|wsl)" /proc/sys/kernel/osrelease; then
        echo "WSL Detected via /proc/sys/kernel/osrelease"
        is_wsl=true
    fi

    # check for WSL_INTEROP env variable
    if [[ -n "$WSL_INTEROP" ]]; then
        echo "WSL detected via WSL_INTEROP environmental variable"
        is_wsl=true
    fi

    # check if wsl.exe runs without error
    if wsl.exe --version &>/dev/null; then
        echo "WSL detected via wsl.exe command."
        is_wsl=true
    fi

    WSL_DETECTED=$is_wsl

    if $is_wsl; then
        return 0
    else
        return 1
    fi
}

# utility functions

append_to_bashrc() {
    local line="$1"
    if ! grep -Fxq "$line" "$BASH_RC"; then
        echo "Appending: $line to $BASH_RC"
        echo "$line" >> "$BASH_RC"
    else
        echo "$line is already present in $BASH_RC"
    fi
}

print_yellow() {
    echo -e "\033[0;33m$1\033[0m"
}

print_cyan() {
    echo -e "\033[0;36m$1\033[0m"
}

print_green() {
    echo -e "\033[0;32m$1\033[0m"
}

print_magenta() {
    echo -e "\033[0;35m$1\033[0m"
}

print_red() {
    echo -e "\033[1;31m$1\033[0m"
}

print_notifications() {
    if ! $NOTIFICATIONS; then
        echo "========================"
        print_green "NOTIFICATIONS"
        echo "========================"

        if $WSL_DETECTED; then
            echo
            print_magenta "WSL2"
            
            echo
            print_green "Fonts"
            echo
            print_yellow "To setup fonts correctly, make sure to unzip and install the fonts in _fonts, and tell WSL to use the font in the settings tab of the cmd window"

            echo
            print_green "Docker"
            echo
            print_yellow "Docker in WSL runs using Docker Desktop, make sure to install docker desktop, and inside docker desktop settins do the following:"
            print_yellow "1. Make sure 'Use the WSL 2 based engine' is checked in the general tab"
            print_yellow "2. Make sure 'Enable integration with my default WSL distro' is checked under Resources > WSL Integration"
            print_yellow "3. Make sure you use the slider to enable the it with 'additional distros'"
            print_yellow "4. Ensure docker is running by running 'docker ps' in the terminal"
            print_yellow "5. If you get 'permission denied, rerun the script with the --setup-docker flag to fix it"
            
            echo
            print_red "  ./install.sh --setup-docker"
        fi

        # Check if Git was set up successfully
        echo
        print_magenta "Git"
        if ! $GIT_SETUP; then
            print_yellow "Git was not set up due to not having the flag to do so. To set it up, rerun the script with the '--setup-git' flag:"
            echo
            print_red "  ./install.sh --setup-git"
        else
            print_yellow "A Git SSH key was setup, unfortunately this can't be scripted because reasons: " 
            print_yellow "Run these commands in order"
            print_red '   eval "$(ssh-agent -s)"'
            print_red "   ssh-add \"$HOME/.ssh/id_rsa_$name\""
            echo
            print_yellow "Add this SSH key to git: "
            echo
            ssh_key_paste=$(cat $GIT_SSH_KEY)
            print_red "$ssh_key_paste"
        fi

        echo
        print_magenta "nvim"
        print_yellow "The first time you run nvim it will take a second to install all the packages"

        echo 
        print_magenta "All"
        print_yellow "Now that everything is setup, you probably should just restart your shell"

        echo
    fi
}

init() {
    local setup_git_flag=false
    local setup_docker_flag=false

    for arg in "$@"; do
        case $arg in
            --setup-git)
                setup_git_flag=true
                ;;
            --setup-docker)
                setup_docker_flag=true
                ;;
            *)
                echo "Unknown argument: $arg"
                echo "Usage: $0 [--setup-git]"
                exit 1
                ;;
        esac
    done

    if $setup_git_flag; then
        SKIP_NOTIFICATIONS=true
        print_cyan "Setting up git"
        setup_git
        print_notifications
        print_cyan "Done"
    elif $setup_docker_flag; then
        # Set the flag here so we don't print out git shenanigans when setting up docker
        SKIP_NOTIFICATIONS=true
        print_cyan "Setting up docker"
        setup_docker
        print_notifications
        print_cyan "Done"
    else
        setup "$@"
    fi

}

init "$@"

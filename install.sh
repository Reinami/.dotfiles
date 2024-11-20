NOTIFICATIONS=false
GIT_SETUP=false
GIT_SSH_KEY=""

setup() {
    print_cyan "Starting dev environment setup"
    sleep 2
    
    print_yellow "Updating OS"
    sudo apt-get update
 
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

    print_notifications

    print_cyan "Done"
}

setup_packages() {
    local include_git_flag=false

    # Parse arguments for setup_packages
    for arg in "$@"; do
        case $arg in
            --include-git)
                include_git_flag=true
                ;;
        esac
    done

    setup_cron

    if $include_git_flag; then
        setup_git
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

    eval "$(ssh-agent -s)"
    ssh-add "$HOME/.ssh/id_rsa_$name"
    if [ $? -eq 0 ]; then
        echo "SSH Key added to agent."
    else
        echo "Failed to add SSH key to agent"
        exit 1
    fi
    
    git config --global user.name "$name"
    git config --global user.email "$email"

    echo "SSH key setup complete"
    echo "Name: $name"
    echo "Email: $email"
    echo "Filepath: $HOME/.ssh/id_rsa_$name"
    
    GIT_SETUP=true
    GIT_SSH_KEY="$HOME/.ssh/id_rsa_$name.pub"
}

install_packages() {
    nix-env -iA nixpkgs.neovim
    nix-env -iA nixpkgs.git
    nix-env -iA nixpkgs.gcc
    nix-env -iA nixpkgs.cron
    nix-env -iA nixpkgs.jq
    nix-env -iA nixpkgs.bat
    nix-env -iA nixpkgs.stow
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
    
    if ! grep -Fq "$path_line" ~/.bashrc; then
        echo "$path_line" >> ~/.bashrc
    fi

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

    if $is_wsl; then
        return 0
    else
        return 1
    fi
}

# utility functions

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
    if ! $GIT_SETUP; then
        NOTIFICATIONS=true
    fi    

    if $NOTIFICATIONS; then
        echo "========================"
        print_green "NOTIFICATIONS"
        echo "========================"
    fi
    # Check if Git was set up successfully
    print_magenta "Git"
    if ! $GIT_SETUP; then
        print_yellow "Git was not set up due to not having the flag to do so. To set it up, rerun the script with the '--setup-git' flag:"
        echo
        print_red "  ./install.sh --setup-git"
    else
        print_yellow "A Git SSH was setup, make sure to add this to your sshkeys on git"
        echo
        ssh_key_paste=$(cat $GIT_SSH_KEY)
        print_red "$ssh_key_paste"
    fi
}

init() {
    local setup_git_flag=false

    for arg in "$@"; do
        case $arg in
            --setup-git)
                setup_git_flag=true
                ;;
            *)
                echo "Unknown argument: $arg"
                echo "Usage: $0 [--setup-git]"
                exit 1
                ;;
        esac
    done

    if $setup_git_flag; then
        print_cyan "Setting up git"
        setup_git
        print_notifications
        print_cyan "Done"
    else
        setup "$@"
    fi

}

init "$@"

# Portable Development Enviornment

This is my own personal development environment meant to be spun up on any machine anywhere. You can use it if you want i guess, but it's mean't for me so i won't make any changes to any of it outside of what i want.

Simply load up any OS command prompt (preferably WSL using ubuntu for now, anything else is untested) and run this command:

```
curl -L https://github.com/Reinami/.dotfiles/archive/refs/heads/master.tar.gz | tar xz && mv .dotfiles-master .dotfiles && cd .dotfiles && ./install.sh
```

## Fpnts

- You'll need to setup the fonts in WSL if you are using that in the _fonts folder. That is done through WSL unfortunately.

## To enable docker in WSL2

- Make sure to have docker desktop installed
- Open docker desktop in windows


Follow all prompts on screen and you will be all set

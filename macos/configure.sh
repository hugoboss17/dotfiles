#!/bin/bash

SHELL_FILE="/etc/shells"
ZPROFILE="$HOME/.zprofile"
FISH_CONFIG="$HOME/.config/fish/config.fish"

if ! grep -q "fish" "$SHELL_FILE"; then
    echo "Adding fish to $SHELL_FILE"
    echo "$(which fish)" | sudo tee -a "$SHELL_FILE" > /dev/null
fi

# Default shell 
sudo dscl . -create /Users/"$USER" UserShell "$(which fish)"

if ! grep -q "aliases" "$FISH_CONFIG"; then
    echo "Adding git aliases"
    echo "source $HOME/Projects/dotfiles/config/git/aliases" | sudo tee -a "$ZPROFILE" > /dev/null
    echo "source $HOME/Projects/dotfiles/config/git/aliases" | sudo tee -a "$FISH_CONFIG" > /dev/null
fi

echo "Adding git functions"
rm -rf "$HOME/.config/fish/functions"
mkdir -p "$HOME/.config/fish/functions"
cp -r $HOME/Projects/dotfiles/config/fish/functions/* "$HOME/.config/fish/functions/"
cp -r $HOME/Projects/dotfiles/config/fish/conf.d/* "$HOME/.config/fish/completions/"

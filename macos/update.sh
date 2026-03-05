#!/bin/bash

RC_FILE="$HOME/.zprofile"

if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    sudo softwareupdate --install-rosetta --agree-to-license
fi

brew update

echo "Updating brew packages.."
brew bundle --file=./Packages/Brewfile

echo "Updating VS Code packages.."
if [ -f "./packages/Vscode" ]; then
    while IFS= read -r ext || [ -n "$ext" ]; do
        ext="${ext%%#*}"
        ext="$(printf '%s' "$ext" | tr -d '\r' | xargs)"
        [ -z "$ext" ] && continue
        code --install-extension "$ext" --force || true
    done < "./packages/Vscode"
fi

#!/bin/bash

RC_FILE="$HOME/.zprofile"

if ! /usr/bin/pgrep oahd >/dev/null 2>&1; then
    sudo softwareupdate --install-rosetta --agree-to-license
fi

if ! command -v brew /dev/null 2>&1; then
    echo "Installing brew.."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
fi

brew update

echo "Installing brew packages.."
brew bundle --file=./Packages/Brewfile

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
for script in "$SCRIPT_DIR/install/"*.sh; do
    [ -f "$script" ] && bash "$script"
done

if [ -f "./packages/Vscode" ]; then
    while IFS= read -r ext || [ -n "$ext" ]; do
        ext="${ext%%#*}"
        ext="$(printf '%s' "$ext" | tr -d '\r' | xargs)"
        [ -z "$ext" ] && continue
        code --install-extension "$ext" --force || true
    done < "./packages/Vscode"
fi


if ! grep -q "/opt/homebrew/bin" "$RC_FILE"; then
    printf "\n# Add Homebrew to PATH\n%s\n" 'export PATH="/opt/homebrew/bin:$PATH"' >> "$RC_FILE"
fi
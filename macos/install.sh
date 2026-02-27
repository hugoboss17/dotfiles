#!/bin/bash

echo "Installing brew.."
if ! command -v brew /dev/null 2>&1; then
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

echo "Updating brew.."
brew update

echo "Installing brew packages.."
brew bundle --file=./Brewfile

echo "Installation Setup complete!"

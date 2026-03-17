#!/bin/bash

if [ $# -eq 0 ]; then
    cat ~/Projects/dotfiles/docs/index
    exit
fi

if [ -f ~/Projects/dotfiles/docs/$1 ]; then
    cat ~/Projects/dotfiles/docs/$1
else
    echo "error: argument not found."
fi

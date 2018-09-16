#!/bin/bash

if [ $# -eq 0 ]; then
    cat ~/Projects/dotfiles/docs/myhelp/index
    exit
fi

if [ -f ~/Projects/dotfiles/docs/myhelp/$1 ]; then
    cat ~/Projects/dotfiles/docs/myhelp/$1
else
    echo "error: argument not found."
fi

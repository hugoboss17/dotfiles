#!/bin/bash

install_dependencies() {
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
    brew install dpkg
    brew install wget
}

install_dependencies

for package in `cat inc/macos/brew-packages.list`; do
    running $package
    if [ -f /usr/bin/"$package" ]; then
        ok
        continue
    fi
    if ! dpkg --get-selections | grep -q "^$package[[:space:]]*install$" >/dev/null; then
        brew install $package -y
        if [ $? != 0 ]; then
            error "failed to install $package! aborting..."
            exit
        fi
    fi
    ok
done

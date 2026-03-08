#!/bin/bash

install() {
    bot "Installing for $OS"
    chmod +x $OS/install.sh
    source $OS/install.sh
    bot "Installed for $OS"
}

configure() {
    bot "Configuring for $OS"
    chmod +x $OS/configure.sh
    source $OS/configure.sh
    bot "Configured for $OS"
}

update() {
    bot "Updating for $OS"
    chmod +x $OS/update.sh
    source $OS/update.sh
    bot "Updated for $OS"
}

all() {
    sudo -v

while true; do
    sudo -n true
    sleep 60
    kill -0 "$$" || exit
done 2>/dev/null &
    install &&
    configure
}

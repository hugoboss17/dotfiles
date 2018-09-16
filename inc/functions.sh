#!/bin/bash

install() {
    echo 
    bot "Installing for $OS"
    echo
    chmod +x $OS/install.sh
    source $OS/install.sh
    echo
    echo "Installed"
}

configure() {
    echo 
    bot "Configuring for $OS"
    echo
    chmod +x $OS/configure.sh
    source $OS/configure.sh
    echo
    echo "Configured"
}

update() {
    echo 
    bot "Updating for $OS"
    echo
    chmod +x $OS/update.sh
    source $OS/update.sh
    echo
    echo "Updated"
}

all() {
    install
    #update
    configure
}

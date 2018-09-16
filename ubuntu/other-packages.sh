#!/bin/bash

fish() {
    apt-add-repository ppa:fish-shell/release-2 &>>$LOG
    apt update &>>$LOG
    apt install fish &>>$LOG
}

omf() {
    # Additional check
    if [ -e ~/.config/fish/conf.d/omf.fish ]; then
        return 1
    fi
    curl -qL https://get.oh-my.fish &>>$LOG | fish
}

sublime() {
    # Additional check
    if [ -e /usr/share/applications/sublime_text.desktop ]; then
        return 1
    fi

    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    apt install apt-transport-https &> $LOG
    echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list &>>$LOG
    apt update &>>$LOG
    apt install sublime-text &>>$LOG
}

vagrant() {
    wget https://releases.hashicorp.com/vagrant/2.1.5/vagrant_2.1.5_x86_64.deb -O ~/Downloads/vagrant.deb &>>$LOG
    dpkg -i ~/Downloads/vagrant.deb &>>$LOG
    rm ~/Downloads/vagrant.deb
}

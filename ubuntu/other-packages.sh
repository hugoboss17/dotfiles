#!/bin/bash

fish() {
    if [ ! -f /etc/apt/sources.list.d/fish-shell-ubuntu-nightly-master-cosmic.list ]; then
        yes "" | add-apt-repository ppa:fish-shell/nightly-master &>>$APP_LOG
    fi
    apt-get update &>>$APP_LOG
    apt-get install -y fish &>>$APP_LOG
}

omf() {
    if [ ! -f install ]; then
        curl -s https://get.oh-my.fish > install
    fi
    ./install --noninteractive &>>$APP_LOG
}

sublime() {
    if [ -f /usr/bin/subl ]; then
        return 1
    fi
    wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | sudo apt-key add -
    apt install apt-transport-https &>>$APP_LOG
    if [ ! -f /etc/apt/source.list.d/sublime-text.list ]; then
        echo "deb https://download.sublimetext.com/ apt/stable/" | sudo tee /etc/apt/sources.list.d/sublime-text.list &>>$APP_LOG
    fi
    apt update &>>$APP_LOG
    apt install -y sublime-text &>>$APP_LOG
}

vagrant() {
    wget https://releases.hashicorp.com/vagrant/2.1.5/vagrant_2.1.5_x86_64.deb -O ~/Downloads/vagrant.deb &>>$APP_LOG
    dpkg -i ~/Downloads/vagrant.deb &>>$APP_LOG
    rm ~/Downloads/vagrant.deb
}

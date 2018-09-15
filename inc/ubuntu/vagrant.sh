#!/bin/bash

echo "Vagrant:"

wget https://releases.hashicorp.com/vagrant/2.1.5/vagrant_2.1.5_x86_64.deb -O ~/Downloads/vagrant.deb &>/dev/null
echo "downloaded"

dpkg -i ~/Downloads/vagrant.deb &>/dev/null
echo "installed"

rm ~/Downloads/vagrant.deb
echo "installer removed"
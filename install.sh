#!/bin/bash

user=$(whoami)

apt-packages=(
  gnome-tweak-tool
  fish
  guake
  htop
  
)

wget-packages=(
  ansible
  build-essential
  cowsay
  git-core
  htop
)

sudo apt-get install gnome
sudo dpkg-reconfigure lightdm


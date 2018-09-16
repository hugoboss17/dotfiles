#!/bin/bash

##
# Fish
# 
running 'fish'
omf install cbjohnson &>>$LOG

cp -r config/fish/functions/ ~/.config/fish/functions/ 

if [ $? != 0 ]; then
    error "failed to configure fish! aborting..."
    exit
fi
ok
##
# Sublime
##

running 'sublime'
wget https://packagecontrol.io/Package%20Control.sublime-package -O ~/.config/sublime-text-3/Installed Packages/Package%20Control.sublime-package
cp -r config/sublime/packages/ ~/.config/sublime-text-3/Packages/User/
if [ $? != 0 ]; then
    error "failed to configure sublime! aborting..."
    exit
fi
ok
#for package in `cat inc/ubuntu/apt-packages.list`; do
#    if ! dpkg --get-selections | grep -q "^$package[[:space:]]*install$" >/dev/null; then
#        echo "Installing $package"
#        apt install $package &>/dev/null
#    fi
#    ok
#done

#chmod +x inc/ubuntu/other-packages.sh
#bash inc/ubuntu/other-packages.sh

#apt install -fy &>/dev/null
#echo "dependencies installed"

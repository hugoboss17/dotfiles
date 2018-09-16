#!/bin/bash

for package in `cat inc/macos/apt-packages.list`; do
    echo $package
    ALREADY='already'
    if ! dpkg --get-selections | grep -q "^$package[[:space:]]*install$" >/dev/null; then
        apt install $package -y
        ALREADY=''
    fi
    echo "$package $already installed"
done

chmod +x inc/macos/other-packages.sh
bash inc/macos/other-packages.sh

apt install -fy &>/dev/null
echo "dependencies installed"

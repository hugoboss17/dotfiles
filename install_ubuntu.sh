#!/bin/bash

for package in `cat inc/ubuntu/apt-packages.list`; do
	apt install $package -y &>/dev/null
	echo "$package installed"
done

for package in inc/ubuntu/other-packages/*.sh; do
	chmod +x $package
    bash ./$package
done

apt update -y &>/dev/null
echo "source lists updated"

apt install -fy &>/dev/null
echo "dependencies installed"

apt autoremove -y &>/dev/null
echo "removed unused packages"

exit 0
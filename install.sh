#!/bin/bash

function letsInstall() {
	echo "$1"
}

source args.sh

for package in $packages do
	letsInstall $package
done

#sudo apt-get install gnome
#sudo dpkg-reconfigure lightdm
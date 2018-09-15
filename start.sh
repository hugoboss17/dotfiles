#!/bin/bash

if [ "$1" = ubuntu ]; then
	echo "will install & configure ubuntu dotfiles"
	bash ./install_ubuntu.sh
elif  [ "$1" = macos ]; then
	echo "will install & configure macos dotfiles"
	#sh install_macos.sh
	# TODO install_macos.sh
else
	echo "no dotfiles found"
	exit 0
fi
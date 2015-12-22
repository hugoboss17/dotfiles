#!/bin/bash

function bytes_for_humans() {
	if [ $1 -eq 0 ]
	then
		echo "System already cleaned"
	else
		echo $1 | awk '{ sum=$1 ; hum[1024**3]="Gb";hum[1024**2]="Mb";hum[1024]="Kb"; for (x=1024**3; x>=1024; x/=1024){ if (sum>=x) { printf "%.2f %s\n",sum/x,hum[x];break } }}'
	fi
}

function clean_up() {
	# packages cleaner
	sudo apt-get clean
	sudo apt-get autoclean
	sudo apt-get autoremove -y

	# clean up or compress log files
	#logrotate

	# clean up trash
	rm -rf ~/.local/share/Trash/*
}

# get used space before cleaner
cur_space=$(df | awk '{if($3 != "Used" && $3 > 0)print $3}' | awk '{sum+=$1} END {print sum}')

#clean up your system
clean_up

# get used space after cleaner
after_space=$(df | awk '{if($3 != "Used" && $3 > 0)print $3}' | awk '{sum+=$1} END {print sum}')

# get difference
cleaned=$(expr $cur_space - $after_space)
cleaned=$(expr $cleaned \* 1000)
cleaned=$(bytes_for_humans "$cleaned")

# send notification with cleaned space
notify-send -i "~/Projects/dotfiles/docs/img/cleaner.png" "Cleaner" "Total cleaned: $cleaned"
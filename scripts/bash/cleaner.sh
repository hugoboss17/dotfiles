#!/bin/bash

function bytes_for_humans() {
	if [ $1 -lt 1 ]
	then
		echo "System already cleaned"
	else
		if [ $1 -lt 1024 ]
		then
			type="KB"
			arg=1
		elif [ $1 -gt 1023 ] && [ $1 -lt 1048576 ] 
		then
			type="MB"
			arg=1024
		elif [ $1 -gt 1048575 ]
		then
			type="GB"
			arg=$(expr 1024**2)
		fi
		total=$(awk "BEGIN{print $1 / $arg}")
		echo "$total $type"
	fi
}

function clean_up() {
	# packages cleaner
	apt-get clean &>/dev/null
	apt-get autoclean  &>/dev/null
	apt-get autoremove -y &>/dev/null

	# clean up or compress log files
	logrotate --force /etc/logrotate.conf

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
cleaned=$(bytes_for_humans "$cleaned")

date=$(date +'%d-%m-%Y %T')
echo "$date : $cleaned" >> ~/Projects/dotfiles/logs/cleaner.log

notify-send "Cleaned!" "$cleaned"

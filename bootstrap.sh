#!/bin/bash

source inc/args.sh
source inc/messages.sh
source inc/functions.sh

echo "" > $LOG

if [ $# -eq 0 ]; then
doHelp
fi

while getopts o:t: option
do
    case "${option}"
    in
    o) OS=${OPTARG};;
    t) TYPE=${OPTARG};;
    esac
done

$TYPE

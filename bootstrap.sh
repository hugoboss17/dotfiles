#!/bin/bash

source inc/args.sh
source inc/messages.sh
source inc/functions.sh

touch $APP_LOG

if [ $# -eq 0 ]; then
    doHelp
fi

while getopts t: option
do
    case "${option}"
    in
    t) TYPE=${OPTARG};;
    esac
done

TYPE="$1"

# Auto-detect OS
if [[ "$(uname -s)" == "Darwin" ]]; then
    OS="macos"
elif [[ -f /etc/os-release ]]; then
    . /etc/os-release
    if [[ "${ID,,}" == "ubuntu" || "${ID_LIKE,,}" == *ubuntu* ]]; then
        OS="ubuntu"
    else
        OS="${ID,,}"
    fi
else
    OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
fi

"$TYPE"
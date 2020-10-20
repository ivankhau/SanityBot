#!/bin/bash

echo  $'\n\n\n\n\n\n\n\n\n\n\n\n\n\n'; clear
echo -e "\033[1m##============================================================##\033[0m"
echo -e "\033[1m##===================  AppleConnect Login  ===================##\033[0m"
echo -e "\033[1m##============================================================##\033[0m"

SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
/usr/local/bin/appleconnect authenticate -a splgofer_bot --password-file=${SCRIPT_PATH}/auth

if [[ $? == 0 ]]; then
    echo -e "\033[1mAppleConnect Login Success\033[0m"
else
    echo -e "\033[1mAppleConnect Login Failure, Exit Code: $?\033[0m"
    exit $?
fi

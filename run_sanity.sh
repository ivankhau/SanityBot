#!/bin/bash
#### loops sanity bot

HEADER () {
    echo ""
    echo -e "\033[1m## $1\033[0m"
    echo -e "\033[1m##==================================================##\033[0m"
}

PRINT () {
    echo -e "\033[1m<> $(date '+%d/%m/%Y %H:%M:%S') <>\033[0m $1"
}

print () {
    echo $1
}

SPACER () {
    echo ""
}

while true
do
  HEADER "Looping Sanity Script"
  SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
  $SCRIPT_PATH/sanity_bot.sh
  PRINT "Iteration Complete"
  HEADER "Wait 12 minutes"
  sleep 720
done

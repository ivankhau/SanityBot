#!/bin/bash
#### Sends bot message to Mattermost
# usage: ./mattermost.sh <mattermost webhook> <message>

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

if [[ ! $1 ]]; then
  PRINT "Error, you must enter a webhook address. usage: ./mattermost.sh <mattermost webhook> <message>"
  exit 1
fi

if [[ ! $2 ]]; then
  PRINT "Error, you must enter a message. usage: ./mattermost.sh <mattermost webhook> <message>"
  exit 2
fi

############ Post Result to Mattermost ############
HEADER "Post Results to Mattermost"
POST_TEST="$2"
POST_TEXT="{\"text\": \"$POST_TEST\"}"
SPACER
PRINT "Posting text to Mattermost:"
echo "$POST_TEST"
SPACER
PRINT "JSON format:"
echo "$POST_TEXT"
PRINT "Posting to Mattermost..."
curl -i -X POST -H 'Content-Type: application/json' -d "$POST_TEXT" $1

if [[ $? -ne 0 ]] ; then
    PRINT "ERROR: Invalid URL"
    exit $?
fi
exit 0

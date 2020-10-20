#!/bin/bash
#### Downloads latest bundle, restores unit, sends message if restore fail/success, if success runs sanity sequence, posts sanity results.

## <> Todo: remove eos-restore locks, send email, need to touch finder after 15 minutes and if unable send another message that unit failed to boot.


SCRIPT_PATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
PROJECT=""
TRAIN=""
TIMEOUT=""
MATTERMOST=""
LATEST_BUNDLE=""
AUTH_FILE="${SCRIPT_PATH}/appleconnect/auth"
AUTH=`cat "$AUTH_FILE"`
CACHE_FILE=""
CACHE=""

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

mattermost() {
    $SCRIPT_PATH/mattermost.sh $MATTERMOST "$1"
}

echo  $'\n\n\n\n\n\n\n\n\n\n\n\n\n\n'; clear
echo -e "\033[1m##============================================================##\033[0m"
echo -e "\033[1m##===============  SPLGofer Sanity Regression  ===============##\033[0m"
echo -e "\033[1m##============================================================##\033[0m"
SPACER

############ INITIAL SETUP ############
HEADER "Initializing Settings"
PRINT "Script Path: $SCRIPT_PATH"
PRINT "Searching for settings.txt"
if [[ ! -f "$SCRIPT_PATH/settings.txt" ]]; then
    PRINT "$SCRIPT_PATH/settings.txt"
    PRINT "File not found! Creating Settings file"
    PRINT "ERROR: Need to set Settings File"
    touch "$SCRIPT_PATH/settings.txt"
    exit 22
else
    PRINT "Settings.txt found, checking formatting..."
    PRINT "Setting project and train variables..."
    SPACER
    SETTINGS_TEXT=`cat "$SCRIPT_PATH/settings.txt"`
    echo "$SETTINGS_TEXT"
    while read -r line; do
        if [[ "$line" = ""  ]]; then
            continue
        fi
        if [[ "$line" = *"project="* ]]; then
            PROJECT=${line:8}
        fi
        if [[ "$line" = *"train="* ]]; then
            TRAIN=${line:6}
        fi
        if [[ "$line" = *"timeout="* ]]; then
            TIMEOUT=${line:8}
        fi
        if [[ "$line" = *"mattermost="* ]]; then
            MATTERMOST=${line:11}
        fi
    done <<< "$SETTINGS_TEXT"

    if [[ "$PROJECT" = "" ]]; then
        PRINT "Settings not set, exiting. Make sure you set project, train, timeout, and mattermost in settings.txt"
        exit 4
    fi
    if [[ "$TRAIN" = "" ]]; then
        PRINT "Settings not set, exiting. Make sure you set project, train, timeout, and mattermost in settings.txt"
        exit 4
    fi
    if [[ "$TIMEOUT" = "" ]]; then
        PRINT "Settings not set, exiting. Make sure you set project, train, timeout, and mattermost in settings.txt"
        exit 4
    fi
    if [[ "$MATTERMOST" = "" ]]; then
        PRINT "Settings not set, exiting. Make sure you set project, train, timeout, and mattermost in settings.txt"
        exit 4
    fi
    SPACER
    PRINT "Project found: $PROJECT"
    PRINT "Train found: $TRAIN"
    PRINT "Timeout found: $TIMEOUT seconds"
    PRINT "Mattermost found: $MATTERMOST"
fi


SPACER
PRINT "Searching for cache.txt"
CACHE_FILE="$SCRIPT_PATH/cache.txt"
if [[ ! -f "$SCRIPT_PATH/cache.txt" ]]; then
    echo "$SCRIPT_PATH/cache.txt"
    echo "File not found! Creating cache file..."
    touch "$SCRIPT_PATH/cache.txt"
else
    PRINT $'Cache.txt found, processing...'
fi
CACHE=`cat "$CACHE_FILE"`

BUNDLE_URL="https://cd.apple.com/CDs/$TRAIN/"
TRAIN_NAME=""

############ Connect to AppleConnect and get DAW token ############
HEADER "Connect to AppleConnect"
${SCRIPT_PATH}/appleconnect/appleconnect_login.sh
if [[ $? == 0 ]]; then
    PRINT "Connected to AppleConnect"
else
    PRINT "Could not connect to AppleConnect, error code $?"
    exit $?
fi
HEADER "Get DAW Token"
DAW_TOKEN=`${SCRIPT_PATH}/daw_token.py`
echo "DAW Token: $DAW_TOKEN"
#BUNDLE_URL="https://cd.apple.com/CDs/"
#bundles="$(curl -s --user ivan_khau:$DAW_TOKEN $BUNDLE_URL)"
#echo "$bundles"
#exit 69


############ Get Latest Bundle Download URL ############
HEADER "CURL Bundles and Parse Latest Bundle"
bundles="$(curl -s --user splgofer_bot:$DAW_TOKEN $BUNDLE_URL)"
if [[ $? != 0 ]]; then
    PRINT "Error: Could not get bundle list"
    exit 4
fi

if [[ "$bundles" = *"404 Not Found"* ]]; then
    PRINT "Error: 404 Not Found"
    exit 49
fi

if [[ "$bundles" = *"nauthorized"* ]]; then
    PRINT "Error: Unauthorized - Westgate authorization failed/denied."
    exit 49
fi


echo ""
PRINT "CURL bundles..."
echo "$bundles"
echo ""
PRINT "Parse latest bundle..."
bundle_last_line=""
while read -r line; do
    if [[ $line == *"alt=\"[DIR]\""* ]]; then
        bundle_last_line=$line
    fi
done <<< "$bundles"
TEMP=${bundle_last_line#*href=\"}
LATEST_BUNDLE=${TEMP%%/\"*}
print "Latest Bundle: $LATEST_BUNDLE"

## Check if bundle has been previously processed
if [[ "$CACHE" = *$LATEST_BUNDLE* ]]; then
  PRINT "$LATEST_BUNDLE has already been processed. Skipping..."
  exit 49
else
  PRINT "$LATEST_BUNDLE has not been processed. Processing..."
fi

if [[ "$LATEST_BUNDLE" = "" ]]; then
    PRINT "NO bundle found, exiting..."
    exit 7
fi

BUNDLE_URL_TEMP="$BUNDLE_URL$LATEST_BUNDLE/$PROJECT-Factory-Diagnostics-ASR/"
PRINT "Curl path: $BUNDLE_URL_TEMP"
CURL_DMG="$(curl -s --user splgofer_bot:$DAW_TOKEN $BUNDLE_URL_TEMP)"

if [[ $? != 0 ]]; then
    PRINT "Factory Diagnostics ASR not found... exiting..."
    exit $?
fi
echo "$CURL_DMG"

if [[ "$CURL_DMG" = *"404 Not Found"* ]]; then
    PRINT "Error: 404 Not Found."
    exit 49
fi

if [[ "$CURL_DMG" = *"nauthorized"* ]]; then
    PRINT "Error: Unauthorized - Westgate authorization failed/denied."
    exit 49
fi

PRINT "Parse bundle dmg URL..."
bundle_last_line=""
while read -r line; do
    if [[ $line == *"alt=\"[   ]\""* ]]; then
        bundle_last_line=$line
    fi
done <<< "$CURL_DMG"
TEMP=${bundle_last_line#*href=\"}
BUNDLE_DMG_URL=${TEMP%%\">*}
PRINT "DMG NAME: $BUNDLE_DMG_URL"

BUNDLE_DMG_DOWNLOAD_PATH="$BUNDLE_URL_TEMP$BUNDLE_DMG_URL"
PRINT "Latest Bundle Download URL: $BUNDLE_DMG_DOWNLOAD_PATH"

## If DMG doesn't exist, exit.
echo "$BUNDLE_DMG_DOWNLOAD_PATH"
DMG_SUB=".dmg"
if [[ "$BUNDLE_DMG_DOWNLOAD_PATH" != *".dmg"*  ]]; then
    PRINT "Not a dmg, exiting..."
    exit 9
fi

PRINT "Deleting temp files."
rm -rf /tmp/gofer/
PRINT "Creating temp folder."
mkdir /tmp/gofer/

############ Download Bundle ############
HEADER "Downloading Latest Bundle"
PRINT "Bundle: $BUNDLE_DMG_URL"
PRINT "Bundle URL: $BUNDLE_DMG_DOWNLOAD_PATH"

if [[ ! -f /tmp/gofer/$(basename $BUNDLE_DMG_DOWNLOAD_PATH) ]]; then
    PRINT "$(basename $BUNDLE_DMG_DOWNLOAD_PATH) not found, downloading bundle..."
    SPACER
    echo `curl -L --user splgofer_bot:$DAW_TOKEN -v -o /tmp/gofer/$(basename $BUNDLE_DMG_DOWNLOAD_PATH) ${BUNDLE_DMG_DOWNLOAD_PATH}`
    if [[ $? != 0 ]]; then
        echo "##  Error downloading bundle, exiting...  ##"
        exit $?
    fi
else
    echo "$(basename $BUNDLE_DMG_DOWNLOAD_PATH) already exists, skipping download."
fi
/bin/sleep 3

############ Connect to AppleConnect ############
# HEADER "Connect to AppleConnect"
# ${SCRIPT_PATH}/appleconnect/appleconnect_login.sh
# if [[ $? == 0 ]]; then
#     PRINT "Connected to AppleConnect"
# else
#     PRINT "Could not connect to AppleConnect, error code $?"
#     exit $?
# fi

## Append bundle name to cache
PRINT "Appending ${LATEST_BUNDLE} to "$CACHE_FILE""
echo "${LATEST_BUNDLE}" >> "$CACHE_FILE"

############ Invoke eos-restore ############
HEADER "Invoking eos-restore, bundle: $(basename $BUNDLE_DMG_DOWNLOAD_PATH)"
PRINT "Invocation: /usr/bin/sudo /usr/local/bin/eos-restore --dti --ignore-matching-bridgeos --erase --passwordless --efi-diag 30 --noprompt --macos /tmp/gofer/$(basename $BUNDLE_DMG_DOWNLOAD_PATH)"
/usr/bin/sudo /usr/local/bin/eos-restore --dti --ignore-matching-bridgeos --erase --passwordless --efi-diag 30 --noprompt --macos /tmp/gofer/$(basename $BUNDLE_DMG_DOWNLOAD_PATH)

############ Post Restore Result to Mattermost ############
if [[ $? == 0 ]]; then
    PRINT "Restoration success without error"
    mattermost "Project: ${PROJECT}\nTrain: ${TRAIN}\nLatest Bundle: ${LATEST_BUNDLE}\nRestore: Success"
else
    PRINT "Restoration failed, error code $?"
    mattermost "Project: ${PROJECT}\nTrain: ${TRAIN}\nLatest Bundle: ${LATEST_BUNDLE}\nError: Restore Failed"
    exit $?
fi

/bin/sleep 5

HEADER "Sleeping for 15 minutes, to apply DTI preferences."
/bin/sleep 900


HEADER "Additional Post Restore Setup"
/usr/local/bin/eos-ssh -x nvram skip_network_handshake=1

PRINT "Searching for local Sanity lua sequence..."
if [[ ! -f $SCRIPT_PATH/sanity.lua ]]; then
    PRINT "No local Sanity lua sequence found."
else
    PRINT "Local Sanity lua sequence found, transfering..."
    eos-scp -x $SCRIPT_PATH/sanity.lua eos:/AppleInternal/Diags/Astro/Flows/J160/
fi


HEADER "Kicking off Regression"
echo "Adding bootarg..."
/usr/local/bin/eos-ssh -x OSDToolbox bootargs -a astro=sanity
echo "Rebooting to start testing..."
/usr/local/bin/eos-ssh -x reboot


HEADER "Monitering Runin Status..."
TEST_COMPLETE=false
TEST_START=$(date '+%d/%m/%Y %H:%M:%S')
PRINT "Test Start: $TEST_START"
CURRENT_TIME=$(date '+%d/%m/%Y %H:%M:%S')
TIME_ELAPSED=0

ASTRO_STATUS=""
while [[ $TEST_COMPLETE = false ]] ; do
    PRINT "Wait 120 seconds..."
    sleep 120

    TIME_ELAPSED=$((TIME_ELAPSED + 120))
    PRINT "Time Elapsed: $TIME_ELAPSED seconds"

    PRINT "Checking Status"
    #ASTRO_STATUS="`/usr/local/bin/eos-ssh -x astro status | awk '{if(NR>1)print}'`"
    ASTRO_STATUS="`/usr/local/bin/eos-ssh -x astro status`"

    if (( $TIME_ELAPSED > $TIMEOUT )); then
        PRINT "Runin timed out"
        PRINT "Time Elapsed: $TIME_ELAPSED seconds"
        PRINT "Timeout limit: $TIMEOUT seconds"
        PRINT "Exiting..."

        ############ Post Result to Mattermost ############
        mattermost "#### **SPL Automated Sanity Timeout**\n\nProject: ${PROJECT}\nTrain: ${TRAIN}\nLatest Bundle: ${LATEST_BUNDLE}\nTimeout: ${TIMEOUT} seconds\nError: Sequence timed out, hang or panic.\n\n${ASTRO_STATUS} \n\n"

        exit 69
    fi

    if [[ $ASTRO_STATUS == *"Status: Complete"* ]]; then
        PRINT "Flow Complete"
        TEST_COMPLETE=true
    else
        PRINT "Test Running, Flow Incomplete"
    fi
    CURRENT_TIME=$(date '+%d/%m/%Y %H:%M:%S')
    PRINT "Current Time: $CURRENT_TIME"
done

############ Post Result to Mattermost ############
mattermost "#### **SPL Automated Sanity Results**\n\nProject: ${PROJECT}\nTrain: ${TRAIN}\nLatest Bundle: ${LATEST_BUNDLE}\n\n${ASTRO_STATUS} \n\n"

SPACER
SPACER
HEADER "<><> Sanity Complete <><> ##"

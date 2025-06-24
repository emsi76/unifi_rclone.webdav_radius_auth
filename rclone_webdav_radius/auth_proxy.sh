#!/bin/bash

STD_IN=$(</dev/stdin)
echo "STDIN is $STD_IN" >> ${RCLONE_WEBDAV_LOG_PATH}

# Load environment variables
set -a
source /data/rclone_webdav_radius/rclone_webdav_radius.env
set +a

user=$(echo $STD_IN | jq --raw-output '.user')
pass=$(echo $STD_IN | jq --raw-output '.pass')

echo "user $user and pass $pass" >> ${RCLONE_WEBDAV_LOG_PATH}

auth=$(radtest $user $pass 127.0.0.1 1812 497214700494 |  grep -c 'Access-Accept')

if [ $auth == 1 ]; then
    if [ ! -d "${RCLONE_WEBDAV_ROOT_PATH}/${user}_banned/" ]; then
        mkdir -p "${RCLONE_WEBDAV_ROOT_PATH}/${user}/"
        printf "{\"type\":\"local\",\"_root\":\"${RCLONE_WEBDAV_ROOT_PATH}/${user}\",\"user\":\"$user\",\"pass\":\"$pass\"}\n"
    else
        printf "Blocked login: auth not successful for user $user"
    fi
else
    if [ -d "${RCLONE_WEBDAV_ROOT_PATH}/${user}/" ]; then
        mv "${RCLONE_WEBDAV_ROOT_PATH}/${user}/" "${RCLONE_WEBDAV_ROOT_PATH}/${user}_banned/"
    fi
    printf "Failed login: auth not successful for user $user"
fi

#!/bin/bash

function exists_in_list() {
    LIST=$1
    DELIMITER=$2
    VALUE=$3
    echo $LIST | tr "$DELIMITER" '\n' | grep -F -x "$VALUE"
}

STD_IN=$(</dev/stdin)
echo "STDIN is $STD_IN" >> ${RCLONE_WEBDAV_LOG_PATH}

# Load environment variables
set -a
source /data/rclone_webdav_radius/rclone_webdav_radius.env
set +a

user=$(echo $STD_IN | jq --raw-output '.user')
pass=$(echo $STD_IN | jq --raw-output '.pass')

echo "user $user and pass $pass" >> ${RCLONE_WEBDAV_LOG_PATH}
has_access=0

echo "Radius allowed user list is $RCLONE_WEBDAV_RADIUS_USERS" >> ${RCLONE_WEBDAV_LOG_PATH}
if [ -z "$RCLONE_WEBDAV_RADIUS_USERS" ]; then
    echo "Empty radius allowed list" >> ${RCLONE_WEBDAV_LOG_PATH}
    has_access=1
else
    if [ exists_in_list $RCLONE_WEBDAV_RADIUS_USERS "," $user ]; then
        echo "User is in the radius allowed list" >> ${RCLONE_WEBDAV_LOG_PATH}
        has_access=1
    else
        echo "User is not in the radius allowed list" >> ${RCLONE_WEBDAV_LOG_PATH}
        has_access=0
    fi
fi

if [ $has_access -eq 1 ]; then
    myhost="$(hostname -f)"
    myhost+="."
    myhost+="$(hostname -y)"
    
    echo "radius host $myhost" >> ${RCLONE_WEBDAV_LOG_PATH} 
    
    auth=$(radtest $user $pass $myhost $RCLONE_WEBDAV_RADIUS_PORT $RCLONE_WEBDAV_RADIUS_SECRET |  grep -c 'Access-Accept')
    
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
else
        printf "Blocked login: user $user is not in radius allowed list"
fi

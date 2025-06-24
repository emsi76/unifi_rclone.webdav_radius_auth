#!/bin/bash

# Load environment variables
set -a
source /data/rclone/rclone_webdav.env
set +a

rclone serve webdav -v "${RCLONE_WEBDAV_ROOT_PATH}" --addr :${RCLONE_WEBDAV_PORT} --key ${RCLONE_WEBDAV_SSL_KEY} --cert ${RCLONE_WEBDAV_SSL_CERT} --htpasswd /data/rclone/htpasswd --log-file=${RCLONE_WEBDAV_LOG_PATH}

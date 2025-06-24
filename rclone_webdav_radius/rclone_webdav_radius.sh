#!/bin/bash

# Load environment variables
set -a
source /data/rclone_webdav_radius/rclone_webdav_radius.env
set +a

rclone serve webdav --addr :${RCLONE_WEBDAV_PORT} --key ${RCLONE_WEBDAV_SSL_KEY} --cert ${RCLONE_WEBDAV_SSL_CERT} --log-file=${RCLONE_WEBDAV_LOG_PATH} --auth-proxy ./auth_proxy.sh

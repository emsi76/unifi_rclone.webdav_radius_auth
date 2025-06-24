#!/bin/bash

set -e
SCRIPT_DIR=$(dirname ${0})

export repoUrl='https://raw.githubusercontent.com/emsi76/unifi_rclone.webdav_radius_auth/refs/heads/main'
export SERVICE_NAME='rclone_webdav_radius'

# Get the firmware version
export FIRMWARE_VER=$(ubnt-device-info firmware || true)
# Get the Harware Model
export MODEL="$(ubnt-device-info model || true)"

export RCLONE_WEBDAV_FOLDER='/data/rclone_webdav'

# Check os version

check_version_model_dir(){
	if [ $(echo ${FIRMWARE_VER} | sed 's#\..*$##g') -gt 1 ]
		then
        	export DATA_DIR="/data"
	else
		echo "- Unsupported firmware - ${FIRMWARE_VER}"
		exit 1
	fi

	case "${MODEL}" in
	"UniFi Dream Machine Pro"|"UniFi Dream Machine"|"UniFi Dream Router"|"UniFi Dream Machine SE")
		echo "${MODEL} running firmware ${FIRMWARE_VER} detected, installing rclone.webdav in ${DATA_DIR}..."
		;;
		*)
		echo "- Unsupported model - ${MODEL}"
		exit 1
		;;
	esac
	if [ ! -d "$DATA_DIR" ]; then
  		echo "- Required '$DATA_DIR' directory does not exist -"
		exit 1
	fi
	echo valid model, version and /data folder existing...proceeding...
}

# Check if service exists
service_exists() {
    echo checking if service exists
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

# Download files
get_rclone_webdav_radius(){
	echo 'get the rclone_webdav_radius files into $RCLONE_WEBDAV_FOLDER from $repoUrl'
	mkdir -p $RCLONE_WEBDAV_FOLDER
 	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.sh" "$repoUrl/rclone_webdav/rclone_webdav_radius.sh"
	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service" "$repoUrl/rclone_webdav/rclone_webdav_radius.service"
	(wget -nc -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.env" "$repoUrl/rclone_webdav/rclone_webdav_radius.env" || true)
 	echo 'setting right permissions'
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav.sh
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav.service
 	echo 'rclone_webdav_radius now into $RCLONE_WEBDAV_FOLDER'
}

install_webdav_radius_service(){
	echo install service 'rclone_webdav_radius.service'
	cp $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service  /etc/systemd/system/rclone_webdav_radius.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_webdav_radius.service
	sudo systemctl enable rclone_webdav_radius.service
 	echo service 'rclone_webdav_radius.service' installed
}

update_webdav_radius_service(){
	echo update service 'rclone_webdav_radius.service'
	sudo systemctl stop rclone_webdav_radius.service
	sudo systemctl disable rclone_webdav_radius.service
	cp $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service  /etc/systemd/system/rclone_webdav_radius.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_webdav_radius.service
	sudo systemctl enable rclone_webdav_radius.service
 	echo service 'rclone_webdav_radius.service' updated
}

uninstall_webdav_radius_service(){
	echo uninstall service 'rclone_webdav_radius.service'
	sudo systemctl stop rclone_webdav_radius.service
	sudo systemctl disable rclone_webdav_radius.service
	rm $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service
	sudo systemctl daemon-reload
}

#install rclone
install_rclone(){
	echo try installing rclone
	((sudo -v ; curl https://rclone.org/install.sh | sudo bash) || true)
 	echo 'rclone installed or already installed'
}


check_version_model_dir
get_rclone_webdav_radius
install_rclone

if service_exists rclone_webdav_radius; 
	then
		update_webdav_radius_service
		echo service updated
    	else
		install_webdav_radius_service
		echo service installed
fi

# Load environment variables
set -a
source /data/rclone/rclone_webdav_radius.env
set +a

echo your WebDav _radius server should now be running on port $RCLONE_WEBDAV_PORT with root folder: $RCLONE_WEBDAV_ROOT_PATH

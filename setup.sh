#!/bin/bash

#echo starting setup.sh script...


OPTIND=1         # Reset in case getopts has been used previously in the shell.
install=false
uninstall=false

while getopts "h?iu" opt; do
    case "$opt" in
    h|\?)
        echo -e "Usage: setup.sh\n[-i]\t to install rclone webdav\n[-u]\t to uninstall rclone webdav"
        exit 0
        ;;
    i)  install=true
    	echo "setup mode is installation"
        ;;
    u)  uninstall=true
    	echo "setup mode is uninstallation"
        ;;
    *) 
    	echo -e "Missing argument. Usage: setup.sh\n[-i]\t to install rclone webdav\n[-u]\t to uninstall rclone webdav"
        exit 0
	;;
    esac
done

shift $((OPTIND-1))
[ "${1:-}" = "--" ] && shift

# echo "install=$install, uninstall=$uninstall, Leftovers: $@"

if [[ "$install" = false ]]
    then
    	if [[ "$uninstall" = false ]]
     	   then
		echo -e "Missing mandatory argument. Usage: setup.sh\n[-i]\t to install rclone webdav\n[-u]\t to uninstall rclone webdav"
       		exit 0
	fi
fi

# echo 'proceeding...'

export repoUrl='https://raw.githubusercontent.com/emsi76/unifi_rclone.webdav/refs/heads/main'
export SERVICE_NAME='rclone_webdav'

# Get the firmware version
export FIRMWARE_VER=$(ubnt-device-info firmware || true)
# Get the Harware Model
export MODEL="$(ubnt-device-info model || true)"

export RCLONE_WEBDAV_FOLDER='/data/rclone'

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
get_rclone_webdav(){
	echo 'get the rclone_webdav files into $RCLONE_WEBDAV_FOLDER from $repoUrl'
	mkdir -p $RCLONE_WEBDAV_FOLDER
 	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav.sh" "$repoUrl/rclone_webdav/rclone_webdav.sh"
	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav.service" "$repoUrl/rclone_webdav/rclone_webdav.service"
 	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.sh" "$repoUrl/rclone_webdav/rclone_ban_failed_users.sh"
 	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.service" "$repoUrl/rclone_webdav/rclone_ban_failed_users.service"
	(wget -nc -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav.env" "$repoUrl/rclone_webdav/rclone_webdav.env" || true)
	(wget -nc -O "$RCLONE_WEBDAV_FOLDER/htpasswd" "$repoUrl/rclone_webdav/htpasswd" || true)
 	echo 'setting right permissions'
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav.sh
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.sh
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav.service
 	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.service
 	echo 'rclone_webdav now into $RCLONE_WEBDAV_FOLDER'
}

install_webdav_service(){
	echo install service 'rclone_webdav.service'
	cp $RCLONE_WEBDAV_FOLDER/rclone_webdav.service  /etc/systemd/system/rclone_webdav.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_webdav.service
	sudo systemctl enable rclone_webdav.service
 	echo service 'rclone_webdav.service' installed
}

update_webdav_service(){
	echo update service 'rclone_webdav.service'
	sudo systemctl stop rclone_webdav.service
	sudo systemctl disable rclone_webdav.service
	cp $RCLONE_WEBDAV_FOLDER/rclone_webdav.service  /etc/systemd/system/rclone_webdav.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_webdav.service
	sudo systemctl enable rclone_webdav.service
 	echo service 'rclone_webdav.service' updated
}

uninstall_webdav_service(){
	echo  service 'rclone_webdav.service'
	sudo systemctl stop rclone_webdav.service
	sudo systemctl disable rclone_webdav.service
	rm $RCLONE_WEBDAV_FOLDER/rclone_webdav.service
  rm $RCLONE_WEBDAV_FOLDER/rclone_webdav.sh
	sudo systemctl daemon-reload
}

install_rclone_ban_failed_users_service(){
	echo install service 'rclone_ban_failed_users.service'
	cp $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.service  /etc/systemd/system/rclone_ban_failed_users.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_ban_failed_users.service
	sudo systemctl enable rclone_ban_failed_users.service
 	echo service 'rclone_ban_failed_users.service' installed
}

update_rclone_ban_failed_users_service(){
	echo update service 'rclone_ban_failed_users.service'
	sudo systemctl stop rclone_ban_failed_users.service
	sudo systemctl disable rclone_ban_failed_users.service
	cp $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.service  /etc/systemd/system/rclone_ban_failed_users.service
	sudo systemctl daemon-reload
	sudo systemctl start rclone_ban_failed_users.service
	sudo systemctl enable rclone_ban_failed_users.service
 	echo service 'rclone_ban_failed_users.service' updated
}

uninstall_rclone_ban_failed_users_service(){
	echo  service 'rclone_ban_failed_users.service'
	sudo systemctl stop rclone_ban_failed_users.service
	sudo systemctl disable rclone_ban_failed_users.service
	rm $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.service
  rm $RCLONE_WEBDAV_FOLDER/rclone_ban_failed_users.sh
	sudo systemctl daemon-reload
}

#install rclone
install_rclone(){
	echo try installing rclone
	((sudo -v ; curl https://rclone.org/install.sh | sudo bash) || true)
 	echo 'rclone installed or already installed'
}

installation(){
  check_version_model_dir
  get_rclone_webdav
  install_rclone
  
  if service_exists rclone_webdav; 
  	then
  		update_webdav_service
  		echo service updated
      	else
  		install_webdav_service
  		echo service installed
  fi
  if service_exists rclone_ban_failed_users; 
  	then
  		update_rclone_ban_failed_users_service
  		echo service updated
      	else
  		install_rclone_ban_failed_users_service
  		echo service installed
  fi
}

uninstallation(){
  check_version_model_dir
  if service_exists rclone_ban_failed_users; 
  	then
  		uninstall_rclone_ban_failed_users_service
  		echo service uninstalled
  fi
  if service_exists rclone_webdav; 
  	then
  		uninstall_webdav_service
  		echo service ed
  fi
}

if $install;
  then
    installation
    # Load environment variables
    set -a
      source $RCLONE_WEBDAV_FOLDER/rclone_webdav.env
    set +a
    echo your WebDav server should now be running on port $RCLONE_WEBDAV_PORT with root folder: $RCLONE_WEBDAV_ROOT_PATH
  else
    if $uninstall;
      then
        uninstallation
        echo your WebDav server is now uninstalled!
    fi
fi

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

export repoUrl='https://raw.githubusercontent.com/emsi76/unifi_rclone.webdav_radius_auth/refs/heads/main'
export SERVICE_NAME='rclone_webdav_radius'

# Get the firmware version
export FIRMWARE_VER=$(ubnt-device-info firmware || true)
# Get the Harware Model
export MODEL="$(ubnt-device-info model || true)"

export RCLONE_WEBDAV_FOLDER='/data/rclone_webdav_radius'

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
 	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.sh" "$repoUrl/rclone_webdav_radius/rclone_webdav_radius.sh"
	wget -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service" "$repoUrl/rclone_webdav_radius/rclone_webdav_radius.service"
 	wget -O "$RCLONE_WEBDAV_FOLDER/auth_proxy.sh" "$repoUrl/rclone_webdav_radius/auth_proxy.sh"
	(wget -nc -O "$RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.env" "$repoUrl/rclone_webdav_radius/rclone_webdav_radius.env" || true)
 	echo 'setting right permissions'
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.sh
	chmod oug+rx $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service
 	chmod oug+rx $RCLONE_WEBDAV_FOLDER/auth_proxy.sh
 	echo 'rclone_webdav now into $RCLONE_WEBDAV_FOLDER'
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
	echo  service 'rclone_webdav_radius.service'
	sudo systemctl stop rclone_webdav_radius.service
	sudo systemctl disable rclone_webdav_radius.service
	rm $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.service
  rm $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.sh
	sudo systemctl daemon-reload
}

#install rclone
install_rclone(){
	echo try installing rclone
	((sudo -v ; curl https://rclone.org/install.sh | sudo bash) || true)
 	echo 'rclone installed or already installed'
}

install_freeradius-utils(){
	echo try installing freeradius-utils
	(sudo apt install freeradius-utils=3.2.1+dfsg-3~bpo11+1 || true)
 	echo 'freeradius-utils installed or already installed'
}
uninstall_freeradius-utils(){
	(sudo apt-get purge --auto-remove -y freeradius-utils || true)
 	echo 'freeradius-utils uninstalled or already uninstalled'
}

installation(){
  check_version_model_dir
  get_rclone_webdav_radius
  install_rclone
  install_freeradius-utils
  
  if service_exists rclone_webdav_radius; 
  	then
  		update_webdav_radius_service
  		echo service updated
      	else
  		install_webdav_radius_service
  		echo service installed
  fi
}

uninstallation(){
  check_version_model_dir
  if service_exists rclone_webdav_radius; 
  	then
  		uninstall_webdav_radius_service
    		uninstall_freeradius-utils
  		echo service uninstalled
  fi
}

if $install;
  then
    installation
    # Load environment variables
    set -a
      source $RCLONE_WEBDAV_FOLDER/rclone_webdav_radius.env
    set +a
    mkdir -p $RCLONE_WEBDAV_ROOT_PATH
    echo your WebDav radius server should now be running on port $RCLONE_WEBDAV_PORT with root folder: $RCLONE_WEBDAV_ROOT_PATH
  else
    if $uninstall;
      then
        uninstallation
        echo your WebDav server is now uninstalled!
    fi
fi

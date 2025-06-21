#!/bin/bash
u='\e[4m'
bold='\033[1m'
CYAN='\033[0;36m'	# cyan text
RED='\033[0;31m'	# red text
NC='\033[0m'		# white text
PURPLE='\033[1;35m'	# Light Purple
BLUE='\033[0;34m'	# BLUE
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
clear

echo -e ${CYAN}"Welcome in Auto Arch usb boot medium creator."${NC}
sleep 3

if [ "$(id -u)" -ne 0 ]; then
	echo -e  ${CYAN}"Please run this script as root "${NC}
	exit 1
fi

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export script_dir
export bold
export normal
export CYAN
export RED
export NC
export PURPLE
export BLUE
export GREEN
export YELLOW

source "$script_dir/resources/scripts/check_packages.sh"
source "$script_dir/resources/scripts/fdisk_create.sh"
source "$script_dir/resources/scripts/dowload_and_check.sh"
source "/$script_dir/resources/scripts/extrackt_and_move.sh"
source "/$script_dir/resources/scripts/jail_bootstrap.sh"

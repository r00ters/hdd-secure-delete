#!/usr/bin/env bash

TARGET_DISK=''
TARGET_DISK_SECTOR_SIZE=4096

prompt_confirm() {
    while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
        [yY]) echo ; return 0 ;;
        [nN]) echo ; return 1 ;;
        *) printf " \033[31m %s \n\033[0m" "invalid input"
    esac
    done
}

usage() {
    if [[ "$EUID" -ne 0 ]]; then
        echo "Error: Please run as root"
        exit 1
    fi

    if [[ $# != 1 ]]; then
        echo "Usage: ${0} [/dev/disk/by-id/ata-MODEL-PARTNUMBER_SERIAL]"
        exit 1
    fi

    TARGET_DISK=${1}

    prompt_confirm "Target disk: ${TARGET_DISK}" || exit 1
}

get_smart_info() {
    smartctl -a "${TARGET_DISK}" | grep -E "Device Model|Serial Number|User Capacity|Local Time is|_Hours|_Error|_Recovered|ATTRIBUTE_NAME|SSD"
}

get_sector_size() {
    TARGET_DISK_SECTOR_SIZE=$( hdparm -I "${TARGET_DISK}" |  awk '/Physical Sector size:/ { print $4 }' )
    echo "Physical Sector size: ${TARGET_DISK_SECTOR_SIZE}"
}

get_partition_info() {
    fdisk -l "${TARGET_DISK}"
}

wipe() {
    prompt_confirm "Wipe disk: ${TARGET_DISK}" || exit 1
    dd if=/dev/urandom of="${TARGET_DISK}" bs="${TARGET_DISK_SECTOR_SIZE}" status=progress
}


usage "$@"
get_smart_info
get_sector_size
get_partition_info
wipe

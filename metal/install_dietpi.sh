#!/usr/bin/env bash

# Los trap que pongo para borrar archivos temporales y umountear cosas no
# tienen mucho sentido si son llamados y ya no se tienen permisos de root
if [ $UID -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

DIETPI_ARCH="ARMv8"
DIETPI_RELEASE="Bookworm"
DIETPI_IMAGE_URL="https://dietpi.com/downloads/images/DietPi_RPi-$DIETPI_ARCH-$DIETPI_RELEASE.img.xz"
DIETPI_CHKSUM_URL="$DIETPI_IMAGE_URL.sha256"

usage() {
    cat << EOF
Usage: $0 [OPTARGS] [ARGS]

ARGS:
    -d, --device <device path>
    -c, --config-file <config file>

OPTARGS:
    -i, --image <os image file path>
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -d|--device)
        DEVICE="$2"; shift ;;
    -c|--config-file)
        CONFIG_FILE="$2"; shift ;;
    -i|--image)
        OS_IMAGE="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

if [ -z "$CONFIG_FILE" ] || [ -z "$DEVICE" ];
then
    usage
fi

download_latest_image() {
    OS_IMAGE=$(mktemp /tmp/dietpi_rpi.XXXXXX)
    trap "rm -f $OS_IMAGE" 0 2 3 15

    echo "[*] Downloading OS image from $DIETPI_IMAGE_URL"
    wget -q $DIETPI_IMAGE_URL -O $OS_IMAGE
    echo $(wget $DIETPI_CHKSUM_URL -O- -o /dev/null | cut -f1 -d' ') $OS_IMAGE | sha256sum --check --status

    exit_status=$?
    if [ $exit_status -eq 1 ];
    then
        echo "[-] Image checksum validation failed"
         exit 1
    else
        echo "[+] Image checksum verified"
    fi
}

burn_image() {
    echo "[*] Writing data to '$DEVICE'"
    xz --stdout --decompress $OS_IMAGE | dd of=$DEVICE status=progress
    echo "[+] Data succesfully written to '$DEVICE'"
}

copy_config_file() {
    mnt_dir=$(mktemp --directory /mnt/dietpi.XXXXXX)
    trap "umount $mnt_dir && rm -r $mnt_dir" 0 2 3 15

    sd_partition=$(fdisk -l /dev/mmcblk0 | awk '/^\/dev/ && !/Linux/' | cut -d' ' -f1)

    echo "[*] Mounting partition $sd_partition -> $mnt_dir"
    mount $sd_partition $mnt_dir
    echo "[*] Copying config file $CONFIG_FILE -> $mnt_dir/$CONFIG_FILE"
    cp $CONFIG_FILE $mnt_dir
}

if [ -z "$OS_IMAGE" ];
then
    download_latest_image
fi

burn_image
copy_config_file
#eject $DEVICE
echo "[+] Media ready :)"

#!/usr/bin/env bash

# Los trap que pongo para borrar archivos temporales y umountear cosas no
# tienen mucho sentido si son llamados y ya no se tienen permisos de root
if [ $UID -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

#BASE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images"
#RASPIOS_IMAGE_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/?C=M;O=A"
RASPIOS_LATEST_URL="https://downloads.raspberrypi.org/raspios_lite_arm64_latest"
RASPIOS_CHKSUM_URL="$RASPIOS_LATEST_URL.sha256"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

usage() {
    cat << EOF
Usage: $0 [OPTARGS] [ARGS]

OPTARGS:
    -i, --image <os image file path>

ARGS:
    -d, --device <device path>
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -d|--device)
        DEVICE="$2"; shift ;;
    -i|--image)
        OS_IMAGE="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

if [ -z "$DEVICE" ];
then
    usage
fi

download_latest_image() {
    OS_IMAGE=$(mktemp /tmp/raspios_rpi.XXXXXX)
    trap "echo '[*] Deleting image'; rm -f $OS_IMAGE" 0 2 3 15

    # Por no investigar 5 minutos más...
    #latest_release_dir=$(curl --silent "https://downloads.raspberrypi.com/raspios_lite_arm64/images/?C=M;O=A" \
        #| grep -oP '(raspios_lite_arm64-[0-9\-]+)(?=/<)' \
        #| tail -n 1)
    #latest_release_url="$BASE_URL/$latest_release_dir"
    #latest_image_name=$(curl --silent $latest_release_url/ \
        #| grep -oP '(?<=href=")[a-zA-Z0-9\-\.]+\.xz(?=")')
    #echo "[*] Latest image: $latest_image_name"

    #latest_image_url="$latest_release_url/$latest_image_name"
    #echo $latest_image_url

    #echo "[*] Downloading OS image from $latest_image_url"
    #wget $latest_image_url -q --show-progress -O $OS_IMAGE
    echo "[*] Downloading OS image from $RASPIOS_LATEST_URL"
    wget $RASPIOS_LATEST_URL -q --show-progress -O $OS_IMAGE
    echo $(wget $RASPIOS_CHKSUM_URL -O- -o /dev/null | cut -f1 -d' ') $OS_IMAGE | sha256sum --check --status

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

mount_boot() {
    mnt_dir=$(mktemp --directory /mnt/dietpi.XXXXXX)
    trap "echo '[*] Umounting $mnt_dir'; umount $mnt_dir; rm -r $mnt_dir" 0 2 3 15

    sd_partition=$(fdisk -l $DEVICE | awk '/^\/dev/ && !/Linux/' | cut -d' ' -f1)

    echo "[*] Mounting partition $sd_partition -> $mnt_dir"
    mount $sd_partition $mnt_dir
    read -r -p "[?] Press any key when ready to unmount..." key
}

if [ -z "$OS_IMAGE" ];
then
    download_latest_image
fi

burn_image
mount_boot
echo "[+] Media ready :)"

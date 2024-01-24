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
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)"

usage() {
    cat << EOF
Usage: $0 [OPTARGS] [ARGS]

OPTARGS:
    -i, --image <os image file path>

ARGS:
    -d, --device <device path>
    -H, --hostname <hostname>
    --static-cidr <CIDR>
    --static-gateway <IPv4 address>
    --static-dns <IPv4 address>
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -d|--device)
        DEVICE="$2"; shift ;;
    -H|--hostname)
        RPI_HOSTNAME="$2"; shift ;;
    --static-cidr)
        STATIC_CIDR="$2"; shift ;;
    --static-gateway)
        STATIC_GATEWAY="$2"; shift ;;
    --static-dns)
        STATIC_DNS="$2"; shift ;;
    -i|--image)
        OS_IMAGE="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

case "" in
    "$DEVICE"|"$RPI_HOSTNAME"|\
    "$STATIC_CIDR"|"$STATIC_GATEWAY"|"$STATIC_DNS")
        usage ;;
esac

download_latest_image() {
    OS_IMAGE=$(mktemp /tmp/dietpi_rpi.XXXXXX)
    trap "echo '[*] Deleting image'; rm -f $OS_IMAGE" 0 2 3 15

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

setup_env_vars() {
    echo "[*] Setting up template variables"
    export CONFIG_STATIC_IP=$(ipcalc $STATIC_CIDR | sed -nE 's/^Address:\s*([0-9\.]+).*$/\1/p')
    export CONFIG_STATIC_MASK=$(ipcalc $STATIC_CIDR | sed -nE 's/^Netmask:\s*([0-9\.]+).*$/\1/p')
    export CONFIG_STATIC_GATEWAY="$STATIC_GATEWAY"
    export CONFIG_STATIC_DNS="$STATIC_DNS"
    export CONFIG_HOSTNAME="$RPI_HOSTNAME"
}

copy_config_file() {
    mnt_dir=$(mktemp --directory /mnt/dietpi.XXXXXX)
    trap "echo '[*] Umounting $mnt_dir'; umount $mnt_dir; rm -r $mnt_dir" 0 2 3 15

    config_template="$DIR/config/dietpi.txt"
    config_file="$mnt_dir/dietpi.txt"

    sd_partition=$(fdisk -l $DEVICE | awk '/^\/dev/ && !/Linux/' | cut -d' ' -f1)

    echo "[*] Mounting partition $sd_partition -> $mnt_dir"
    mount $sd_partition $mnt_dir
    echo "[*] Copying config file $config_template -> $config_file"

    setup_env_vars
    envsubst < $config_template > $config_file
}

if [ -z "$OS_IMAGE" ];
then
    download_latest_image
fi

burn_image
copy_config_file
echo "[+] Media ready :)"

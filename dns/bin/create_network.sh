#!/usr/bin/env bash

usage() {
    cat << EOF
Usage: $0 [ARGUMENTS]

ARGUMENTS:
    -f, --config-file <config file>:   YML config file
    -n, --network-name <network name>: Docker network name
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -f|--config-file)
        CONFIG_FILE="$2"; shift ;;
    -n|--network-name)
        NETWORK_NAME="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

if [ -z "$CONFIG_FILE" ] || [ -z "$NETWORK_NAME" ];
then
    usage
fi

LAB_NETWORK=$(yq -r '.network' "$CONFIG_FILE")
LAB_GATEWAY=$(yq -r '.gateway' "$CONFIG_FILE")

docker network rm --force $NETWORK_NAME
docker network create --gateway $LAB_GATEWAY --subnet $LAB_NETWORK $DOCKER_NETWORK_NAME

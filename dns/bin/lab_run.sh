#!/usr/bin/env bash

usage() {
    cat << EOF
Usage: $0 [ARGUMENTS]

ARGUMENTS:
    -a, --action <start|stop>
    -f, --compose-file <compose file>
    -c, --config-file <config file>
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -a|--action)
        ACTION="$2"; shift ;;
    -c|--config-file)
        CONFIG_FILE="$2"; shift ;;
    -f|--compose-file)
        COMPOSE_FILE="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

if [ -z "$CONFIG_FILE" ] || [ -z "$COMPOSE_FILE" ] || [ -z "$ACTION" ];
then
    usage
fi

# Variables para docker-compose.yml
export AUTHORITATIVE_DNS=$(yq -r '.authoritative_dns' "$CONFIG_FILE")
export RECURSIVE_DNS=$(yq -r '.recursive_dns' "$CONFIG_FILE")
DOCKERCOMPOSE="docker compose --file $COMPOSE_FILE"

if [ "$ACTION" = "stop" ];
then
    $DOCKERCOMPOSE stop
    exit 0
fi

# Servidor DNS
$DOCKERCOMPOSE up -d

#!/usr/bin/env bash

if [ $UID -ne 0 ]; then
    exec sudo -- "$0" "$@"
fi

usage() {
    cat << EOF
Usage: $0 <ARGS>

<ARGS>:
    -i, --image{PATH}:      SDM enhanced RaspiOS image
    -o, --output{PATH}:     Final image output path
    -H, --hostname{STRING}: Set device hostname
EOF
    exit 1
}

while test $# != 0
do
    case "$1" in
    -i|--image)
        INPUT_IMAGE="$2"; shift;;
    -o|--output)
        OUTPUT_IMAGE="$2"; shift ;;
    -H|--hostname)
        HOSTNAME="$2"; shift;;
    --) shift; break;;
    *)  usage;;
    esac
    shift
done

case "" in
    "$INPUT_IMAGE"|"$OUTPUT_IMAGE"|"$HOSTNAME")
        usage ;;
esac

sdm \
    --burnfile $OUTPUT_IMAGE \
    --host $HOSTNAME \
    --expand-root \
    --regen-ssh-host-key \
    --ecolors 0 \
    --mcolors 0 \
    $INPUT_IMAGE

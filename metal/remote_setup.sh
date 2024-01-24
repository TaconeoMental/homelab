#!/usr/bin/env bash

usage() {
    cat << EOF
Usage: $0 user@host
EOF
    exit 1
}

REMOTE_HOST="$1"

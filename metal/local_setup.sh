#!/usr/bin/env bash

generate_password() {
    head /dev/urandom | tr -dc A-Za-z0-9 | head -c 50
}

change_passwords() {
    USERS=()
    USERS+=('root')
    USERS+=('dietpi')

    for local_user in "${USERS[@]}"
    do
        new_password=$(generate_password)
        echo "$local_user:$new_password" | chpasswd
        echo "New $local_user password: $new_password"
    done
}

# Añadir usuario sin contraseña
adduser --quiet --disabled-password --shell /bin/bash --home /home/neo --gecos "neo" neo
echo "neo:GUOR6CanfIL9NgZtGxeUTmYp0ONlfrEPioEsgQ2U" | chpasswd

change_passwords

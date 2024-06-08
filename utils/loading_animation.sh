#!/usr/bin/env bash

function loading_icon() {
    local loading_message="${1}"
    local status_endpoint="${2}"
    local load_interval="${3}"
    local elapsed=0
    local loading_animation=( '—' "\\" '|' '/' )

    echo -n "${loading_message} "

    # This part is to make the cursor not blink
    # on top of the animation while it lasts
    tput civis
    trap "tput cnorm" EXIT

    until [ $elapsed -ge $load_interval ] || curl -sSf $status_endpoint > /dev/null 2>&1;  do
        for frame in "${loading_animation[@]}" ; do
            printf "%s\b" "${frame}"
            sleep 0.25
        done
        elapsed=$(( elapsed + 1 ))
    done
    printf " \b\n"
}

loading_icon "$@"
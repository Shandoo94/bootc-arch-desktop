#!/bin/bash
HOSTNAME=$(grep -oP 'bootc\.hostname=\K[^ ]+' /proc/cmdline)
if [[ -n "$HOSTNAME" ]]; then
    cat "$HOSTNAME" > /etc/hostname
fi

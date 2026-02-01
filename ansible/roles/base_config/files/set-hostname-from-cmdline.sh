#!/bin/bash
HOSTNAME=$(grep -oP 'bootc\.hostname=\K[^ ]+' /proc/cmdline)
if [[ -n "$HOSTNAME" ]]; then
    hostnamectl set-hostname "$HOSTNAME"
fi

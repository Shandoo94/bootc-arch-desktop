#!/bin/bash
HOSTNAME=$(grep -oP 'bootc\.hostname=\K[^ ]+' /proc/cmdline)
if [[ -n "$HOSTNAME" ]]; then
  echo "$HOSTNAME" > /etc/hostname
fi

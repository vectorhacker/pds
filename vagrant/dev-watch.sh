#!/bin/bash
set -e

if ! command -V vagrant >/dev/null 2>&1; then
    echo "OOPS! Run this command OUTSIDE of vagrant so that we can watch the file system better."
    exit 1
fi

if ! command -V modd >/dev/null 2>&1; then
    echo "Oops - please install `modd` on your host machine"
    echo "https://github.com/cortesi/modd"
    exit 1
fi

# Boot the vm
vagrant up

# Catch shutdown signal and kill both
trap 'kill %1;' SIGINT

(sleep 5; echo "booting modd"; modd) | sed -e 's/^/[modd] /'

# shut down the VM
vagrant halt
#!/usr/bin/env bash
if [ -z "$@" ]; then
    cliphist list
else
    echo "$@" | cliphist decode | wl-copy
fi

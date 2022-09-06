#!/usr/bin/env bash

# Enable debugging
# set -x

# Send a quick restart announcement to all the players
rcon "announcerestart 1"
sleep 5


## FIXME: This seems to instantly destroy it, without saving?!
# Tell the server to terminate
kill -s INT `pgrep -nf VRisingServer.exe`


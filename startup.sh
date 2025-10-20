#!/bin/bash
set -e

# Start cron in background
service cron start

# Optional: show cron jobs for debug
crontab -l

# Start Duplicati (foreground so container stays alive)
exec /init

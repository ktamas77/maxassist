#!/bin/bash
set -e

# Load crontab from persisted file if it exists and has entries
if [ -f /maxassist/cron/crontab.txt ] && grep -qv '^#' /maxassist/cron/crontab.txt 2>/dev/null; then
    crontab /maxassist/cron/crontab.txt
    echo "Loaded crontab from /maxassist/cron/crontab.txt"
fi

# Start cron in foreground
exec cron -f

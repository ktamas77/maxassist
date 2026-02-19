#!/bin/bash
# Example: Health check script that pings a URL and posts result to Slack.
# This is a reference template — not added to cron by default.
# Ask Claude to customize it for your services.
#
# Usage: example-health-check.sh
# Configure TARGET_URL and SLACK_CHANNEL below.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_URL="${TARGET_URL:-https://example.com}"
SLACK_CHANNEL="${SLACK_CHANNEL:-#ops}"

HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$TARGET_URL" 2>/dev/null || echo "000")
TIMESTAMP=$(date -u +"%Y-%m-%d %H:%M:%S UTC")

if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 400 ]; then
    echo "$TIMESTAMP OK $HTTP_CODE $TARGET_URL" >> "$SCRIPT_DIR/../output/health-check.log"
else
    MESSAGE="Health check FAILED: $TARGET_URL returned $HTTP_CODE at $TIMESTAMP"
    echo "$TIMESTAMP FAIL $HTTP_CODE $TARGET_URL" >> "$SCRIPT_DIR/../output/health-check.log"
    "$SCRIPT_DIR/slack-post.sh" "$SLACK_CHANNEL" "$MESSAGE"
fi

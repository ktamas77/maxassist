#!/bin/bash
# Usage: slack-post.sh "#channel" "message text"
# Posts a message to Slack via Bot Token (chat.postMessage API).
# Requires SLACK_BOT_TOKEN in environment (source config/slack.env).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

if [ -f "$CONFIG_DIR/slack.env" ]; then
    set -a
    source "$CONFIG_DIR/slack.env"
    set +a
fi

CHANNEL="${1:-${SLACK_DEFAULT_CHANNEL:-#general}}"
MESSAGE="${2:?Usage: slack-post.sh \"#channel\" \"message\"}"

if [ -z "${SLACK_BOT_TOKEN:-}" ]; then
    echo "Error: SLACK_BOT_TOKEN not set. Add it to config/slack.env." >&2
    exit 1
fi

RESPONSE=$(curl -s -X POST "https://slack.com/api/chat.postMessage" \
    -H "Authorization: Bearer $SLACK_BOT_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg channel "$CHANNEL" --arg text "$MESSAGE" '{channel: $channel, text: $text}')")

OK=$(echo "$RESPONSE" | jq -r '.ok')
if [ "$OK" != "true" ]; then
    ERROR=$(echo "$RESPONSE" | jq -r '.error // "unknown error"')
    echo "Slack API error: $ERROR" >&2
    exit 1
fi

echo "Message posted to $CHANNEL"

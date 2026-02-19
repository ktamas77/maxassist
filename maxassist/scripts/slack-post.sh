#!/bin/bash
# Usage: slack-post.sh "#channel" "message text"
# Posts a message to Slack via incoming webhook.
# Requires SLACK_WEBHOOK_URL in environment (source config/slack.env).

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

if [ -f "$CONFIG_DIR/slack.env" ]; then
    set -a
    source "$CONFIG_DIR/slack.env"
    set +a
fi

CHANNEL="${1:-$SLACK_DEFAULT_CHANNEL}"
MESSAGE="${2:?Usage: slack-post.sh \"#channel\" \"message\"}"

if [ -z "${SLACK_WEBHOOK_URL:-}" ]; then
    echo "Error: SLACK_WEBHOOK_URL not set. Copy config/slack.env.example to config/slack.env and fill it in." >&2
    exit 1
fi

curl -s -X POST "$SLACK_WEBHOOK_URL" \
    -H 'Content-Type: application/json' \
    -d "$(jq -n --arg channel "$CHANNEL" --arg text "$MESSAGE" '{channel: $channel, text: $text}')"

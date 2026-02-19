#!/bin/bash
# reminders.sh — One-time reminder system
# Usage:
#   reminders.sh check       — Post pending reminders to Slack (cron mode)
#   reminders.sh list        — Show all reminders with status
#   reminders.sh done <id>   — Mark a reminder as done
#   reminders.sh add "text" [YYYY-MM-DD] — Add a new reminder (optional start date)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"
REMINDERS_FILE="$CONFIG_DIR/reminders.json"

if [ ! -f "$REMINDERS_FILE" ]; then
    echo "Error: $REMINDERS_FILE not found" >&2
    exit 1
fi

ACTION="${1:-check}"

case "$ACTION" in
    check)
        NOW=$(date +%Y-%m-%dT%H:%M)
        NOW_DATE="${NOW%T*}"
        NOW_HOUR="${NOW#*T}"
        NOW_HOUR="${NOW_HOUR%:*}"
        ACTIVE=$(jq -r --arg now "$NOW_DATE" --arg hour "$NOW_HOUR" '[.[] | select(.status == "pending") | select(
            (.remind_from // "") == "" or
            (.remind_from | split("T") | .[0]) < $now or
            ((.remind_from | split("T") | .[0]) == $now and
             ((.remind_from | split("T") | if length > 1 then .[1] | split(":") | .[0] else "00" end) <= $hour))
        )]' "$REMINDERS_FILE")
        COUNT=$(echo "$ACTIVE" | jq 'length')

        if [ "$COUNT" -eq 0 ]; then
            exit 0
        fi

        MSG=":memo: *Daily Reminders* ($COUNT pending)\n\n"
        while IFS= read -r line; do
            ID=$(echo "$line" | jq -r '.id')
            TEXT=$(echo "$line" | jq -r '.text')
            MSG+="• $TEXT\n"
        done < <(echo "$ACTIVE" | jq -c '.[]')
        MSG+="\n_Mark done: \`/reminder done <id>\`_"

        "$SCRIPT_DIR/slack-post.sh" "#gerty-assistant" "$(echo -e "$MSG")"
        echo "Posted $COUNT pending reminders to Slack"
        ;;

    list)
        echo "=== Reminders ==="
        NOW_DATE=$(date +%Y-%m-%d)
        jq -r --arg now "$NOW_DATE" '.[] |
            (if .status == "done" then "[x]"
             elif (.remind_from // "") != "" and (.remind_from | split("T") | .[0]) > $now then "[ ] (waiting)"
             else "[ ]" end) + " " + .id + " — " + .text +
            (if (.remind_from // "") != "" and (.remind_from | split("T") | .[0]) > $now then " [from " + .remind_from + "]" else "" end)' "$REMINDERS_FILE"
        PENDING=$(jq '[.[] | select(.status == "pending")] | length' "$REMINDERS_FILE")
        DONE=$(jq '[.[] | select(.status == "done")] | length' "$REMINDERS_FILE")
        echo "---"
        echo "$PENDING pending, $DONE done"
        ;;

    done)
        ID="${2:?Usage: reminders.sh done <id>}"
        EXISTS=$(jq --arg id "$ID" '[.[] | select(.id == $id)] | length' "$REMINDERS_FILE")
        if [ "$EXISTS" -eq 0 ]; then
            echo "Error: reminder '$ID' not found" >&2
            exit 1
        fi
        CURRENT=$(jq -r --arg id "$ID" '.[] | select(.id == $id) | .status' "$REMINDERS_FILE")
        if [ "$CURRENT" = "done" ]; then
            echo "Reminder '$ID' is already done"
            exit 0
        fi
        DATE=$(date +%Y-%m-%d)
        jq --arg id "$ID" --arg date "$DATE" \
            'map(if .id == $id then .status = "done" | .completed = $date else . end)' \
            "$REMINDERS_FILE" > "${REMINDERS_FILE}.tmp" && mv "${REMINDERS_FILE}.tmp" "$REMINDERS_FILE"
        TEXT=$(jq -r --arg id "$ID" '.[] | select(.id == $id) | .text' "$REMINDERS_FILE")
        echo "Marked '$ID' as done: $TEXT"
        ;;

    add)
        TEXT="${2:?Usage: reminders.sh add \"reminder text\" [YYYY-MM-DD|YYYY-MM-DDTHH:MM]}"
        REMIND_FROM="${3:-}"
        ID=$(echo "$TEXT" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/^-//;s/-$//' | cut -c1-40)
        DATE=$(date +%Y-%m-%d)
        if [ -n "$REMIND_FROM" ]; then
            jq --arg id "$ID" --arg text "$TEXT" --arg date "$DATE" --arg rf "$REMIND_FROM" \
                '. + [{"id": $id, "text": $text, "status": "pending", "created": $date, "remind_from": $rf}]' \
                "$REMINDERS_FILE" > "${REMINDERS_FILE}.tmp" && mv "${REMINDERS_FILE}.tmp" "$REMINDERS_FILE"
            echo "Added reminder '$ID': $TEXT (reminds from $REMIND_FROM)"
        else
            jq --arg id "$ID" --arg text "$TEXT" --arg date "$DATE" \
                '. + [{"id": $id, "text": $text, "status": "pending", "created": $date}]' \
                "$REMINDERS_FILE" > "${REMINDERS_FILE}.tmp" && mv "${REMINDERS_FILE}.tmp" "$REMINDERS_FILE"
            echo "Added reminder '$ID': $TEXT"
        fi
        ;;

    *)
        echo "Usage: reminders.sh {check|list|done <id>|add \"text\"}" >&2
        exit 1
        ;;
esac

#!/bin/bash
# Usage: loki-query.sh <service_name> [options]
#
# Query Grafana Loki logs for a given service.
# Requires GRAFANA_LOKI_URL, GRAFANA_LOKI_USER, GRAFANA_LOKI_TOKEN in environment.
#
# Examples:
#   loki-query.sh voidbot-backend
#   loki-query.sh voidbot-backend --since 1h --limit 100
#   loki-query.sh voidbot-backend --since 24h --grep "error"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONFIG_DIR="$(dirname "$SCRIPT_DIR")/config"

if [ -f "$CONFIG_DIR/grafana.env" ]; then
    set -a
    source "$CONFIG_DIR/grafana.env"
    set +a
fi

if [ -z "${GRAFANA_LOKI_URL:-}" ] || [ -z "${GRAFANA_LOKI_USER:-}" ] || [ -z "${GRAFANA_LOKI_TOKEN:-}" ]; then
    echo "Error: Grafana Loki credentials not set. Add them to config/grafana.env." >&2
    exit 1
fi

SERVICE="${1:?Usage: loki-query.sh <service_name> [--since <duration>] [--limit <n>] [--grep <pattern>]}"
shift

# Defaults
SINCE="1h"
LIMIT=50
GREP_PATTERN=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --since) SINCE="$2"; shift 2 ;;
        --limit) LIMIT="$2"; shift 2 ;;
        --grep)  GREP_PATTERN="$2"; shift 2 ;;
        *) echo "Unknown option: $1" >&2; exit 1 ;;
    esac
done

# Build LogQL query
if [ -n "$GREP_PATTERN" ]; then
    QUERY="{service_name=\"$SERVICE\"} |~ \"(?i)$GREP_PATTERN\""
else
    QUERY="{service_name=\"$SERVICE\"}"
fi

# Calculate start time (now - SINCE)
# Parse duration: supports h (hours), m (minutes), d (days)
UNIT="${SINCE: -1}"
VALUE="${SINCE%?}"
case "$UNIT" in
    m) SECONDS_AGO=$((VALUE * 60)) ;;
    h) SECONDS_AGO=$((VALUE * 3600)) ;;
    d) SECONDS_AGO=$((VALUE * 86400)) ;;
    *) echo "Error: unsupported duration unit '$UNIT'. Use m, h, or d." >&2; exit 1 ;;
esac

START_NS=$(( ($(date +%s) - SECONDS_AGO) * 1000000000 ))

RESPONSE=$(curl -s -G \
    --user "$GRAFANA_LOKI_USER:$GRAFANA_LOKI_TOKEN" \
    "$GRAFANA_LOKI_URL/loki/api/v1/query_range" \
    --data-urlencode "query=$QUERY" \
    --data-urlencode "start=$START_NS" \
    --data-urlencode "limit=$LIMIT" \
    --data-urlencode "direction=backward")

STATUS=$(echo "$RESPONSE" | jq -r '.status // "error"')
if [ "$STATUS" != "success" ]; then
    echo "Loki query failed:" >&2
    echo "$RESPONSE" | jq . >&2
    exit 1
fi

# Extract and format log lines with timestamps
echo "$RESPONSE" | jq -r '
    .data.result[]
    | .values[]
    | .[0] as $ts
    | .[1] as $line
    | ($ts | tonumber / 1000000000 | strftime("%Y-%m-%d %H:%M:%S")) + "  " + $line
' | sort

COUNT=$(echo "$RESPONSE" | jq '[.data.result[].values[]] | length')
echo "--- $COUNT log lines from $SERVICE (last $SINCE) ---" >&2

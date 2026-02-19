# Grafana Loki Setup Guide

How to connect MaxAssist to Grafana Cloud Loki so scripts can query application logs.

## 1. Get Grafana Cloud Credentials

1. Log in to [grafana.com](https://grafana.com) and go to your stack
2. Navigate to **Connections > Data sources > Loki**
3. Note the following:
   - **URL** — the Loki endpoint (e.g. `https://logs-prod-XXX.grafana.net`)
   - **User** — the numeric user/instance ID
4. Go to **Security > API keys** (or **Service Accounts**)
5. Create a token with `logs:read` scope
6. Copy the token

## 2. Configure MaxAssist

Create `maxassist/config/grafana.env`:

```bash
GRAFANA_LOKI_URL=https://logs-prod-XXX.grafana.net
GRAFANA_LOKI_USER=123456
GRAFANA_LOKI_TOKEN=glc_your_token_here
```

> **Important**: `grafana.env` is gitignored. Never commit tokens.

## 3. Add to Docker Compose

Add the env file to your `docker-compose.yml`:

```yaml
services:
  maxassist:
    env_file:
      - maxassist/config/slack.env
      - maxassist/config/grafana.env
```

Restart the container:

```bash
docker compose up -d
```

## 4. Test the Connection

```bash
docker exec maxassist /maxassist/scripts/loki-query.sh your-service-name --since 1h --limit 5
```

You should see timestamped log lines.

## Usage

```bash
# Last 50 lines (default)
loki-query.sh my-service

# Last 24 hours, 100 lines
loki-query.sh my-service --since 24h --limit 100

# Last 30 minutes, filter for errors (case-insensitive)
loki-query.sh my-service --since 30m --grep "error"

# Last 7 days, filter for a specific pattern
loki-query.sh my-service --since 7d --grep "timeout"
```

### Options

| Option | Default | Description |
|---|---|---|
| `--since` | `1h` | How far back to query. Supports `m` (minutes), `h` (hours), `d` (days) |
| `--limit` | `50` | Maximum number of log lines to return |
| `--grep` | _(none)_ | Case-insensitive regex filter applied server-side via LogQL |

### Output

- Log lines are printed to stdout with timestamps, sorted chronologically
- A summary line is printed to stderr: `--- N log lines from service (last duration) ---`
- Exit code 1 on any error (missing credentials, API failure, bad options)

## How It Works

The script queries the Loki [query_range API](https://grafana.com/docs/loki/latest/reference/loki-http-api/#query-logs-within-a-range-of-time) directly via curl — no `logcli` binary needed inside the container.

The query uses the `service_name` label, which is the standard label used by Grafana Cloud for identifying applications.

## Troubleshooting

| Error | Fix |
|---|---|
| `Grafana Loki credentials not set` | Check that `grafana.env` exists and is listed in `docker-compose.yml` under `env_file` |
| `Loki query failed` | Check the JSON error output — usually an auth or query syntax issue |
| No results returned | Verify the `service_name` label matches what your app sends to Loki |
| `unsupported duration unit` | Use `m`, `h`, or `d` (e.g. `--since 30m`, `--since 2h`, `--since 7d`) |

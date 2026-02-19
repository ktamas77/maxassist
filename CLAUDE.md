# MaxAssist — Claude Code Instructions

You are running on the host machine in the repo root. The `maxassist/` subdirectory contains all runtime data and is mounted into the Docker container at `/maxassist/`.

## Architecture

- **You (Claude Code)** run on the host. You read/write files under `maxassist/`.
- **The container** runs cron as PID 1. Scripts and cron jobs execute inside it.
- **Volume mount** — `maxassist/` on the host is mounted as `/maxassist/` in the container. Changes are immediate.

## Folder Structure

- `maxassist/config/` — Environment files and data. `slack.env` for Slack, `grafana.env` for Grafana Loki, `reminders.json` for one-time reminders.
- `maxassist/scripts/` — All executable scripts. You write new scripts here.
- `maxassist/memory/` — Persistent context. Always update `maxassist/memory/context.md` after making changes.
- `maxassist/output/` — Runtime output from scripts (logs, reports, JSON).
- `maxassist/cron/` — `crontab.txt` mirrors the active crontab inside the container.

## Conventions

### Writing Scripts
- Write scripts to `maxassist/scripts/` as bash or python.
- Make them executable: `chmod +x maxassist/scripts/your-script.sh`
- Scripts run inside the container at `/maxassist/scripts/`.
- Scripts should be self-contained and idempotent.
- Write output/logs to `/maxassist/output/` (container path).
- Source `/maxassist/config/slack.env` for Slack credentials (container path).

### Querying Logs
Query Grafana Loki logs from inside the container:
```bash
/maxassist/scripts/loki-query.sh <service_name> [--since <duration>] [--limit <n>] [--grep <pattern>]
```
See `docs/grafana-loki-setup.md` for full setup and usage.

### Posting to Slack
Use the included helper (from inside the container):
```bash
/maxassist/scripts/slack-post.sh "#channel" "Your message here"
```

### Managing Cron
To add or modify scheduled tasks, execute commands inside the container:
```bash
# View current crontab
docker exec maxassist crontab -l

# Add a new entry
docker exec maxassist bash -c '(crontab -l 2>/dev/null; echo "*/30 * * * * /maxassist/scripts/your-script.sh") | crontab -'
```
After any cron change:
1. Update `maxassist/cron/crontab.txt` to mirror the active crontab
2. Log the change in `maxassist/memory/context.md`

### Running Scripts Manually
Test scripts inside the container before scheduling:
```bash
docker exec maxassist /maxassist/scripts/your-script.sh
```

### Updating Memory
After every session where you make changes, update `maxassist/memory/context.md` with:
- What was added/changed/removed
- Current active scripts and their schedules
- Any decisions made and why

### Managing Reminders
One-time reminders are stored in `maxassist/config/reminders.json` and posted daily to Slack by cron. Use the `/reminder` slash command or run directly:
```bash
# List all reminders
docker exec maxassist /maxassist/scripts/reminders.sh list

# Mark one done
docker exec maxassist /maxassist/scripts/reminders.sh done <id>

# Add a new reminder (optionally with a start date)
docker exec maxassist /maxassist/scripts/reminders.sh add "Do the thing"
docker exec maxassist /maxassist/scripts/reminders.sh add "Do the thing" 2025-06-01
```

Each reminder has:
- `id` — slug for referencing
- `text` — what to do
- `status` — `pending` or `done`
- `remind_from` (optional) — `YYYY-MM-DD` or `YYYY-MM-DDTHH:MM`. Reminder stays silent until this date/time.

Schedule `reminders.sh check` in cron (e.g. `0 9 * * *`). It posts all active pending reminders to Slack. If none are pending (or all are waiting), it stays silent.

### Using External AI APIs
For tasks that need AI reasoning (summarization, classification), write scripts that call cheap external APIs (e.g. OpenAI gpt-4o-mini). Store API keys in `maxassist/config/` env files. Never hardcode secrets in scripts.

## Session Logging

**IMPORTANT**: After completing each user request, append a summary to the daily log file:
- File: `docs/log-YYYY-MM-DD.md` (use today's date)
- Create the file if it doesn't exist, with header `# Session Log — YYYY-MM-DD`
- Each session/task gets a `## Session N` or `### Task description` header
- Log what was done: files created/modified, commands run, decisions made
- Keep entries concise but complete enough to reconstruct what happened

Example entry:
```markdown
### Created health check script
- Added `maxassist/scripts/health-check.sh`
- Scheduled at `*/30 * * * *` in crontab
- Posts alerts to #gerty-assistant on failure
```

## Important
- Scripts execute inside the container, not on the host. Use `docker exec` to run or test them.
- Cron runs as PID 1 in the container — it's always active as long as the container is running.
- All paths inside the container are under `/maxassist/`.
- The container has curl, jq, python3, and bash available.

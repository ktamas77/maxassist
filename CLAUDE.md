# MaxAssist — Claude Code Instructions

You are operating inside a MaxAssist container. This is a personal automation assistant. The user interacts with you through Claude CLI to design, build, and manage automated scripts that run via cron.

## Folder Structure

- `config/` — Environment files and service configuration. `slack.env` contains Slack webhook credentials.
- `scripts/` — All executable scripts. You write new scripts here. Use `slack-post.sh` as the Slack posting helper.
- `memory/` — Persistent context. Always update `memory/context.md` after making changes.
- `output/` — Runtime output from scripts (logs, reports, JSON). Scripts write here.
- `cron/` — `crontab.txt` mirrors the active crontab. Keep it in sync.

## Conventions

### Writing Scripts
- Write scripts to `scripts/` as bash or python.
- Make them executable: `chmod +x scripts/your-script.sh`
- Scripts should be self-contained and idempotent.
- Write output/logs to `output/`.
- Source `config/slack.env` for Slack credentials.

### Posting to Slack
Use the included helper:
```bash
scripts/slack-post.sh "#channel" "Your message here"
```

### Managing Cron
When adding or removing scheduled tasks:
1. Edit the system crontab: `crontab -l` to read, pipe to `crontab -` to write
2. Update `cron/crontab.txt` to mirror the active crontab
3. Log the change in `memory/context.md`

### Updating Memory
After every session where you make changes, update `memory/context.md` with:
- What was added/changed/removed
- Current active scripts and their schedules
- Any decisions made and why

### Using External AI APIs
For tasks that need AI reasoning (summarization, classification), write scripts that call cheap external APIs (e.g. OpenAI gpt-4o-mini). Store API keys in `config/` env files. Never hardcode secrets in scripts.

## Important
- You are running inside a Docker container. The host filesystem is mounted via volumes.
- Cron runs as PID 1 in this container — it's always active.
- The user will `docker exec` in to talk to you. When they leave, scripts keep running on schedule.

# MaxAssist — Claude Code Instructions

You are running on the host machine inside the `maxassist/` project folder. A Docker container (`maxassist`) runs alongside you as the execution environment — it handles cron scheduling and script execution in a predictable Debian Linux environment.

## Architecture

- **You (Claude Code)** run on the host. You read/write files in this project folder.
- **The container** runs cron as PID 1. Scripts and cron jobs execute inside it.
- **Volumes are shared** — files you write to `scripts/`, `config/`, `memory/`, `output/` are immediately available inside the container.

## Folder Structure

- `config/` — Environment files. `slack.env` contains Slack webhook credentials.
- `scripts/` — All executable scripts. You write new scripts here.
- `memory/` — Persistent context. Always update `memory/context.md` after making changes.
- `output/` — Runtime output from scripts (logs, reports, JSON).
- `cron/` — `crontab.txt` mirrors the active crontab inside the container.

## Conventions

### Writing Scripts
- Write scripts to `scripts/` as bash or python.
- Make them executable: `chmod +x scripts/your-script.sh`
- Scripts run inside the container at `/maxassist/scripts/`.
- Scripts should be self-contained and idempotent.
- Write output/logs to `output/`.
- Source `config/slack.env` for Slack credentials.

### Posting to Slack
Use the included helper:
```bash
scripts/slack-post.sh "#channel" "Your message here"
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
1. Update `cron/crontab.txt` to mirror the active crontab
2. Log the change in `memory/context.md`

### Running Scripts Manually
Test scripts inside the container before scheduling:
```bash
docker exec maxassist /maxassist/scripts/your-script.sh
```

### Updating Memory
After every session where you make changes, update `memory/context.md` with:
- What was added/changed/removed
- Current active scripts and their schedules
- Any decisions made and why

### Using External AI APIs
For tasks that need AI reasoning (summarization, classification), write scripts that call cheap external APIs (e.g. OpenAI gpt-4o-mini). Store API keys in `config/` env files. Never hardcode secrets in scripts.

## Important
- Scripts execute inside the container, not on the host. Use `docker exec` to run or test them.
- Cron runs as PID 1 in the container — it's always active as long as the container is running.
- All paths inside the container are under `/maxassist/`.
- The container has curl, jq, python3, and bash available.

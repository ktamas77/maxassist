# MaxAssist

100% Anthropic TOS-compatible personal assistant using Claude Opus via Claude Max. No API wrapping, no bot framework, no gray areas.

You run Claude Code CLI on your machine — Anthropic's official tool, used exactly as intended. A Docker container runs alongside as a predictable execution environment for the scripts and cron jobs Claude creates. Claude designs the automation, the container runs it.

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/ktamas77/maxassist.git
cd maxassist

# 2. Configure Slack
cp config/slack.env.example config/slack.env
# Edit config/slack.env with your webhook URL

# 3. Start the execution container
docker compose up -d

# 4. Run Claude Code in the project folder
claude
```

Once inside Claude, try:

> "Set up a health check for https://myapp.com every 30 minutes. Post failures to #alerts on Slack."

Claude writes a script, adds a cron entry inside the container, and updates its memory. You close the terminal — the container keeps running the scripts on schedule.

## How It Works

```
Host machine                          Docker container (maxassist)
─────────────                         ──────────────────────────────

You ──▶ claude (CLI)                  cron (PID 1, always running)
        │                               │
        ├── reads CLAUDE.md             ├── executes scripts on schedule
        ├── reads memory/context.md     ├── scripts post to Slack
        ├── writes scripts/new.sh       └── scripts write to output/
        ├── docker exec: add cron
        └── updates memory/

   ◀── single volume mount (.:/maxassist) ──▶
```

- **Claude Code** runs natively on your host — already authenticated with your Max subscription
- **The container** is a lightweight Debian environment running cron, with curl, jq, python3, and bash
- **Single volume mount** maps the entire project folder into the container — Claude writes files on the host and the container sees them immediately
- **No Claude CLI inside the container** — the container is purely an execution runtime

## Project Structure

```
maxassist/                            ◀── mounted as /maxassist in container
├── CLAUDE.md                     # Claude Code reads this automatically
├── Dockerfile
├── docker-compose.yml
├── entrypoint.sh                 # Loads crontab on container start
├── config/
│   ├── slack.env.example         # Template — copy to slack.env
│   └── slack.env                 # Your Slack webhook (gitignored)
├── scripts/
│   ├── slack-post.sh             # Slack posting helper
│   └── example-health-check.sh   # Reference template
├── memory/
│   └── context.md                # Claude maintains this across sessions
├── output/                       # Runtime output from scripts (gitignored)
└── cron/
    └── crontab.txt               # Persisted crontab — loaded on container start
```

## What You Can Build

**Deterministic tasks** (no AI needed, no extra cost):
- Health checks and uptime monitoring
- Log tailing and pattern matching
- Backup verification and disk usage alerts
- Scheduled reports from APIs
- Data fetching and formatting

**AI-powered tasks** (Claude writes scripts that call cheap external models):
- Log summarization via GPT-4o-mini
- Anomaly detection and classification
- Natural language report generation

```python
# Claude writes this script — it runs via cron inside the container
import openai, os, requests

client = openai.OpenAI()  # OPENAI_API_KEY from env
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": f"Summarize these logs:\n{logs}"}]
)

webhook = os.environ["SLACK_WEBHOOK_URL"]
requests.post(webhook, json={"text": response.choices[0].message.content})
```

## Customizing

Edit `CLAUDE.md` to shape how Claude behaves — define your services, set conventions, specify preferred languages, add custom reporting rules. Claude reads it automatically every session.

`memory/context.md` is maintained by Claude across sessions — it tracks what's set up, decisions made, and current state.

## TOS Compliance

This is 100% compatible with Anthropic's Terms of Service:

- **Human-initiated** — you open a terminal and type `claude`. Every session is a genuine interactive conversation.
- **Official interface** — Claude Code CLI is Anthropic's own product, used as intended.
- **No programmatic access** — no automation loops, no piped prompts, no API wrapping, no headless usage.
- **Scripts are independent** — cron jobs are plain bash/python running in a Docker container. Claude is not involved at runtime.
- **Single user** — your Max subscription, your machine, your assistant.

## Philosophy

MaxAssist isn't a bot. It's a **workflow**. You sit down with Claude Opus, describe what you need automated, and Claude builds it. The automation runs without Claude in a predictable containerized environment. Next time you sit down, you review output, iterate, and expand.

Think of it as having a senior engineer on retainer who you meet with periodically to design and improve your automation infrastructure. The infrastructure runs 24/7, but the engineer only works when you're in the meeting.

## License

MIT

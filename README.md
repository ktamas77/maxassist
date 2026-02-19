# MaxAssist

A TOS-compliant personal assistant template built on Claude Code CLI + Claude Max. No API wrapping, no always-on bot, no OAuth harness — just a Dockerized environment where Claude Code writes scripts and cron runs them.

Clone this repo, run the container, exec in, and talk to Claude. It reads the project state, writes automation scripts, schedules them via cron, and posts results to Slack. The scripts run 24/7 — Claude is only active when you're talking to it.

## Quick Start

```bash
# 1. Clone the repo
git clone https://github.com/ktamas77/maxassist.git
cd maxassist

# 2. Configure Slack
cp config/slack.env.example config/slack.env
# Edit config/slack.env with your webhook URL

# 3. Build and start the container
docker compose up -d

# 4. Exec into the container
docker exec -it maxassist bash

# 5. Install Claude Code CLI (first time only)
npm install -g @anthropic-ai/claude-code

# 6. Start Claude and begin building your assistant
claude
```

Once inside Claude, try:

> "Set up a health check for https://myapp.com every 30 minutes. Post failures to #alerts on Slack."

Claude will read the project config, write a script, add a cron entry, and update the memory. The script runs on schedule even after you disconnect.

## How It Works

```
You (terminal) ──▶ docker exec -it maxassist bash ──▶ claude
                                                        │
                   Claude reads CLAUDE.md, memory/,     │
                   config/, existing scripts             │
                                                        ▼
                   Claude writes scripts/new-task.sh
                   Claude updates crontab
                   Claude updates memory/context.md
                                                        │
You disconnect ◀────────────────────────────────────────┘
                                                        │
                   cron keeps running scripts            │
                   scripts post results to Slack ────────┘
```

1. **You exec into the container** and run `claude`
2. **Claude reads the project state** — config, scripts, memory, cron schedule, output logs
3. **You describe what you need** — monitoring, reporting, data collection, alerts
4. **Claude writes scripts** (bash/python), sets up cron entries, configures Slack output
5. **You disconnect** — cron keeps running everything on schedule
6. **Next session** — Claude reads output/logs and you iterate

The key: **Claude is only active during your interactive CLI session.** Everything it produces runs independently as plain scripts + cron.

## Project Structure

```
maxassist/
├── CLAUDE.md                  # Instructions for Claude Code (read automatically)
├── Dockerfile
├── docker-compose.yml
├── config/
│   ├── slack.env.example      # Template — copy to slack.env
│   └── slack.env              # Your Slack webhook (gitignored)
├── scripts/
│   ├── slack-post.sh          # Slack posting helper (used by other scripts)
│   └── example-health-check.sh  # Reference template
├── memory/
│   └── context.md             # Claude maintains this — tracks state & decisions
├── output/                    # Runtime output from scripts (gitignored)
└── cron/
    └── crontab.txt            # Mirror of active crontab (Claude keeps in sync)
```

**Volumes are mounted from the host**, so everything persists across container rebuilds. Your scripts, config, and memory live on your machine.

## What You Can Build

**Deterministic tasks** (no AI needed, no extra cost):
- Health checks and uptime monitoring
- Log tailing and pattern matching
- Backup verification
- Disk/resource usage alerts
- Data fetching and formatting
- Scheduled reports from APIs

**AI-powered tasks** (Claude writes scripts that call cheap external models):
- Log summarization via GPT-4o-mini
- Anomaly detection and classification
- Natural language report generation
- Content moderation checks

```python
# Example: Claude writes this script, it runs via cron independently
# Uses a cheap external model for the AI part
import openai
client = openai.OpenAI()  # OPENAI_API_KEY from env
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": f"Summarize these logs:\n{logs}"}]
)
post_to_slack(response.choices[0].message.content)
```

## Customizing Your Assistant

The `CLAUDE.md` file tells Claude how to behave in this project. Edit it to:
- Define your services and infrastructure
- Set naming conventions for scripts
- Specify preferred languages (bash vs python)
- Add custom instructions for how reports should look
- Define escalation rules (when to alert, when to just log)

The `memory/context.md` file is maintained by Claude across sessions. It tracks what's set up, what decisions were made, and what the current state is.

## TOS Compliance

This approach stays within Anthropic's terms because:

- **Human-initiated** — every Claude interaction starts with you opening a terminal and typing `claude`
- **Official interface** — Claude Code CLI is Anthropic's own product
- **Scripts are independent** — cron jobs are plain bash/python, no Claude involved at runtime
- **No programmatic access** — no automation loops, no piped prompts, no API wrapping

**What would NOT be OK:** wrapping Claude Code in a script that auto-sends prompts, building a service layer on top of Claude Max, or using headless/programmatic access to simulate interaction.

## Philosophy

MaxAssist isn't a bot. It's a **workflow**. You sit down with Claude, describe what you need automated, and Claude builds it. The automation runs without Claude. Next time you sit down, you review, iterate, and expand.

Think of it as having a senior engineer on retainer who you meet with periodically to design and improve your automation infrastructure. The infrastructure runs 24/7, but the engineer only works when you're in the meeting.

## License

MIT

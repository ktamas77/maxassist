# MaxAssist

A TOS-compliant personal assistant built entirely on Claude Code CLI + Claude Max subscription. No API wrapping, no always-on bot, no OAuth harness — just Claude Code reading local files, writing scripts, and scheduling tasks via cron.

## The Problem

Running an always-on AI assistant (like ClawdBot) through the Anthropic API or wrapped UIs risks:
- **TOS violations** — using Claude Max for automated/programmatic access via third-party harnesses
- **API costs** — pay-per-token pricing adds up for continuous monitoring and reporting
- **Complexity** — OAuth flows, bot frameworks, hosted infrastructure

## The Idea

Claude Max is intended for interactive use through official Anthropic interfaces. Claude Code CLI **is** an official interface. What if the assistant is just... you talking to Claude Code in a project folder?

### How It Works

1. **You open a terminal** and run `claude` in the `maxassist/` folder
2. **Claude reads the project state** — config files, scripts, memories, schedules, reports
3. **You ask it to do things** — "check the server status every hour and post to #ops on Slack"
4. **Claude writes a script** (bash/python/node), sets up a cron entry, and it runs independently
5. **Next time you chat**, Claude reads logs/output and you iterate

The key distinction: **Claude is only active when you're interacting with it through the CLI.** The scripts it produces run independently — they're just regular programs on your machine.

## Architecture

```
maxassist/
├── README.md
├── config/
│   ├── slack.env          # Slack webhook URLs, channel mappings
│   ├── services.json      # Services to monitor, endpoints, etc.
│   └── schedule.json      # Desired cron schedules (human-readable)
├── scripts/
│   ├── health-check.sh    # Claude-generated: ping services, post to Slack
│   ├── log-summary.py     # Claude-generated: query Loki, summarize, report
│   ├── backup-status.sh   # Claude-generated: check backup state
│   └── ...                # Any script Claude writes on demand
├── memory/
│   ├── context.md         # What MaxAssist knows about your setup
│   ├── decisions.md       # Past decisions and rationale
│   └── history.md         # Log of what was created/changed and when
├── output/
│   ├── last-health.json   # Latest output from health-check
│   ├── last-summary.md    # Latest log summary
│   └── ...
├── cron/
│   └── crontab.txt        # Current cron entries (mirrored for reference)
└── CLAUDE.md              # Project instructions for Claude Code
```

### Script Generation Flow

```
You: "Monitor the voidbot API every 30 min, post failures to #alerts"
  │
  ▼
Claude Code reads config/slack.env, config/services.json
  │
  ▼
Claude Code writes scripts/voidbot-monitor.sh
  (curl endpoint, check status, post to Slack webhook on failure)
  │
  ▼
Claude Code runs: crontab -l + new entry → crontab -
  (adds: */30 * * * * /path/to/scripts/voidbot-monitor.sh)
  │
  ▼
Claude Code updates memory/context.md, cron/crontab.txt
  │
  ▼
Script runs independently via cron — no Claude involved
```

### Non-Deterministic Tasks (Using Other Models)

For tasks requiring AI reasoning (summarization, classification, anomaly detection), Claude Code generates scripts that call **cheaper external APIs**:

```python
# Claude writes this script, but it runs independently via cron
# Uses OpenAI GPT-4o-mini at ~$0.15/1M tokens for cheap summarization

import openai
client = openai.OpenAI()  # uses OPENAI_API_KEY from env
response = client.chat.completions.create(
    model="gpt-4o-mini",
    messages=[{"role": "user", "content": f"Summarize these logs:\n{logs}"}]
)
post_to_slack(response.choices[0].message.content)
```

This keeps the architecture honest:
- **Claude Max** — interactive design, code generation, debugging (through official CLI)
- **Cheap API calls** — automated reasoning tasks that run in cron scripts
- **Deterministic scripts** — health checks, data fetching, formatting (no AI needed)

## Feasibility Assessment

### What Works Well

| Aspect | Assessment |
|--------|-----------|
| **TOS compliance** | Claude Code CLI is an official Anthropic product. Human-initiated interactive sessions are the intended use case. Scripts run independently without Claude. |
| **Cost** | Claude Max flat rate for the interactive part. Only pay-per-token for cheap model calls in automated scripts. Most monitoring/alerting is deterministic (no AI needed). |
| **Capability** | Claude Code can read files, write scripts, run shell commands, manage cron — everything needed. |
| **State continuity** | CLAUDE.md + memory/ folder gives Claude full context each session. Claude Code's own memory system adds another layer. |
| **Script quality** | Claude writes excellent bash/python. Scripts are human-readable and editable. |

### Limitations & Honest Risks

| Concern | Reality |
|---------|---------|
| **Not real-time** | You must open a terminal session to iterate. No push notifications to *you* (scripts can push to Slack though). |
| **No conversation memory across sessions** | Claude Code has memory features, but context is mostly file-based. The memory/ folder is the workaround. |
| **Cron is basic** | No retry logic, no dependency chains. For complex workflows, scripts need to handle their own error cases. |
| **Manual bootstrapping** | Each new task requires a conversation. Can't say "hey bot, do X" from your phone. |
| **Gray area: excessive automation** | If you open Claude Code 50 times a day just to trigger automated workflows without genuine interaction, that *could* push boundaries. The intent matters — genuine interactive use is fine. |

### TOS Compliance Analysis

**Clearly OK:**
- Opening Claude Code CLI and asking it to write a script
- Having Claude Code set up cron jobs
- Claude Code reading local files and project state
- Scripts calling other APIs (OpenAI, etc.) independently

**Clearly NOT OK:**
- Wrapping Claude Code in an automation loop that simulates user interaction
- Using headless/programmatic access to pipe prompts to Claude
- Building a service layer on top of Claude Max that serves multiple users

**The distinction that matters:** A human initiates each Claude interaction through the official CLI. What Claude produces (scripts, cron entries) runs independently.

## Getting Started

```bash
# 1. Clone and enter the project
cd maxassist/

# 2. Set up config
cp config/slack.env.example config/slack.env
# Edit with your Slack webhook URLs

# 3. Start a Claude Code session
claude

# 4. Ask Claude to set things up
# "Read the config and set up a health check for voidbot that posts to #ops every hour"
```

## Comparison with ClawdBot

| Feature | ClawdBot | MaxAssist |
|---------|----------|-----------|
| Interface | Slack/Discord bot | Claude Code CLI |
| Always-on | Yes (server process) | No (human-initiated sessions) |
| TOS risk | Medium-High (API wrapping, automated access) | Low (official CLI, interactive use) |
| Cost model | Per-token API | Flat Max subscription + cheap API for automation |
| Mobile access | Yes (via Slack) | No (terminal only) |
| Real-time responses | Yes | No (async via scripts/cron) |
| Script execution | In-process | Independent (cron/manual) |
| State | Database | Local files |

## Philosophy

MaxAssist isn't a bot. It's a **workflow** — you sit down with Claude Code, describe what you need automated, and Claude builds it. The automation runs without Claude. Next time you sit down, you review, iterate, and expand.

Think of it as having a senior engineer on retainer who you meet with periodically to design and improve your automation infrastructure. The infrastructure runs 24/7, but the engineer only works when you're in the meeting.

# Slack Setup Guide

How to connect MaxAssist to a Slack workspace so scripts can post messages.

## 1. Create a Slack App

1. Go to [api.slack.com/apps](https://api.slack.com/apps) and click **Create New App**
2. Choose **From scratch**
3. Name it (e.g. "MaxAssist") and select your workspace
4. Click **Create App**

## 2. Configure Bot Permissions

1. In the app settings, go to **OAuth & Permissions**
2. Under **Bot Token Scopes**, add:
   - `chat:write` — post messages to channels
   - `chat:write.public` — post to channels the bot hasn't joined (optional)
3. Scroll up and click **Install to Workspace**
4. Authorize the app
5. Copy the **Bot User OAuth Token** (starts with `xoxb-`)

## 3. (Optional) Enable Socket Mode

Only needed if you want the bot to receive events or slash commands.

1. Go to **Socket Mode** in the app settings
2. Toggle it on
3. Create an app-level token with `connections:write` scope
4. Copy the **App-Level Token** (starts with `xapp-`)

## 4. Configure MaxAssist

Create `maxassist/config/slack.env`:

```bash
# Required
SLACK_BOT_TOKEN=xoxb-your-token-here
SLACK_DEFAULT_CHANNEL=#your-channel

# Optional: channel IDs for routing messages
# SLACK_CHANNEL_ALERTS=C0XXXXXXXXX
# SLACK_CHANNEL_REPORTS=C0XXXXXXXXX

# Optional: socket mode (only if enabled above)
# SLACK_APP_TOKEN=xapp-your-token-here
```

> **Important**: `slack.env` is gitignored. Never commit tokens.

## 5. Invite the Bot to Channels

In Slack, go to each channel you want the bot to post in and run:

```
/invite @MaxAssist
```

Or use the `chat:write.public` scope to skip this step for public channels.

## 6. Test the Connection

Start the container and send a test message:

```bash
docker compose up -d --build
docker exec maxassist /maxassist/scripts/slack-post.sh "#your-channel" "Hello from MaxAssist!"
```

You should see `Message posted to #your-channel` and the message should appear in Slack.

## Troubleshooting

| Error | Fix |
|---|---|
| `SLACK_BOT_TOKEN not set` | Check that `slack.env` exists and is loaded (listed in `docker-compose.yml` under `env_file`) |
| `not_in_channel` | Invite the bot to the channel or add `chat:write.public` scope |
| `invalid_auth` | Token is wrong or revoked — regenerate in app settings |
| `channel_not_found` | Use channel ID (e.g. `C0XXXXXXXXX`) instead of channel name |

## How slack-post.sh Works

The script uses the [chat.postMessage](https://api.slack.com/methods/chat.postMessage) API:

```bash
/maxassist/scripts/slack-post.sh "#channel" "Your message here"
```

- Sources `config/slack.env` automatically
- Uses `SLACK_BOT_TOKEN` for authentication
- Falls back to `SLACK_DEFAULT_CHANNEL` if no channel argument given
- Exits with error code and message on failure

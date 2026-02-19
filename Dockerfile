FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    jq \
    cron \
    python3 \
    python3-pip \
    python3-venv \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" > /etc/apt/sources.list.d/nodesource.list \
    && apt-get update && apt-get install -y --no-install-recommends nodejs \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /maxassist/config \
    /maxassist/scripts \
    /maxassist/memory \
    /maxassist/output \
    /maxassist/cron

COPY CLAUDE.md /maxassist/CLAUDE.md
COPY config/slack.env.example /maxassist/config/slack.env.example
COPY scripts/ /maxassist/scripts/
COPY memory/context.md /maxassist/memory/context.md
COPY cron/crontab.txt /maxassist/cron/crontab.txt

RUN chmod +x /maxassist/scripts/*.sh

WORKDIR /maxassist

CMD ["cron", "-f"]

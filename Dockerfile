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
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /maxassist/config \
    /maxassist/scripts \
    /maxassist/memory \
    /maxassist/output \
    /maxassist/cron

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

COPY maxassist/scripts/ /maxassist/scripts/
COPY maxassist/cron/crontab.txt /maxassist/cron/crontab.txt

RUN chmod +x /maxassist/scripts/*.sh

WORKDIR /maxassist

ENTRYPOINT ["/entrypoint.sh"]

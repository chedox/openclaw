# OpenClaw Setup on Docker Desktop (MacBook Pro M1)

Panduan ini menjelaskan cara setup **OpenClaw** di **Docker Desktop** pada **MacBook Pro M1**, termasuk:

- `docker-compose.yml`
- file `.env`
- onboarding OpenAI provider
- start gateway
- login dashboard
- akses via Tailscale
- troubleshooting umum

---

## 1. Prasyarat

Pastikan sudah terpasang:

- Docker Desktop
- Git
- OpenSSL
- Tailscale (opsional, untuk akses remote privat)

Cek Docker:

```bash
docker --version
docker compose version

## 2. Structure Folder

Buat folder kerja:

mkdir -p ~/openclaw-docker/openclaw-data/config
mkdir -p ~/openclaw-docker/openclaw-data/workspace
cd ~/openclaw-docker

## 3. File docker-compose.yml

services:
  openclaw-gateway:
    image: ${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN:-}
      OPENAI_API_KEY: ${OPENAI_API_KEY:-}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
      GEMINI_API_KEY: ${GEMINI_API_KEY:-}
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY:-}
      OPENCLAW_ALLOW_INSECURE_PRIVATE_WS: ${OPENCLAW_ALLOW_INSECURE_PRIVATE_WS:-}
      CLAUDE_AI_SESSION_KEY: ${CLAUDE_AI_SESSION_KEY:-}
      CLAUDE_WEB_SESSION_KEY: ${CLAUDE_WEB_SESSION_KEY:-}
      CLAUDE_WEB_COOKIE: ${CLAUDE_WEB_COOKIE:-}
      TZ: ${OPENCLAW_TZ:-Asia/Jakarta}
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    ports:
      - "${OPENCLAW_GATEWAY_PORT:-18789}:18789"
      - "${OPENCLAW_BRIDGE_PORT:-18790}:18790"
    init: true
    restart: unless-stopped
    command:
      - node
      - dist/index.js
      - gateway
      - --bind
      - ${OPENCLAW_GATEWAY_BIND:-lan}
      - --port
      - "18789"
    healthcheck:
      test:
        - CMD
        - node
        - -e
        - fetch('http://127.0.0.1:18789/healthz').then((r)=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))
      interval: 30s
      timeout: 5s
      retries: 5
      start_period: 20s

  openclaw-cli:
    image: ${OPENCLAW_IMAGE:-ghcr.io/openclaw/openclaw:latest}
    network_mode: "service:openclaw-gateway"
    cap_drop:
      - NET_RAW
      - NET_ADMIN
    security_opt:
      - no-new-privileges:true
    environment:
      HOME: /home/node
      TERM: xterm-256color
      OPENCLAW_GATEWAY_TOKEN: ${OPENCLAW_GATEWAY_TOKEN:-}
      OPENAI_API_KEY: ${OPENAI_API_KEY:-}
      ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-}
      GEMINI_API_KEY: ${GEMINI_API_KEY:-}
      OPENROUTER_API_KEY: ${OPENROUTER_API_KEY:-}
      OPENCLAW_ALLOW_INSECURE_PRIVATE_WS: ${OPENCLAW_ALLOW_INSECURE_PRIVATE_WS:-}
      BROWSER: echo
      CLAUDE_AI_SESSION_KEY: ${CLAUDE_AI_SESSION_KEY:-}
      CLAUDE_WEB_SESSION_KEY: ${CLAUDE_WEB_SESSION_KEY:-}
      CLAUDE_WEB_COOKIE: ${CLAUDE_WEB_COOKIE:-}
      TZ: ${OPENCLAW_TZ:-Asia/Jakarta}
    volumes:
      - ${OPENCLAW_CONFIG_DIR}:/home/node/.openclaw
      - ${OPENCLAW_WORKSPACE_DIR}:/home/node/.openclaw/workspace
    stdin_open: true
    tty: true
    init: true
    entrypoint:
      - node
      - dist/index.js
    depends_on:
      - openclaw-gateway

- validasi yml :

  docker compose config

## 4. File .env

- Buat file .env

OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
OPENCLAW_CONFIG_DIR=./openclaw-data/config
OPENCLAW_WORKSPACE_DIR=./openclaw-data/workspace

OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_TZ=Asia/Jakarta

OPENCLAW_GATEWAY_TOKEN=ISI_DENGAN_TOKEN_ACAK_ASLI
OPENAI_API_KEY=ISI_DENGAN_API_KEY_OPENAI_ASLI

- Buat token acak :

TOKEN="$(openssl rand -hex 32)"

- Contoh membuat .env otomatis :

TOKEN="$(openssl rand -hex 32)"

cat > .env <<EOF
OPENCLAW_IMAGE=ghcr.io/openclaw/openclaw:latest
OPENCLAW_CONFIG_DIR=./openclaw-data/config
OPENCLAW_WORKSPACE_DIR=./openclaw-data/workspace
OPENCLAW_GATEWAY_PORT=18789
OPENCLAW_BRIDGE_PORT=18790
OPENCLAW_GATEWAY_BIND=lan
OPENCLAW_TZ=Asia/Jakarta
OPENCLAW_GATEWAY_TOKEN=$TOKEN
OPENAI_API_KEY=PASTE_OPENAI_API_KEY_ASLI_DI_SINI
EOF

## 5. Onboarding Provider OpenAPI

Jalankan onboarding :

docker compose --env-file .env run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js onboard --non-interactive \
  --mode local \
  --auth-choice openai-api-key \
  --secret-input-mode ref \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --accept-risk \
  --skip-health

Kalau sukses, OpenClaw akan membuat/menyimpan konfigurasi lokal

## 6. Konfigurasi openclaw.json

Lokasi file :

./openclaw-data/config/openclaw.json

Contoh gabungan config yang cocok untuk akses LAN/Tailscale :

{
  "agents": {
    "defaults": {
      "workspace": "/home/node/.openclaw/workspace",
      "models": {
        "openai/gpt-5.4": {
          "alias": "GPT"
        }
      },
      "model": {
        "primary": "openai/gpt-5.4"
      }
    }
  },
  "gateway": {
    "mode": "local",
    "auth": {
      "mode": "token",
      "token": {
        "source": "env",
        "provider": "default",
        "id": "OPENCLAW_GATEWAY_TOKEN"
      }
    },
    "port": 18789,
    "bind": "lan",
    "controlUi": {
      "allowedOrigins": [
        "http://127.0.0.1:18789",
        "http://localhost:18789",
        "http://IP-TAILSCALE-MAC-ANDA:18789",
        "http://HOSTNAME-TAILSCALE-ANDA.ts.net:18789"
      ]
    },
    "tailscale": {
      "mode": "off",
      "resetOnExit": false
    }
  },
  "session": {
    "dmScope": "per-channel-peer"
  },
  "tools": {
    "profile": "coding"
  },
  "plugins": {
    "entries": {
      "openai": {
        "enabled": true
      }
    }
  },
  "auth": {
    "profiles": {
      "openai:default": {
        "provider": "openai",
        "mode": "api_key"
      }
    }
  },
  "skills": {
    "install": {
      "nodeManager": "npm"
    }
  }
}

- Kalau hanya ingin akses lokal dulu, cukup :

"controlUi": {
  "allowedOrigins": [
    "http://127.0.0.1:18789",
    "http://localhost:18789"
  ]
}

## 7. Start Gateway

- Jalankan gateway :

docker compose --env-file .env up -d --force-recreate openclaw-gateway
docker compose --env-file .env ps

- Cek log :

docker compose --env-file .env logs --tail=100 openclaw-gateway

## 8. Login Dashboard

- Buka :

http://127.0.0.1:18789/

- Isi form login :

  Websocket url : ws://localhost:18789
  Gateway Token : isi dari .env
  Password      : kosongkan

- Ambil token :

  grep '^OPENCLAW_GATEWAY_TOKEN=' .env

  Salin nilai setelah  = lalu tempel pada Gateway Token

## 9. Script execute-claw.sh

#!/usr/bin/env bash
set -e

docker compose --env-file .env config >/dev/null

docker compose --env-file .env run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js onboard --non-interactive \
  --mode local \
  --auth-choice openai-api-key \
  --secret-input-mode ref \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --accept-risk \
  --skip-health

docker compose --env-file .env up -d openclaw-gateway
docker compose --env-file .env ps

- Beri izin eksekusi :

chmod +x execute-claw.sh
./execute-claw.sh


## 10. Tailscale untuk akses dari mana saja

- Install tailscale :

brew install --cask tailscale
tailscale up

- Cek IP Tailscale :

tailscale ip -4
tailscale status

- Tambahkan IP/hostname Tailscale ke allowedOrigins di openclaw.json.

Lalu akses dari device lain di tailnet yang sama:

http://IP-TAILSCALE-MAC:18789/

http://100.88.10.25:18789/

- Kalau buka dari device lain, WebSocket URL dashboard akan menyesuaikan :

ws://100.88.10.25:18789





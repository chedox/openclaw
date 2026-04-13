#!/usr/bin/env bash
set -e

set -a
source .env
set +a

echo "OPENAI_API_KEY loaded? ${OPENAI_API_KEY:+YES}"
echo "OPENCLAW_GATEWAY_TOKEN loaded? ${OPENCLAW_GATEWAY_TOKEN:+YES}"

docker compose --env-file .env run --rm --no-deps --entrypoint node openclaw-gateway \
  dist/index.js onboard --non-interactive \
  --mode local \
  --auth-choice openai-api-key \
  --secret-input-mode ref \
  --gateway-auth token \
  --gateway-token-ref-env OPENCLAW_GATEWAY_TOKEN \
  --accept-risk \
  --skip-health

docker compose up -d openclaw-gateway
docker compose ps
docker compose logs -f openclaw-gateway

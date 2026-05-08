#!/usr/bin/env bash
set -euo pipefail

: "${GITHUB_URL:?GITHUB_URL is required}"
: "${RUNNER_TOKEN:?RUNNER_TOKEN is required}"

RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,docker}"

cleanup() {
    if [ -f .runner ]; then
        ./config.sh remove --unattended --token "$RUNNER_TOKEN" || true
    fi
}

trap cleanup EXIT

./config.sh \
    --url "$GITHUB_URL" \
    --token "$RUNNER_TOKEN" \
    --name "$RUNNER_NAME" \
    --labels "$RUNNER_LABELS" \
    --unattended \
    --replace

./run.sh

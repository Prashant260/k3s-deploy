#!/usr/bin/env bash
set -euo pipefail

: "${RUNNER_TOKEN:?RUNNER_TOKEN is required}"

GITHUB_URL="${GITHUB_URL:-${REPO_URL:-}}"
RUNNER_NAME="${RUNNER_NAME:-$(hostname)}"
RUNNER_LABELS="${RUNNER_LABELS:-self-hosted,linux,docker}"

if [ -z "$GITHUB_URL" ]; then
    echo "GITHUB_URL or REPO_URL is required"
    exit 1
fi

echo "Configuring GitHub Actions runner for $GITHUB_URL"

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

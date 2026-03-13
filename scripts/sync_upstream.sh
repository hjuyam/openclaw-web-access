#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="https://raw.githubusercontent.com/eze-is/eze-skills/main/web-access/SKILL.md"
OUT="$ROOT_DIR/references/upstream/eze-skills_web-access_SKILL.latest.md"

echo "Fetching: $UPSTREAM_URL"
curl -fsSL "$UPSTREAM_URL" > "$OUT"

echo "Saved: $OUT"

# Upstream tracking

This repository (`openclaw-web-access`) is a fork/adaptation for **OpenClaw built-in tools** (`web_search`/`web_fetch`/`browser`).

We track upstream ideas from **eze-is/eze-skills** `web-access` skill, but we **do not** copy its implementation:
- upstream uses *Jina* and *agent-browser CDP* scripts for Claude Code
- OpenClaw version uses native tools and must follow OpenClaw safety constraints

## Files
- `eze-skills_web-access_SKILL.latest.md`: latest snapshot pulled from upstream main

## How to update snapshot
```bash
bash scripts/sync_upstream.sh
```

# Upstream comparison: eze-skills/web-access → openclaw-web-access

## What upstream has that is valuable (portable)

1) **Decision rules that reduce thrash**
- “够了吗？” stop rule
- “在层内解决” when blocked
- “禁止降级” idea (once upgraded to heavy channel, don’t bounce back for the same goal)

2) **More explicit channel selection table**
Upstream distinguishes:
- search vs fetch
- "正文抽取" (Jina/Readability) vs raw HTML fetch

Even though OpenClaw doesn’t use Jina by default, the *concept* maps well:
- `web_fetch` = raw HTML
- `browser` = rendered/interactive

3) **First-run onboarding script (conceptual)**
Upstream has a very clear first-run onboarding checklist.
We can replicate *the messaging* (what users should expect), without adopting their dependency install scripts.

## What upstream has that we intentionally DO NOT adopt

- **agent-browser CDP scripts** and any port/PID management.
  OpenClaw must use the `browser` tool and must not kill system Chrome.

- **Cookie/profile persistence tooling**.
  OpenClaw version must not read/write user cookies/credentials files.

- **Jina as a hard dependency**.
  OpenClaw has `web_fetch` and `browser`; if we later add a text-extraction middle-layer, it should be optional and still respect OpenClaw’s constraints.

## Iteration plan (keep openclaw-web-access strictly better)

- Add a "first-run" section in README:
  - what to expect
  - how to attach Chrome Relay when needed
  - common failure modes (SPA, 403, login wall)

- Expand channel-selection rules:
  - when to prefer `web_fetch` for meta/JSON-LD fields
  - when to go straight to `browser` (SPA, login, lazy-load)

- Keep hard safety constraints:
  - MUST NOT kill Chrome
  - MUST NOT touch cookie files

## How to review upstream changes

Run:
```bash
bash scripts/sync_upstream.sh

git diff -- references/upstream/eze-skills_web-access_SKILL.latest.md
```

Then cherry-pick portable ideas into:
- `openclaw-web-access/SKILL.md`
- `README.md`

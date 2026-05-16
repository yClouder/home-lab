---
description: Roll up the last 2^k entries from log.md into a fold page in folds/.
---

Read the `fold` skill at `~/.claude/skills/fold/SKILL.md` and run the log-fold workflow.

Usage:
- `/fold` — propose a k based on current `log.md` size, ask the user to confirm
- `/fold k=3` — fold the oldest 8 entries
- `/fold k=4` — fold the oldest 16 entries

Filename is the idempotency token: `fold-k{n}-from-{from-date}-to-{to-date}-n{count}.md`. If it exists, the skill is a no-op (re-folding requires explicit `--force`). Extractive summarization only — no invention. Always leaves the most recent ~16 entries in `log.md`.

---
description: Ingest an external source (URL or local file) into the Obsidian wiki as a sources/<slug>.md page.
---

Read the `ingest` skill at `~/.claude/skills/ingest/SKILL.md` and run the ingest workflow.

Usage:
- `/ingest <url>` — fetch via Defuddle, summarize into `sources/<slug>.md`
- `/ingest <path>` — read a local file or `.raw/` entry, summarize
- `/ingest` (no arg) — prompt the user for the source

The skill saves a cleaned copy to `.raw/` for provenance, then creates the summary page in `sources/` with full frontmatter (including `machine:`), updates the active client/project page, refreshes this machine's hot cache, and prepends to `log.md`.

---
name: start
description: >
  Brief Claude on where work was left off. Reads the per-machine hot cache, other
  machines' hot caches directly, and the most-recent session for the active client
  or project. Use at the start of a session, especially after switching machines.
  Triggers on: "/start", "where was I", "pick up where I left off", "what was I
  doing", "resume".
allowed-tools: Read Glob Grep Bash
---

# start: Cross-machine session handoff

Read the vault state and present a tight brief so the user (and you) can resume work.

---

## Workflow

### 1. Detect machine + vault path

Run `hostname -s` → scan `machines/*.md` frontmatter for a matching `hostname:`
value → use that file's basename as the machine label.

Read the `vault_path:` field from that machine page. All subsequent paths are
relative to this vault root. If `vault_path:` is absent, fall back to
`~/Documents/Obsidian Vault/` on macOS only.

**If no machine page matches:** stop and tell the user —
*"No machine page found for this hostname. Run `/save` first to create one, or
add `machines/<label>.md` with `hostname:` and `vault_path:` fields manually."*
Do not continue with a bare hostname — subsequent steps depend on the machine page.

### 2. Read this machine's hot cache

Read `meta/hot - <machine>.md`. Capture: active clients/projects, currently
working on, recent sessions, open threads, cross-machine notes.

### 3. Check other machines for more recent work

`meta/hot.md` is a Dataview-only file — do not read it for data.

Instead: glob `meta/hot - *.md`, skip this machine's own file, read each
remaining one. Compare `updated:` frontmatter timestamps. If another machine's
cache is more recent than this machine's, surface it:

> "Last work was on `<other-machine>` (`<date>`). This machine's hot may be
> stale — reading that machine's context too."

If the other machine's context is more recent, use it alongside this machine's
hot cache to build the brief.

### 4. Identify the active client / project

From the hot caches. When multiple active clients are listed, pick the one
with the most recent session date for the brief's primary focus. List the
others briefly under a "Also active:" line in the brief. Ask the user only if
the hot cache is completely empty.

### 5. Read the most-recent session

Determine the sessions path based on the active project:
- **Client work**: `Projects/Work/<Client>/Sessions/`
- **Personal project** (e.g. Homelab): `Projects/<Project>/Sessions/`

Glob `<sessions-path>/*.md`, sort the results lexicographically, pick the last
entry — date-prefixed filenames (`YYYY-MM-DD - <topic>.md`) sort in date order.
Read its `## Next session should` and `## Blockers / open threads` sections.

### 6. Read the client / project page

- Client work: `Projects/Work/<Client>/_index.md`
- Personal project: `Projects/<Project>/_index.md`

Also read `Projects/Work/<Client>/Plans/<Project>.md` if it exists. Capture
status, open questions, and key file paths.

### 7. Read the machine page

Read `machines/<machine>.md` for local repo paths and environment quirks
relevant to the active client/project.

### 8. Brief the user

```
## You're on: <machine>
## Active: <Client or Project> / <sub-project if any>
## Also active: <other clients, one line each>   ← omit if only one
## Last session (<machine it ran on>): <YYYY-MM-DD> — <topic>
## Where you left off
- <bullets from "Next session should">
- <bullets from "Blockers">
## Open threads
- <from hot cache Open Threads>
## Local paths on this machine
- <repo>: <path>
## Quirks to remember
- <from machine page + client conventions>
```

The brief must be scannable in 10 seconds. Short bullets, ISO dates, repo
paths. Quote the bits the user actually needs — don't paraphrase the session log.

### 9. Wait

Deliver the brief and stop. Don't act on it — wait for the user's first directive.

---

## Edge cases

- **No hot cache for this machine yet.** Note it, glob all other `meta/hot - *.md`
  for context, then offer to bootstrap one from the most recent global session.
- **Sessions folder empty or missing.** Note it in the brief; omit the last-session
  section rather than erroring.
- **Plans/ folder doesn't exist for the active client.** Skip silently.
- **LiveSync conflict markers (`<<<<<<`) in any hot cache.** Surface immediately and
  ask the user to resolve before continuing.

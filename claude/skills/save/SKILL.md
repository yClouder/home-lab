---
name: save
description: >
  File the current conversation into the Obsidian wiki. Determines note type
  (session / decision / source / scratchpad), creates the page in the correct
  folder with full frontmatter, updates the per-machine hot cache, and prepends
  an entry to log.md. When the conversation worked on a specific ticket or named
  work stream, also creates or updates Ticket and Task pages in the correct
  subfolders. Triggers on: "/save", "save this", "file this", "save to wiki",
  "save this session", "keep this".
allowed-tools: Read Write Edit Glob Grep Bash
---

# save: File the current conversation

Multi-client, multi-machine operational vault. Per-client content lives under
`Projects/Work/<Client>/<DocType>/`. Personal projects (Homelab, etc.) live under
`Projects/<Project>/<DocType>/`. Cross-project folders (`machines/`, `meta/`,
`sources/`, `folds/`) sit at vault root. See vault-root `CLAUDE.md` for the full
structure.

A single save can produce up to three artifacts: a **Ticket page** (static
reference), a **Task page** (persistent working log), and a **Session note**
(substantive, but links to task pages rather than duplicating them).

---

## Note type decision

| Type | Folder | Use when |
|------|--------|---------|
| session | `<project-path>/Sessions/` | The conversation was a work session (default) |
| decision | `<project-path>/Decisions/` | An explicit architectural or process decision was made |
| source | `sources/` | The conversation summarizes external material |
| scratchpad | `meta/` | Throwaway notes that don't fit elsewhere |

Honor an explicit type argument (e.g. `/save decision <name>`). Otherwise infer
from content; ask once if unclear.

---

## Naming

The project name is implicit in the folder — never in the filename.

**Client work** (`Projects/Work/<Client>/`):

| Artifact | Path |
|----------|------|
| Session | `Projects/Work/<Client>/Sessions/YYYY-MM-DD - <topic>.md` |
| Decision | `Projects/Work/<Client>/Decisions/YYYY-MM-DD - <summary>.md` |
| Task (with ticket ID) | `Projects/Work/<Client>/Tasks/<TICKET-ID> - <slug>.md` |
| Task (no ticket ID) | `Projects/Work/<Client>/Tasks/<slug>.md` |
| Ticket | `Projects/Work/<Client>/Tickets/<TICKET-ID> - <slug>.md` |

**Personal projects** (`Projects/<Project>/` — e.g. Homelab):

| Artifact | Path |
|----------|------|
| Session | `Projects/<Project>/Sessions/YYYY-MM-DD - <topic>.md` |
| Decision | `Projects/<Project>/Decisions/YYYY-MM-DD - <summary>.md` |
| Task | `Projects/<Project>/Tasks/<slug>.md` |

**Cross-project:**

| Artifact | Path |
|----------|------|
| Source | `sources/<slug>.md` |
| Scratchpad | `meta/YYYY-MM-DD - <topic>.md` |

**Routing rule**: use `Projects/Work/<Client>/` for paid client work. Use
`Projects/<Project>/` directly for personal projects not under Work/. The hot
cache indicates which applies. When in doubt, ask.

If the user provided a name in `/save <name>`, use it as the topic. If a file
with the same name already exists, update it rather than creating a duplicate.

---

## Machine identification and vault path

1. Run `hostname -s` → scan `machines/*.md` frontmatter for a matching
   `hostname:` value → use that file's basename as the machine label.
2. Read the `vault_path:` frontmatter field from that machine page. This is the
   absolute path to the vault root on this machine.
3. If `vault_path:` is absent, fall back to `~/Documents/Obsidian Vault/` on
   macOS. On Windows there is no safe default — stop and tell the user:
   *"No vault_path found in machines/<label>.md. Add a vault_path: field with
   the absolute path to your vault before saving."*
4. Verify the resolved vault path exists (`ls <vault_path>` or equivalent).
   If it doesn't exist, stop and report the bad path rather than writing files
   to the wrong location.
5. If no machine page matches, ask once for a short label and create the page
   from `Templates/claude-machine.md`, including `vault_path:`.

All subsequent paths in this skill are relative to the resolved vault root.

`machine:` frontmatter is required on sessions, decisions, and sources.

---

## Save workflow

Run steps 1–3 first to establish context, then create all artifacts.

### 1. Detect machine + client

Resolve machine label and vault path (see above). Read
`meta/hot - <machine>.md` → active client or project. Ask if ambiguous.

### 2. Scan for work items

Scan the conversation for any specific, named piece of work:

- **Jira ticket IDs** — scan for UPPERCASE-hyphen-number patterns (e.g.
  `DNA-123`, `DSUP-487`). Treat as a ticket only if the pattern is used as a
  work-item noun in context (worked on, fixed, investigating, opened). Skip
  patterns used as type codes, field values, version numbers, or CLI flags
  (e.g. `COMP-5` as a COBOL packed-decimal type is not a ticket).
- **GitHub PRs** — `PR #1234`, `pull request #1234`
- **Named work streams** (clients without Jira, e.g. G1, Optum) — a named
  feature, fix, or initiative the conversation centered on

A work item warrants a Task page. A Ticket page is warranted only for
Jira-tracked work where the conversation contains enough detail to write both
a description and acceptance criteria (at least one substantive sentence each).

**When no work item is clearly identifiable**, ask once:
> "What work item is this for? Is it a new task or an existing one?"

If the user names a ticket ID, use it. If they name a work stream, derive a
slug. **If the user says there is no work item** (research session, quick
exploration, admin task), skip ticket and task page creation entirely and
proceed directly to step 4 (session note).

### 3. Create / update work item pages

#### Ticket page — `Tickets/<TICKET-ID> - <slug>.md`
*Only for Jira-tracked clients, only when you can write at least one
substantive sentence for both description and acceptance criteria.*

- **If new**: create from `Templates/ticket.md`. Fill in description,
  acceptance criteria, reporter/assignee if known. Link from session note;
  treat as mostly static going forward.
- **If exists**: skip — just link from session note.

#### Task page — `Tasks/<id-or-slug>.md`
*For every substantive work item, Jira or not.*

- **If new**: create from `Templates/task.md`. Fill in:
  - **Goal** — what does done look like for this ticket/stream
  - **Context** — why the work exists, relevant background, constraints
  - **Plan** — concrete next steps as checkboxes
  - **Log** — first dated entry (`### YYYY-MM-DD`) with what was done this
    session
  - **Open questions** — anything unresolved
  - **Links** — ticket key, PRs, related sessions

- **If exists**: read the file and update in place:
  - **Plan** — tick completed items (best-effort: tick what is clearly done
    from this session; leave unticked when uncertain — the log entry is
    always required regardless), add newly discovered steps
  - **Log** — prepend a new `### YYYY-MM-DD` section with what happened
    this session
  - **Open questions** — resolve answered ones (strikethrough), add new ones
  - **Links** — add any new PRs or sessions

### 4. Create session note — `Sessions/YYYY-MM-DD - <topic>.md`

Use `Templates/claude-session.md`. The H1 title must match the filename
exactly: `# YYYY-MM-DD - <topic>`. Keep substance — capture what was
accomplished, key findings, and what to do next — but link to task pages
rather than duplicating their content. A sentence + `[[task page]]` link beats
repeating a paragraph that already lives there.

Structure:
- **Context**: state at the start of this session (1–3 lines)
- **What I did**: the session's work; reference task pages with wikilinks
- **Key findings / decisions**: non-obvious things learned or decided this
  session
- **Files touched** + commands of note
- **Next session should**: concrete actionable checklist
- **Links**: task pages updated, ticket pages, machine, related sessions

### 5. Update hot cache — `meta/hot - <machine>.md`

Before writing: **re-read each task page created or updated this session** to
get their current open questions. Do not rely on what was in context earlier in
this run — task pages may have been written earlier in the same session and
their open-question state should be taken from the file, not memory.

Overwrite (never append). Refresh:
- `Currently Working On` — active work items with one-line status each,
  including newly updated tasks
- `Recent Sessions` — prepend this session + any task pages created or updated
- `Open Threads` — carry forward unresolved open questions from all task pages
  touched (sourced from the files you just re-read)
- `updated:` — ISO timestamp

Never write to another machine's hot cache.

### 6. Prepend to `log.md`

```
## [YYYY-MM-DDTHH:MM <machine>] save | <Session Note Title>

- Type: session (+ task: <Task Page Title> if created/updated)
- Location: <relative path to session note from vault root>
- Client: [[<project path>/_index|<Project>]]
- From: <one-line context>
```

---

## Writing style

- Declarative present tense. Write the knowledge, not the conversation
  narrative.
- Future-you on a different machine has zero context — write as if handing off
  cold.
- Wikilink every client, project, ticket, task, machine, and session reference.
- Decision pages must capture: decision, context, options considered (pros/cons),
  why this won, trade-offs, revisit triggers.

---

## What to save vs. skip

**Save:** non-obvious insights, decisions with rationale, work in progress on
named tickets, anything needed to pick up the thread on another machine.

**Skip:** mechanical Q&A, setup steps already in CLAUDE.md or machine pages,
anything already in the wiki — update the existing page instead.

---

## Multi-machine safety

- Hot caches are exclusively owned — read others, write only your own.
- `_index.md` rosters are Dataview-driven — never add to them manually.
- `log.md` is the only commonly-written shared file. Always prepend with ISO
  timestamp + machine label.

---
name: save
description: >
  File the current conversation into the Obsidian wiki at ~/Documents/Obsidian Vault/.
  Determines note type (session / decision / source / scratchpad), creates the page in
  the correct folder with full frontmatter, updates the per-machine hot cache, and
  prepends an entry to log.md. When the conversation worked on a specific ticket or
  named work stream, also creates or updates Ticket and Task pages in the correct
  client subfolders. Triggers on: "/save", "save this", "file this", "save to wiki",
  "save this session", "keep this".
allowed-tools: Read Write Edit Glob Grep Bash
---

# save: File the current conversation

Multi-client, multi-machine operational vault at `~/Documents/Obsidian Vault/`. Per-client content lives under `Projects/Work/<Client>/<DocType>/`. Cross-client folders (`machines/`, `meta/`, `sources/`, `folds/`) sit at vault root. See vault-root `CLAUDE.md` for the full structure.

A single save can produce up to three artifacts: a **Ticket page** (static reference), a **Task page** (persistent working log), and a **Session note** (substantive, but links to task pages rather than duplicating them).

---

## Note type decision

| Type | Folder | Use when |
|------|--------|---------|
| session | `Projects/Work/<Client>/Sessions/` | The conversation was a work session (default) |
| decision | `Projects/Work/<Client>/Decisions/` | An explicit architectural or process decision was made |
| source | `sources/` | The conversation summarizes external material |
| scratchpad | `meta/` | Throwaway notes that don't fit elsewhere |

Honor an explicit type argument (e.g. `/save decision <name>`). Otherwise infer from content; ask once if unclear.

---

## Naming

Client name is implicit in the folder — never in the filename.

| Artifact | Path |
|----------|------|
| Session | `Projects/Work/<Client>/Sessions/YYYY-MM-DD - <topic>.md` |
| Decision | `Projects/Work/<Client>/Decisions/YYYY-MM-DD - <summary>.md` |
| Task (with ticket ID) | `Projects/Work/<Client>/Tasks/<TICKET-ID> - <slug>.md` |
| Task (no ticket ID) | `Projects/Work/<Client>/Tasks/<slug>.md` |
| Ticket | `Projects/Work/<Client>/Tickets/<TICKET-ID> - <slug>.md` |
| Source | `sources/<slug>.md` |
| Scratchpad | `meta/YYYY-MM-DD - <topic>.md` |

If the user provided a name in `/save <name>`, use it as the topic. If a file with the same name already exists, update it rather than creating a duplicate.

---

## Machine identification

Run `hostname -s` → scan `machines/*.md` frontmatter for a matching `hostname:` value → use that file's basename as the machine label. If no match, ask once for a short label and create the page from `Templates/claude-machine.md`.

`machine:` frontmatter is required on sessions, decisions, and sources.

---

## Save workflow

Run steps 1–3 first to establish context, then create all artifacts.

### 1. Detect machine + client
`hostname -s` → machine label. Read `meta/hot - <machine>.md` → active client. Ask if ambiguous.

### 2. Scan for work items

Look for any specific, named piece of work the conversation centered on:

- **Jira ticket IDs**: patterns like `DNA-123`, `DSUP-487`. Use judgment — `COMP-5` as a COBOL data type is not a ticket; a ticket is something treated as a work item (opened, worked on, mentioned by key as a unit of work).
- **GitHub PRs**: `PR #1234`, `pull request #1234`
- **Named work streams** (clients without Jira, e.g. G1, Optum): a named feature, fix, or initiative the conversation centered on

A work item warrants a Task page. A Ticket page is only warranted when the conversation contains enough to fill in description + acceptance criteria — a passing mention of a ticket key doesn't qualify.

**When no work item is clearly identifiable from the conversation**, ask once before creating any task page:
> "What work item is this for? Is it a new task or an existing one?"

If the user names a ticket ID, use that. If they name a work stream (no ticket ID), use a slug derived from their answer. Don't guess — wait for the answer before proceeding.

### 3. Create / update work item pages

#### Ticket page — `Tickets/<TICKET-ID> - <slug>.md`
*Only for Jira-tracked clients when the conversation has sufficient detail.*

- **If new**: create from `Templates/ticket.md`. Fill in description, acceptance criteria, reporter/assignee if known. Link from session note; treat as mostly static going forward.
- **If exists**: skip — just link from session note.

#### Task page — `Tasks/<id-or-slug>.md`
*For every substantive work item, Jira or not.*

- **If new**: create from `Templates/task.md`. Fill in:
  - **Goal** — what does done look like for this ticket/stream
  - **Context** — why the work exists, relevant background, constraints
  - **Plan** — concrete next steps as checkboxes
  - **Log** — first dated entry (`### YYYY-MM-DD`) with what was done this session
  - **Open questions** — anything unresolved
  - **Links** — ticket key, PRs, related sessions

- **If exists**: read the file and update in place:
  - **Plan** — tick completed items, add newly discovered steps
  - **Log** — prepend a new `### YYYY-MM-DD` section with what happened this session
  - **Open questions** — resolve answered ones, add new ones
  - **Links** — add any new PRs or sessions

### 4. Create session note — `Sessions/YYYY-MM-DD - <topic>.md`

Use `Templates/claude-session.md`. Keep substance — capture what was accomplished, key findings, and what to do next — but link to task pages rather than duplicating their content. A sentence + `[[task page]]` link beats repeating a paragraph that already lives there.

Structure:
- **Context**: state at the start of this session (1–3 lines)
- **What I did**: the session's work; reference task pages with wikilinks
- **Key findings / decisions**: non-obvious things learned or decided this session
- **Files touched** + commands of note
- **Next session should**: concrete actionable checklist
- **Links**: task pages updated, ticket pages, machine, related sessions

### 5. Update hot cache — `meta/hot - <machine>.md`

Overwrite (never append). Refresh:
- `Currently Working On` — active work items with one-line status each, including newly updated tasks
- `Recent Sessions` — prepend this session + any task pages created or updated
- `Open Threads` — carry forward unresolved open questions from all task pages touched
- `updated:` — ISO timestamp

Never write to another machine's hot cache.

### 6. Prepend to `log.md`

```
## [YYYY-MM-DDTHH:MM <machine>] save | <Session Note Title>

- Type: session (+ task: <Task Page Title> if created/updated)
- Location: Projects/Work/<Client>/Sessions/<filename>.md
- Client: [[Projects/Work/<Client>/_index|<Client>]]
- From: <one-line context>
```

---

## Writing style

- Declarative present tense. Write the knowledge, not the conversation narrative.
- Future-you on a different machine has zero context — write as if handing off cold.
- Wikilink every client, project, ticket, task, machine, and session reference.
- Decision pages must capture: decision, context, options considered (pros/cons), why this won, trade-offs, revisit triggers.

---

## What to save vs. skip

**Save:** non-obvious insights, decisions with rationale, work in progress on named tickets, anything needed to pick up the thread on another machine.

**Skip:** mechanical Q&A, setup steps already in CLAUDE.md or machine pages, anything already in the wiki — update the existing page instead.

---

## Multi-machine safety

- Hot caches are exclusively owned — read others, write only your own.
- `_index.md` rosters are Dataview-driven — never add to them manually.
- `log.md` is the only commonly-written shared file. Always prepend with ISO timestamp + machine label.

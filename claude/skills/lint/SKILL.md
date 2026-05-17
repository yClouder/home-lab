---
name: lint
description: >
  Health-check the Obsidian wiki. Finds orphan pages, dead wikilinks, frontmatter
  gaps, stale tasks, and conflict markers from LiveSync. Writes a report to
  meta/lint-YYYY-MM-DD.md. Triggers on: "/lint", "lint the wiki", "wiki health
  check", "clean up wiki", "find orphans", "wiki audit".
allowed-tools: Read Write Edit Glob Grep Bash
---

# lint: Wiki health check

Run after every ~10-15 saves, or weekly, or when something feels off.

Vault path is read from the active machine page (`vault_path:` frontmatter field).
Fall back to `~/Documents/Obsidian Vault/` on macOS only if the field is absent.

Operational layout:
- `Projects/Work/<Client>/{Docs,Plans,Sessions,Decisions,Notes,Tasks,Tickets,People}/` — paid client work.
- `Projects/<Project>/{Docs,Notes,Plans,Tasks,Sessions,Decisions}/` — personal projects (e.g. Homelab).
- Cross-project folders at vault root: `machines/`, `meta/`, `sources/`, `folds/`.
- Templates: `Templates/claude-<type>.md`.
- Vault-level files: `index.md`, `log.md`, `overview.md`, `CLAUDE.md`.
- Pre-existing top-level folders ignored by lint: `Attachments/`, `Journal/`.

---

## Workflow

1. **Detect machine.** `hostname -s` → scan `machines/*.md` for matching `hostname:` → machine label + vault path.
2. **Run all checks below**, collecting findings.
3. **Write report** to `meta/lint-YYYY-MM-DD.md` (or `lint-YYYY-MM-DD-<machine>.md` if a same-day report from another machine already exists).
4. **Summarize to the user**, top 5 issues by severity.
5. **Ask before auto-fixing** anything. Default is read-only.
6. **Prepend to `log.md`**:
   ```
   ## [YYYY-MM-DDTHH:MM <machine>] lint | <findings count>
   - Report: meta/lint-YYYY-MM-DD.md
   - Top issues: <one-line summary>
   ```

---

## Checks

### 1. Orphan pages
A page is an orphan if no other wiki page links to it AND it's not a hub
(`_index.md`, `index.md`, `log.md`, `overview.md`, `CLAUDE.md`, machine page,
hot cache, fold page).

```bash
grep -rh "\[\[" <vault_path> --include="*.md" -o | sort -u
```

From the grep output:
1. Extract each `[[Target]]` or `[[Target|Alias]]` — keep only the part before `|`, strip `[[` and `]]`.
2. Skip any target whose path falls under the exclusion folders: `Attachments/`, `Journal/`, `Templates/`.
3. Build the linked-to set (all extracted targets).
4. Build the full file set: glob `<vault_path>/**/*.md`, exclude `Attachments/`, `Journal/`, `Templates/`.
5. Any file in the full set whose basename is not in the linked-to set and is not a hub page is an orphan.

### 2. Dead wikilinks
For each `[[X]]` or `[[X|Y]]` across all pages, check that a file named `X.md`
exists anywhere in the vault (Obsidian resolves by basename). Use the extracted
link set from check 1 — no need to re-parse all files.

### 3. Frontmatter gaps
Every page should have at least: `type`, `created`, `updated`, `tags`.
Type-specific required fields:
- `session`: `client`, `project`, `machine`, `date`
- `decision`: `client`, `status`, `date`
- `source`: `source_url` (or `source_path`), `ingested`, `machine`
- `client`: `status`
- `project`: `client`, `status`
- `machine`: `hostname`, `vault_path`, `status`
- `hot`: `machine`, `updated`

Missing required fields → finding.

### 4. Stale tasks
Tasks (`- [ ] ...`) older than 60 days. Proxy: file `updated` frontmatter is older
than 60 days AND the page contains unchecked tasks.

Note: this proxy may miss stale tasks in recently-touched files — flag as
best-effort.

### 5. LiveSync conflict markers
Grep all wiki pages for `<<<<<<<` or `>>>>>>>` or `=======`. Any matches are
unresolved sync conflicts — surface immediately with file paths.

### 6. Hot cache freshness
For each `meta/hot - <machine>.md`, check the `updated:` frontmatter. Flag any
older than 14 days.

### 7. Empty pages
Files with only frontmatter and no body content. Often abandoned scaffolds.

### 8. Inconsistent client/project references
Sessions or decisions whose `client:` frontmatter doesn't match any known project
root. Valid project roots are all `_index.md` files found one level deep under
`Projects/` — covering both `Projects/Work/<Client>/` and `Projects/<Project>/`
(e.g. Homelab). A client value that doesn't match any of these is flagged.

### 9. Duplicate filenames across folders
Obsidian resolves wikilinks by basename, so two pages with the same filename in
different folders create ambiguity.

---

## Report format

```markdown
---
type: lint-report
machine: <machine>
created: YYYY-MM-DD
tags: [meta, lint]
---

# Lint report — YYYY-MM-DD (<machine>)

## Summary
- N pages checked
- M findings (X critical, Y warning, Z info)

## Critical
- LiveSync conflict markers: <list>
- Missing required frontmatter: <list>

## Warning
- Dead wikilinks: <list with file + target>
- Inconsistent client refs: <list>

## Info
- Orphan pages: <list>
- Stale tasks: <list>
- Empty pages: <list>
- Stale hot caches: <list>
- Duplicate filenames: <list>

## Suggested fixes
- _(optional — Claude proposes specific edits, but does not apply them without user confirmation)_
```

---

## Fix mode

If the user says "fix it" or "auto-fix the easy ones", apply ONLY these (and
report what was changed):

- Add missing `updated:` to today's date if `created:` exists.
- Resolve trivial dead wikilinks where there's a single fuzzy match (e.g.
  `[[Golden 1 g1-databricks]]` → `[[Golden 1 - g1-databricks]]`) — ASK FIRST
  per fix.
- Delete confirmed-empty pages — ASK FIRST.

Never touch hot caches owned by other machines. Never modify `.raw/`. Never touch
session/decision page bodies — only frontmatter.

---
name: lint
description: >
  Health-check the Obsidian wiki at ~/Documents/Obsidian Vault/. Finds orphan pages,
  dead wikilinks, frontmatter gaps, stale tasks, and conflict markers from LiveSync.
  Writes a report to meta/lint-YYYY-MM-DD.md. Triggers on: "/lint", "lint the wiki",
  "wiki health check", "clean up wiki", "find orphans", "wiki audit".
allowed-tools: Read Write Edit Glob Grep Bash
---

# lint: Wiki health check

Run after every ~10-15 saves, or weekly, or when something feels off.

Vault: `~/Documents/Obsidian Vault/`. Operational layout:
- Active engagements under `Projects/`:
  - `Projects/Work/<Client>/{Docs,Plans,Sessions,Decisions,Notes,Tasks,Tickets,People}/` — paid client work.
  - `Projects/Homelab/{Docs,Notes,Plans,Tasks}/` — personal homelab project (single-owner; no client-style subfolders).
- Cross-project operational folders at vault root: `machines/`, `meta/`, `sources/`, `folds/`.
- Skill scaffolds at `Templates/claude-<type>.md`.
- Vault-level files: `index.md`, `log.md`, `overview.md`, `CLAUDE.md`.
- Pre-existing top-level folders ignored by lint: `Attachments/`, `Journal/`.

---

## Workflow

1. **Detect machine.** `hostname -s` → label.
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
A page is an orphan if no other wiki page links to it AND it's not a hub (`_index.md`, `index.md`, `log.md`, `overview.md`, `CLAUDE.md`, machine page, hot cache, fold page).

```bash
grep -rh "\[\[" . --include="*.md" -o | sort -u
```
Compare against `Glob("Projects/**/*.md")` plus the vault-root operational folders (`machines/`, `meta/`, `sources/`, `folds/`). Anything in the file list missing from the link list and not on the exclusion list is an orphan. **Skip** the pre-existing top-level folders that aren't part of the operational vault: `Attachments/`, `Journal/`, and the templates dir `Templates/` (templates are not content pages).

### 2. Dead wikilinks
Wikilinks pointing to non-existent files. For each `[[X]]` (or `[[X|Y]]`) in any wiki page, check that a file named `X.md` exists somewhere in the vault. Note: Obsidian resolves by basename, not path.

### 3. Frontmatter gaps
Every page should have at least: `type`, `created`, `updated`, `tags`. Type-specific required fields:
- `session`: `client`, `project`, `machine`, `date`
- `decision`: `client`, `status`, `date`
- `source`: `source_url` (or `source_path`), `ingested`, `machine`
- `client`: `status`
- `project`: `client`, `status`
- `machine`: `hostname`, `status`
- `hot`: `machine`, `updated`

Missing required fields → finding.

### 4. Stale tasks
Tasks (`- [ ] ...`) older than 60 days that have no recent updates in the parent page. Computed as: file `updated` frontmatter is older than 60 days AND the page contains unchecked tasks.

### 5. LiveSync conflict markers
Grep all wiki pages for `<<<<<<<` or `>>>>>>>` or `=======`. Any matches are unresolved sync conflicts — surface immediately with file paths.

### 6. Hot cache freshness
For each `meta/hot - <machine>.md`, check the `updated:` frontmatter. Flag any older than 14 days (the machine likely hasn't been used in a while; harmless but worth noting).

### 7. Empty pages
Files with only frontmatter and no body content. Often abandoned scaffolds.

### 8. Inconsistent client/project references
Sessions or decisions whose `client:` frontmatter doesn't match any `Projects/Work/*/_index.md` file. Same for `project:`.

### 9. Duplicate filenames across folders
Obsidian resolves wikilinks by basename, so two pages with the same filename in different folders are an ambiguity hazard.

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

If the user says "fix it" or "auto-fix the easy ones", apply ONLY these (and report what was changed):

- Add missing `updated:` to today's date if `created:` exists.
- Resolve trivial dead wikilinks where there's a single fuzzy match (e.g. `[[Golden 1 g1-databricks]]` → `[[Golden 1 - g1-databricks]]`) — ASK FIRST per fix.
- Delete confirmed-empty pages — ASK FIRST.

Never touch hot caches owned by other machines. Never modify `.raw/`. Never touch session/decision page bodies — only frontmatter.

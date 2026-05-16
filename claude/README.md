# claude/ — Claude Code config, cross-machine

Canonical copy of `~/.claude/skills/`, `~/.claude/commands/`, `~/.claude/CLAUDE.md`, and `~/.claude/settings.json`. Each machine symlinks these paths into its `~/.claude/`, so the repo is the single source of truth — `git push` from any machine, `git pull` on the others, restart Claude Code.

## Layout

```
claude/
├── README.md         # this file
├── bootstrap.sh      # idempotent symlink installer
├── CLAUDE.md         # user-global instructions for Claude Code
├── settings.json     # plugin enablement + marketplace registrations
├── skills/           # homegrown skills (save, start, ingest, lint, fold, decision)
│   └── <name>/SKILL.md
└── commands/         # slash command wrappers
    └── <name>.md
```

## Setup on a new machine

```bash
# 1. Clone the home-lab repo (or pull if already present).
git clone git@github.com:yClouder/home-lab.git ~/dev/home-lab
# or:  cd ~/dev/home-lab && git pull

# 2. Symlink the four items into ~/.claude/.
~/dev/home-lab/claude/bootstrap.sh
```

`bootstrap.sh` is idempotent — re-running is safe. If `~/.claude/skills` (etc.) already exists as a regular file/folder, it moves the existing content into `~/.claude/.pre-bootstrap-<timestamp>/` before linking.

## Day-to-day editing

Edit skills, commands, or `CLAUDE.md` directly in `~/.claude/<path>` — the symlink writes through to the repo. Then:

```bash
cd ~/dev/home-lab
git add claude/
git commit -m "claude: <what changed>"
git push
```

On the other machine:

```bash
cd ~/dev/home-lab && git pull
# Restart Claude Code to pick up new skills/commands.
```

## What's in scope here

- **`CLAUDE.md`** — global instructions Claude Code reads on every session (user role, vault location, conventions).
- **`settings.json`** — `enabledPlugins`, `extraKnownMarketplaces`, `effortLevel`. Portable across machines.
- **`skills/<name>/SKILL.md`** — homegrown skills tailored to the Obsidian operational vault. See [`Vault Setup.md`](../../../Documents/Obsidian/Notes/Vault%20Setup.md) for the vault layout these skills target.
- **`commands/<name>.md`** — slash command wrappers (`/save`, `/start`, `/ingest`, `/lint`, `/fold`, `/decision`).

## What's NOT in scope (stays per-machine)

These should never be tracked here — they're machine-local state:

- `~/.claude/projects/` — per-project state and auto-memory; paths are machine-specific.
- `~/.claude/plugins/` — installed plugin cache.
- `~/.claude/sessions/`, `history.jsonl`, `backups/`, `file-history/`, `paste-cache/`, `cache/`, `debug/`, `session-env/`, `shell-snapshots/`, `tasks/`, `stats-cache.json`, `statsig/` — transient runtime state.
- `~/.claude/ide/`, `mcp-needs-auth-cache.json` — IDE/MCP integration state.

## Conflict policy

If you edit the same SKILL.md on two machines before pushing, you'll get a normal git merge conflict — resolve like any other text conflict. The skill files are short and rarely change, so this is unlikely in practice.

# Dotfiles Agent Guide

This repo is a public, sanitized macOS dotfiles bootstrap. Its goal is simple: clone to `~/.config`, run `./restore.sh`, and restore portable development config without secrets or runtime state.

## Critical Rules

- Never commit secrets, auth state, sessions, caches, telemetry, generated completions, or app runtime databases.
- Never reintroduce personal/client project metadata, private repo paths, personal emails, or `/Users/<name>` hardcoded paths.
- Keep this repo a small bootstrap, not a full installer framework.
- Do not touch sibling FZF worktrees unless the user explicitly asks; they may contain unfinished work.
- Do not force-push or rewrite history unless the user explicitly authorizes that exact operation.

## Priorities

1. Public safety: no secrets or sensitive metadata.
2. Fresh-Mac restore correctness.
3. Simplicity and portability.
4. Small, reviewable changes.

## Structure

- `restore.sh` links portable config into `$HOME` and runs the curated package/bootstrap steps.
- `Brewfile` installs only base tools/apps needed by tracked config.
- `claude/` mirrors safe Claude Code config for `~/.claude`.
- `pi-agent/` mirrors safe Pi config for `~/.pi/agent`.
- `agents/skills/` mirrors shared `~/.agents/skills` for Pi and other agent harnesses.
- `opencode/` stores OpenCode/Gentle AI config under `~/.config/opencode`.
- `macos/defaults.sh` applies conservative, non-secret macOS developer preferences.

## Restore Contract

`restore.sh` should be idempotent enough for a new Mac and cautious on an existing Mac:

- Back up existing non-symlink targets before replacing them.
- Use symlinks for portable config instead of copying runtime state.
- Leave logins, OAuth tokens, SSH keys, app accounts, sessions, and trust decisions manual.
- Prefer `$HOME`, relative paths, or PATH-resolved commands over absolute machine paths.

## Forbidden Paths and Patterns

Keep these untracked unless the user explicitly asks for a private-only change:

- `github-copilot/`, `gh/hosts.yml`, `configstore/`, `.opencode/`
- `fish/fish_variables`, `fish/completions/`, `raycast/extensions/`, `nvim/lazy-lock.json`
- `claude/history.jsonl`, `claude/file-history/`, `claude/projects/`, `claude/telemetry/`, `claude/*cache*.json`
- `pi-agent/auth.json`, `pi-agent/sessions/`, `pi-agent/mcp-oauth/`, `pi-agent/npm/`, `pi-agent/trust.json`
- `agents/skills/**/.venv/`, `agents/skills/**/node_modules/`
- Any `.env`, token, private key, OAuth file, local database, socket, log, or generated package cache.

## Common Commands

```bash
bash -n restore.sh
bash -n macos/defaults.sh
python3 -m json.tool claude/settings.json >/dev/null
python3 -m json.tool pi-agent/settings.json >/dev/null
python3 -m json.tool pi-agent/mcp.json >/dev/null
brew bundle check --file Brewfile --verbose
```

Use `brew bundle check` only to verify dependencies; missing packages on the current machine are expected and should be reported, not auto-installed, unless the user asks.

## Review Checklist

Before reporting done:

- Run shell and JSON validation for touched restore/config files.
- Scan tracked and newly added files for secrets and absolute personal paths.
- Confirm `git status -sb` and name all remaining untracked/modified files.
- For public-facing changes, use a fresh `review-risk` pass before push or PR.

## Agent Behavior

- Treat vague requests as intake; clarify before broad rewrites.
- Keep generated technical artifacts in English unless the user explicitly requests another language.
- Prefer small slices that keep restore behavior demonstrable.
- If changing Claude, Pi, or shared skills, preserve only portable config and update `.gitignore` when new runtime paths appear.

#!/usr/bin/env bash
# Runs on the desktop (systemd user timer): copies the last two days of x2u
# Claude Code session transcripts to the routine host for the dailies skill, and
# prunes copies older than 4 days there. Agent-worktree sessions are skipped;
# their outcomes are already in the parent session.
set -euo pipefail
HOST="${DAILIES_SESSIONS_HOST:-lynx}"
SRC="$HOME/.claude/projects"
cd "$SRC"
find . -maxdepth 2 -name '*.jsonl' -path './-home-cbxm-src-x2u*' ! -path '*worktrees*' -mtime -2 -printf '%P\n' > "${TMPDIR:-/tmp}/dailies-sync-files"
rsync -a --files-from="${TMPDIR:-/tmp}/dailies-sync-files" . "$HOST:desktop-sessions/"
ssh "$HOST" 'find ~/desktop-sessions -name "*.jsonl" -mtime +4 -delete; find ~/desktop-sessions -mindepth 1 -type d -empty -delete; chmod -R go-rwx ~/desktop-sessions'

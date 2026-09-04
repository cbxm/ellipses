#!/usr/bin/env bash
# Prints the forge for the current repo: github | gitlab
# Precedence: $FORGE env → .claude/forge.json "forge" key → origin remote host.
set -euo pipefail
if [ -n "${FORGE:-}" ]; then echo "$FORGE"; exit 0; fi
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo .)
if [ -f "$ROOT/.claude/forge.json" ]; then
  f=$(jq -r '.forge // empty' "$ROOT/.claude/forge.json" 2>/dev/null || true)
  if [ -n "$f" ]; then echo "$f"; exit 0; fi
fi
if [ -n "${CI_PROJECT_PATH:-}" ]; then echo gitlab; exit 0; fi
if [ -n "${GITHUB_REPOSITORY:-}" ]; then echo github; exit 0; fi
url=$(git remote get-url origin 2>/dev/null || true)
case "$url" in
  *github.com*) echo github ;;
  *gitlab*)     echo gitlab ;;
  *) echo "forge: cannot determine forge from origin '$url'; set FORGE or .claude/forge.json" >&2; exit 1 ;;
esac

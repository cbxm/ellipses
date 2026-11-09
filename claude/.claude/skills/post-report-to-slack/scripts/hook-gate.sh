#!/usr/bin/env bash
# PreToolUse(Bash) hook: devlog gates on `glab mr create` and `glab mr merge`
# in x2u repos. Anything else exits here without starting node or glab.
input=$(cat)
[[ $input == *glab* && $input =~ mr[[:space:]]+(create|new|merge|accept) ]] || exit 0
exec node "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/hook-gate.mjs" <<<"$input"

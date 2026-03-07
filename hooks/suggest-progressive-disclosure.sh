#!/usr/bin/env bash
# PostToolUse hook: suggest /progressive-disclosure when a target document grows past threshold
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(printf '%s' "$INPUT" | jq -r '.tool_input.file_path // empty')

# Exit early if no file path
[ -z "$FILE_PATH" ] && exit 0

# Resolve plugin root for config file
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGETS_FILE="$PLUGIN_ROOT/config/targets.txt"

# Load target patterns (skip comments and blank lines)
if [ ! -f "$TARGETS_FILE" ]; then
  exit 0
fi

MATCHED=false
while IFS= read -r pattern || [ -n "$pattern" ]; do
  # Skip comments and blank lines
  [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
  [[ -z "${pattern// /}" ]] && continue

  # Match file path against glob pattern (case-insensitive basename matching)
  # shellcheck disable=SC2254
  case "$FILE_PATH" in
    $pattern) MATCHED=true; break ;;
  esac
done < "$TARGETS_FILE"

[ "$MATCHED" = "false" ] && exit 0

# File matched a target pattern — check if it exists and count lines
[ -f "$FILE_PATH" ] || exit 0
LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')

# Determine threshold based on path
# User-level (~/.claude/CLAUDE.md) = 100 lines, project-level = 200 lines
THRESHOLD=200
case "$FILE_PATH" in
  */.claude/CLAUDE.md) THRESHOLD=100 ;;
  "$HOME"/.claude/CLAUDE.md) THRESHOLD=100 ;;
esac

[ "$LINE_COUNT" -le "$THRESHOLD" ] && exit 0

# Skip if file already has progressive disclosure structure
if grep -qiE '(Information Recording Principles|Progressive Disclosure|## Reference Index|## Reference Trigger Index)' "$FILE_PATH" 2>/dev/null; then
  exit 0
fi

# Suggest optimization (exit 2 + stderr = fed back to Claude)
printf 'This file is now %d lines (threshold: %d). Consider running /progressive-disclosure to optimize it using three-tier lazy loading.' "$LINE_COUNT" "$THRESHOLD" >&2
exit 2

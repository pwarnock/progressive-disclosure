#!/usr/bin/env bash
# PostToolUse hook: suggest /progressive-disclosure when a target document grows past threshold
set -euo pipefail

INPUT=$(cat)

# Resolve plugin root for config file
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
TARGETS_FILE="$PLUGIN_ROOT/config/targets.txt"

# Load target patterns (skip comments and blank lines)
if [ ! -f "$TARGETS_FILE" ]; then
  exit 0
fi

CWD=$(printf '%s' "$INPUT" | jq -r '.cwd // empty' 2>/dev/null || true)

TMP_PATHS=$(mktemp)
TMP_SUGGESTIONS=$(mktemp)
trap 'rm -f "$TMP_PATHS" "$TMP_SUGGESTIONS"' EXIT

# Copilot PostToolUse payloads can arrive in one of two useful shapes:
# 1. tool_input/toolArgs is an object with a path field (edit/create tools)
# 2. tool_input is the raw apply_patch string, which needs file extraction
printf '%s' "$INPUT" | jq -r '
  [
    (if (.tool_input? | type) == "object" then (.tool_input.path // .tool_input.file_path // .tool_input.filePath // empty) else empty end),
    (if (.toolArgs? | type) == "object" then (.toolArgs.path // .toolArgs.file_path // .toolArgs.filePath // empty) else empty end),
    (.path // .file_path // .filePath // empty)
  ] | .[] | select(type == "string" and length > 0)
' 2>/dev/null > "$TMP_PATHS" || true

PATCH_TEXT=$(
  printf '%s' "$INPUT" | jq -r '
    if (.tool_input? | type) == "string" then .tool_input
    elif (.toolArgs? | type) == "string" then .toolArgs
    else empty
    end
  ' 2>/dev/null || true
)

if [ -n "$PATCH_TEXT" ]; then
  printf '%s\n' "$PATCH_TEXT" | sed -nE 's/^\*\*\* (Update|Add) File: (.+)$/\2/p' >> "$TMP_PATHS" || true
fi

[ -s "$TMP_PATHS" ] || exit 0

matches_target() {
  local absolute_path="$1"
  local relative_path="$2"
  local pattern

  while IFS= read -r pattern || [ -n "$pattern" ]; do
    [[ "$pattern" =~ ^[[:space:]]*# ]] && continue
    [[ -z "${pattern// /}" ]] && continue

    # shellcheck disable=SC2254
    case "$absolute_path" in
      $pattern) return 0 ;;
    esac

    # shellcheck disable=SC2254
    case "$relative_path" in
      $pattern) return 0 ;;
    esac
  done < "$TARGETS_FILE"

  return 1
}

while IFS= read -r RAW_PATH; do
  [ -n "$RAW_PATH" ] || continue

  FILE_PATH="$RAW_PATH"
  case "$FILE_PATH" in
    /*) ;;
    *) [ -n "$CWD" ] && FILE_PATH="$CWD/$FILE_PATH" ;;
  esac

  [ -f "$FILE_PATH" ] || continue

  RELATIVE_PATH="$FILE_PATH"
  if [ -n "$CWD" ]; then
    case "$FILE_PATH" in
      "$CWD"/*) RELATIVE_PATH="${FILE_PATH#"$CWD"/}" ;;
    esac
  fi

  matches_target "$FILE_PATH" "$RELATIVE_PATH" || continue

  LINE_COUNT=$(wc -l < "$FILE_PATH" | tr -d ' ')
  THRESHOLD=200
  case "$FILE_PATH" in
    "$HOME"/.claude/CLAUDE.md) THRESHOLD=100 ;;
  esac

  [ "$LINE_COUNT" -gt "$THRESHOLD" ] || continue

  if grep -qiE '(Information Recording Principles|Progressive Disclosure|## Reference Index|## Reference Trigger Index)' "$FILE_PATH" 2>/dev/null; then
    continue
  fi

  printf '%s (%s lines; threshold %s)\n' "$RELATIVE_PATH" "$LINE_COUNT" "$THRESHOLD" >> "$TMP_SUGGESTIONS"
done < <(sort -u "$TMP_PATHS")

[ -s "$TMP_SUGGESTIONS" ] || exit 0

MESSAGE='Consider running /progressive-disclosure for these files:'
while IFS= read -r suggestion; do
  MESSAGE="${MESSAGE}"$'\n'"- ${suggestion}"
done < "$TMP_SUGGESTIONS"

jq -Rn --arg msg "$MESSAGE" '{additionalContext: $msg}'

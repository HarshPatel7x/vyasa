#!/usr/bin/env bash
# PostToolUse hook — compute the EXACT delta a single Edit/Write/MultiEdit made,
# from the real before bytes (snapshotted by snapshot-before-edit.sh) vs the real
# after bytes on disk. Surfaces a compact user-facing summary; when a reported
# "success" left the file byte-identical, also injects a factual, neutral note
# into the model's context. See workitems/plans/diff-verification-hook.md.
#
# Contract: FAIL-OPEN. Any internal problem -> emit nothing, exit 0. Never blocks
# an edit. Output is hard-capped well under the 10,000-char hook limit.

# --- fail-open guards -------------------------------------------------------
command -v jq >/dev/null 2>&1 || exit 0

payload="$(cat)"
[ -n "$payload" ] || exit 0

session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)"
file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
tool_use_id="$(printf '%s' "$payload" | jq -r '.tool_use_id // empty' 2>/dev/null)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"

# These ids land in filesystem paths below. They are harness-generated in
# practice, but stdin is treated as untrusted, so whitelist them to a safe
# charset (no '/', no '.') to prevent path traversal / dir escape. Pre applies
# the identical transform, so sanitized ids still pair deterministically.
[ -n "$session_id" ]  && session_id="$(printf '%s' "$session_id"  | tr -c 'A-Za-z0-9_-' '_')"
[ -n "$tool_use_id" ] && tool_use_id="$(printf '%s' "$tool_use_id" | tr -c 'A-Za-z0-9_-' '_')"

[ -n "$file_path" ] || exit 0

# --- resolve path identically to the Pre hook -------------------------------
case "$file_path" in
  /*) abs="$file_path" ;;
  *)  abs="${cwd:-$PWD}/$file_path" ;;
esac
resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$abs" 2>/dev/null)"
[ -n "$resolved" ] || resolved="$abs"

path_hash="$(printf '%s' "$resolved" | shasum -a 256 2>/dev/null | cut -d' ' -f1)"
[ -n "$path_hash" ] || exit 0

dir="${TMPDIR:-/tmp}/claude-diff-verify/${session_id:-nosession}"

# recover the matching call id: tool_use_id when present, else pop the oldest
# entry off the per-path FIFO the Pre hook enqueued (drains in Pre order).
if [ -n "$tool_use_id" ]; then
  call_id="$tool_use_id"
else
  queue="$dir/${path_hash}.queue"
  call_id="$(head -1 "$queue" 2>/dev/null)"
  [ -n "$call_id" ] || exit 0
  # pop the consumed line; remove the queue file once empty
  tail -n +2 "$queue" 2>/dev/null > "${queue}.tmp" && mv "${queue}.tmp" "$queue" 2>/dev/null
  [ -s "$queue" ] || rm -f "$queue" 2>/dev/null
fi

key="${path_hash}.${call_id}"
snap="$dir/${key}.snap"
meta="$dir/${key}.meta"

# .meta is authoritative: no meta -> Pre never ran for this call -> stay silent.
[ -f "$meta" ] || exit 0

# --- parse the fixed-format sidecar -----------------------------------------
existed="$(sed -n 's/^existed=//p' "$meta" 2>/dev/null | head -1)"
skipped="$(sed -n 's/^skipped=//p' "$meta" 2>/dev/null | head -1)"

# display path relative to project root when possible. Resolve the base through
# realpath too, so a symlinked project dir (e.g. /tmp -> /private/tmp) still
# matches the realpath-resolved file path and the relative form is shown.
base="${CLAUDE_PROJECT_DIR:-${cwd:-$PWD}}"
base="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$base" 2>/dev/null || printf '%s' "$base")"
reldisplay="$resolved"
case "$resolved" in
  "$base"/*) reldisplay="${resolved#"$base"/}" ;;
esac

cleanup() { rm -f "$snap" "$meta" 2>/dev/null; }

emit() {
  # $1 = user-facing summary (systemMessage); $2 = optional model-context note
  local msg="$1" ctx="$2"
  if [ -n "$ctx" ]; then
    jq -n --arg m "$msg" --arg c "$ctx" \
      '{systemMessage:$m, hookSpecificOutput:{hookEventName:"PostToolUse", additionalContext:$c}}' 2>/dev/null
  else
    jq -n --arg m "$msg" '{systemMessage:$m}' 2>/dev/null
  fi
}

# --- oversize: Pre copied no bytes; report the skip, can't diff --------------
if [ "$skipped" = "oversize" ]; then
  emit "[edit-verify] ${reldisplay}  (skipped: file too large to verify)" ""
  cleanup
  exit 0
fi

[ -f "$snap" ] || { cleanup; exit 0; }

# --- compute the per-edit delta ---------------------------------------------
out="$(diff -u "$snap" "$resolved" 2>/dev/null || true)"   # diff exits 1 when differing — normal

# Strip diff's fixed two-line file header (--- snap / +++ file) structurally
# with tail -n +3, rather than by prefix-matching '^+++'/'^---'. Prefix matching
# wrongly drops *content* lines that themselves begin with '++'/'--' (e.g. diff
# snippets or markdown rules in the edited file). After the header, every line
# is a hunk marker (@@), context ( ), addition (+) or removal (-). The
# "\ No newline at end of file" marker is dropped so it neither shows nor counts.
delta="$(printf '%s\n' "$out" | tail -n +3 | grep -v '^\\ No newline')"
added="$(printf '%s\n' "$delta"   | grep -c '^+')"
removed="$(printf '%s\n' "$delta" | grep -c '^-')"
added="${added:-0}"; removed="${removed:-0}"

# status
if [ -z "$out" ]; then
  status="no change"
elif [ "$existed" = "no" ]; then
  status="NEW file"
else
  status="modified"
fi

header="[edit-verify] ${reldisplay}  +${added} -${removed} lines   (${status})"

if [ "$status" = "no change" ]; then
  # neutral, factual note injected into the model's context — not an accusation.
  note="edit-verify: ${reldisplay} is byte-identical to its pre-edit state; this edit changed nothing on disk."
  emit "${header}" "${note}"
  cleanup
  exit 0
fi

# diff body for display: reuse the header-stripped delta (hunks + context +
# changes), cap line COUNT at 25 and each line's WIDTH at 200, indent, then a
# final whole-string byte cap. cut -c clips per line only, so it cannot bound
# total output on its own — head -c caps the entire blob, the real backstop that
# keeps emission well under the ~10,000-char hook-output limit.
total="$(printf '%s\n' "$delta" | grep -c '')"
shown="$(printf '%s\n' "$delta" | head -25 | cut -c1-200 | sed 's/^/  /')"
summary="$header"$'\n'"$shown"
if [ "$total" -gt 25 ]; then
  summary="${summary}"$'\n'"  ... (truncated, $((total - 25)) more lines)"
fi

# hard backstop on the entire emission (~3,000 chars; far under the 10k cap)
summary="$(printf '%s' "$summary" | head -c 3000)"

emit "$summary" ""
cleanup
exit 0

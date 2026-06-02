#!/usr/bin/env bash
# PreToolUse hook — snapshot a file's bytes BEFORE Claude's Edit/Write/MultiEdit
# changes it, so the paired PostToolUse hook (verify-diff.sh) can compute the
# exact per-edit delta from real before/after bytes (not from anything the model
# claims). See workitems/plans/diff-verification-hook.md and hooks/README.md.
#
# Contract: FAIL-OPEN. Any internal problem -> emit nothing, exit 0. A broken
# verifier must NEVER block a real edit. Writes snapshots with raw shell only
# (cp / redirection), never Claude's Edit/Write tools, so it cannot re-trigger
# the hooks (the load-bearing no-loop guarantee).

# --- fail-open guards -------------------------------------------------------
command -v jq >/dev/null 2>&1 || exit 0   # no jq -> cannot parse payload, bail quietly

payload="$(cat)"
[ -n "$payload" ] || exit 0

session_id="$(printf '%s' "$payload" | jq -r '.session_id // empty' 2>/dev/null)"
file_path="$(printf '%s' "$payload" | jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' 2>/dev/null)"
tool_use_id="$(printf '%s' "$payload" | jq -r '.tool_use_id // empty' 2>/dev/null)"
cwd="$(printf '%s' "$payload" | jq -r '.cwd // empty' 2>/dev/null)"

# These ids land in filesystem paths below. They are harness-generated in
# practice, but stdin is treated as untrusted, so whitelist them to a safe
# charset (no '/', no '.') to prevent path traversal / dir escape. verify-diff.sh
# applies the identical transform, so sanitized ids still pair deterministically.
[ -n "$session_id" ]  && session_id="$(printf '%s' "$session_id"  | tr -c 'A-Za-z0-9_-' '_')"
[ -n "$tool_use_id" ] && tool_use_id="$(printf '%s' "$tool_use_id" | tr -c 'A-Za-z0-9_-' '_')"

[ -n "$file_path" ] || exit 0             # nothing to snapshot

# --- resolve the real, absolute, symlink-followed path ----------------------
# os.path.realpath handles nonexistent paths (new files) gracefully and follows
# symlinks in the existing prefix, so a link and its target key identically.
case "$file_path" in
  /*) abs="$file_path" ;;
  *)  abs="${cwd:-$PWD}/$file_path" ;;
esac
resolved="$(python3 -c 'import os,sys; print(os.path.realpath(sys.argv[1]))' "$abs" 2>/dev/null)"
[ -n "$resolved" ] || resolved="$abs"

# --- derive snapshot location/key -------------------------------------------
path_hash="$(printf '%s' "$resolved" | shasum -a 256 2>/dev/null | cut -d' ' -f1)"
[ -n "$path_hash" ] || exit 0

# Pair Pre/Post deterministically by tool_use_id (confirmed present in this
# harness's payload — this is the path that actually runs). If it is ever absent,
# fall back to a per-session counter enqueued on a per-path FIFO that Post drains
# in order; best-effort only (a true no-collision per-edit guarantee comes from
# tool_use_id, not the counter).
dir="${TMPDIR:-/tmp}/claude-diff-verify/${session_id:-nosession}"
mkdir -p "$dir" 2>/dev/null || exit 0

if [ -n "$tool_use_id" ]; then
  call_id="$tool_use_id"
else
  counter_file="$dir/.counter"
  n="$(cat "$counter_file" 2>/dev/null)"; n="${n:-0}"; n=$((n + 1))
  printf '%s' "$n" > "$counter_file" 2>/dev/null
  call_id="c$n"
  # enqueue this id on a per-path FIFO; Post pops the oldest, so each same-file
  # edit's snapshot is consumed by exactly one Post (no orphan, no overwrite).
  printf '%s\n' "$call_id" >> "$dir/${path_hash}.queue" 2>/dev/null
fi

key="${path_hash}.${call_id}"
snap="$dir/${key}.snap"
meta="$dir/${key}.meta"

# --- write the snapshot + authoritative sidecar metadata (raw shell only) ----
path_b64="$(printf '%s' "$resolved" | base64 | tr -d '\n')"

if [ -e "$resolved" ]; then
  # oversize guard: the hook also fires on large non-repo / git-ignored files.
  # Cap snapshot cost at 5 MB; above that, record the skip and copy no bytes.
  size="$(wc -c < "$resolved" 2>/dev/null | tr -d ' ')"; size="${size:-0}"
  if [ "$size" -gt 5242880 ]; then
    {
      printf 'existed=yes\n'
      printf 'skipped=oversize\n'
      printf 'path_b64=%s\n' "$path_b64"
    } > "$meta" 2>/dev/null
    exit 0
  fi
  cp "$resolved" "$snap" 2>/dev/null || exit 0
  { printf 'existed=yes\n'; printf 'path_b64=%s\n' "$path_b64"; } > "$meta" 2>/dev/null
else
  # new file (Write creating it): empty baseline, marked existed=no
  : > "$snap" 2>/dev/null
  { printf 'existed=no\n'; printf 'path_b64=%s\n' "$path_b64"; } > "$meta" 2>/dev/null
fi

exit 0

#!/usr/bin/env bash
# SessionStart hook: inject the default-load rule shards into session context.
#
# Why: rules/INDEX.md lists which shards apply every session, but that list only
# reaches context if Claude follows the CLAUDE.md -> rules/INDEX.md -> shard
# read-chain (compliance-based, not guaranteed). This hook reads the same list
# from rules/INDEX.md (single source of truth) and prints the concatenated shards
# to stdout, which Claude Code injects as SessionStart context.
#
# Wired via .claude/settings.json (project scope). See hooks/README.md.

set -euo pipefail

# Resolve repo root from this script's location so the hook works regardless of cwd.
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "${script_dir}/.." && pwd)"
index="${repo_root}/rules/INDEX.md"

[[ -f "$index" ]] || { echo "load-default-rules: rules/INDEX.md not found" >&2; exit 1; }

# Read the hook payload from stdin (may be empty). Pull .source if jq is present.
payload="$(cat || true)"
source_field=""
if command -v jq >/dev/null 2>&1 && [[ -n "$payload" ]]; then
  source_field="$(printf '%s' "$payload" | jq -r '.source // empty' 2>/dev/null || true)"
fi

# Extract the Default-load section: lines between the "## Default-load" heading and
# the next "## " heading, then pull the [name](file.md) link targets in order.
# - Tolerate an optional #anchor fragment on the link, stripping it.
# - Keep only bare in-rules/ filenames (allowlist): a target containing a slash is a
#   cross-domain pointer like ../workitems/INDEX.md, not a shard, so it is excluded.
shards="$(
  awk '
    /^## Default-load/ { in_section=1; next }
    /^## / { in_section=0 }
    in_section
  ' "$index" \
  | grep -oE '\]\([^)#]+\.md(#[^)]*)?\)' \
  | sed -E 's/^\]\(//; s/#[^)]*//; s/\)$//' \
  | grep -E '^[^/]+\.md$' || true
)"

[[ -n "$shards" ]] || { echo "load-default-rules: no default-load shards parsed from rules/INDEX.md" >&2; exit 1; }

# Header marker, with a post-compaction note when applicable.
if [[ "$source_field" == "compact" ]]; then
  echo "# vyasa default-load rules (auto-injected, refreshed post-compaction)"
else
  echo "# vyasa default-load rules (auto-injected at session start from rules/INDEX.md)"
fi
echo ""

missing=0
while IFS= read -r shard; do
  [[ -n "$shard" ]] || continue
  path="${repo_root}/rules/${shard}"
  if [[ -f "$path" ]]; then
    echo "===== rules/${shard} ====="
    cat "$path"
    echo ""
  else
    echo "load-default-rules: listed shard rules/${shard} not found on disk" >&2
    missing=1
  fi
done <<< "$shards"

# Exit 0 so stdout is injected as context. A missing shard is surfaced on stderr
# but does not abort the rest of the load.
exit 0

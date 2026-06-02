#!/usr/bin/env bash
# PR-format CI check — server-side enforcement of rules/git-workflow.md at the PR layer.
#
# One script, three modes (invoked as three separate workflow steps so a red ✗ names
# which target failed):
#
#   title   — validate $PR_TITLE against the SAME subject rules as hooks/commit-msg
#             (type set, optional scope whitelist, ≤72 UTF-8 chars, no trailing period).
#   body    — assert all six required headings are present in $PR_BODY (presence only,
#             order-agnostic, content not inspected).
#   commits — validate each non-merge commit message in $BASE_SHA..$HEAD_SHA with the
#             real hooks/commit-msg, invoked in CI mode (COMMIT_REF="<sha>:") so its
#             Touches: D<N> footer check resolves README from each commit's own tree.
#
# Hand-rolled (no third-party action) so the title/commit checks stay byte-identical to
# the shell rules already enforced locally by hooks/commit-msg — one source of truth.
# See workitems/plans/pr-format-check.md (decisions A, B, E-seam).

set -euo pipefail

mode="${1:-}"

# Resolve repo root so this works regardless of the caller's cwd.
repo_root="$(git rev-parse --show-toplevel)"
commit_msg_hook="${repo_root}/hooks/commit-msg"

# Same whitelists as hooks/commit-msg.
allowed_types_re='feat|fix|docs|refactor|chore|test|eval'
allowed_scopes_re='rules|notes|readme|workitems|hooks|cli|skills|fixtures|runs|reports'

fail() {
  echo "" >&2
  echo "✗ pr-format-check ($mode): $1" >&2
  echo "" >&2
  exit 1
}

# Validate a single subject line against the commit-msg subject rules.
# Used for the PR title. Echoes nothing on success; calls fail() on violation.
validate_subject() {
  local subject="$1"

  local subject_re="^(${allowed_types_re})(\(([a-z-]+)\))?: [^[:space:]].*"
  if ! [[ "$subject" =~ $subject_re ]]; then
    fail "subject does not match '<type>(<scope>): <summary>' or type not in {${allowed_types_re//|/, }}.
  Got: $subject"
  fi

  if [[ "$subject" =~ ^[a-z]+\(([a-z-]+)\): ]]; then
    local scope="${BASH_REMATCH[1]}"
    if ! [[ "$scope" =~ ^(${allowed_scopes_re})$ ]]; then
      fail "scope '$scope' is not in {${allowed_scopes_re//|/, }}"
    fi
  fi

  local subject_len
  subject_len="$(printf '%s' "$subject" | perl -CSD -ne 'chomp; print length($_)')"
  if (( subject_len > 72 )); then
    fail "subject is ${subject_len} chars (max 72): $subject"
  fi

  if [[ "$subject" =~ \.$ ]]; then
    fail "subject ends with a period; drop it"
  fi
}

case "$mode" in
  title)
    # Strip a trailing CR (GitHub fields can arrive CRLF-terminated), then take
    # only the first line as the subject.
    title="${PR_TITLE:-}"
    title="${title%$'\r'}"
    title="${title%%$'\n'*}"
    if [[ -z "$title" ]]; then
      fail "PR title is empty"
    fi
    validate_subject "$title"
    echo "✓ PR title OK: $title"
    ;;

  body)
    body="${PR_BODY:-}"
    required=(
      '## Summary'
      '## Why'
      '## Workitem'
      '## Decisions touched'
      '## Verification'
      '## Followups'
    )
    missing=()
    for heading in "${required[@]}"; do
      # Fixed-string, whole-line match anywhere in the body (order-agnostic).
      # grep returns 1 on no-match; guard it so set -e does not abort.
      if ! printf '%s\n' "$body" | grep -qxF "$heading"; then
        missing+=("$heading")
      fi
    done
    if (( ${#missing[@]} > 0 )); then
      fail "PR body is missing required heading(s): ${missing[*]}"
    fi
    echo "✓ PR body OK: all six required headings present"
    ;;

  commits)
    base="${BASE_SHA:-}"
    head="${HEAD_SHA:-}"
    if [[ -z "$base" || -z "$head" ]]; then
      fail "BASE_SHA and HEAD_SHA must both be set"
    fi
    if [[ ! -x "$commit_msg_hook" ]]; then
      fail "commit-msg hook not found or not executable: $commit_msg_hook"
    fi

    # Non-merge commits only. Merge commits are exempt — GitHub generates their
    # subjects server-side and they cannot conform. rev-list can legitimately
    # return an empty list; that is success (no commits to check).
    shas="$(git rev-list --no-merges "${base}..${head}" || true)"
    if [[ -z "$shas" ]]; then
      echo "✓ no non-merge commits in ${base}..${head} — nothing to validate"
      exit 0
    fi

    tmpdir="$(mktemp -d)"
    trap 'rm -rf "$tmpdir"' EXIT

    failures=0
    while IFS= read -r sha; do
      [[ -z "$sha" ]] && continue
      msg_file="${tmpdir}/${sha}.msg"
      git log -1 --format=%B "$sha" > "$msg_file"
      # Run the real hook in CI mode so its Touches check resolves README from
      # this commit's tree (COMMIT_REF="<sha>:").
      if COMMIT_REF="${sha}:" bash "$commit_msg_hook" "$msg_file"; then
        echo "✓ commit ${sha} OK"
      else
        echo "✗ commit ${sha} FAILED (see message above)" >&2
        failures=$((failures + 1))
      fi
    done <<< "$shas"

    if (( failures > 0 )); then
      fail "${failures} commit message(s) failed validation in ${base}..${head}"
    fi
    echo "✓ all non-merge commit messages OK in ${base}..${head}"
    ;;

  *)
    fail "unknown mode '${mode}' — expected one of: title, body, commits"
    ;;
esac

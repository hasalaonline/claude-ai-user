#!/usr/bin/env bash
# Turn every persona's report into GitHub issues (skipping ones already open)
# and a summary table on the workflow run page.
set -euo pipefail
label=ai-user
gh label create "$label" --color 7c5cff --description "Found by the nightly AI user" --force >/dev/null

summary=${GITHUB_STEP_SUMMARY:-/dev/stdout}
{
  echo "## Nightly AI user"
  echo
  echo "| Persona | Goal completed | Bugs | Summary |"
  echo "|---|---|---|---|"
} >> "$summary"

for report in reports/*.report.json; do
  persona=$(jq -r '.persona' "$report")
  jq -r '"| \(.persona) | \(if .goal_completed then "✅" else "❌" end) | \(.bugs | length) | \(.summary | gsub("\n"; " ")) |"' "$report" >> "$summary"

  jq -c '.bugs[]' "$report" | while read -r bug; do
    title="[AI user] $(jq -r '.title' <<<"$bug")"
    if gh issue list --label "$label" --state open --search "in:title \"$(jq -r '.title' <<<"$bug")\"" \
        --json number --jq 'length' | grep -qv '^0$'; then
      echo "Already open: $title"; continue
    fi
    body=$(jq -r --arg persona "$persona" --arg run "${RUN_URL:-}" '
      [ "**Severity:** \(.severity)  ·  **Found by persona:** `\($persona)`",
        "",
        "### Steps to reproduce",
        (.steps | to_entries | map("\(.key + 1). \(.value)") | join("\n")),
        "",
        "### Expected",
        .expected,
        "",
        "### Actual",
        .actual,
        (if (.console_errors // []) | length > 0
          then "\n### Console errors\n```\n\((.console_errors) | join("\n"))\n```" else empty end),
        "",
        (if $run != "" then "Screenshot `\(.screenshot // "none")` is in the [run artifacts](\($run))." else empty end)
      ] | join("\n")' <<<"$bug")
    gh issue create --title "$title" --body "$body" --label "$label" >/dev/null
    echo "Filed: $title"
  done
done

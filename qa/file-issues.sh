#!/usr/bin/env bash
# Turn every persona's report into GitHub issues (skipping ones already open)
# and a summary table on the workflow run page.
set -euo pipefail
shopt -s nullglob
label=ai-user
gh label create "$label" --color 7c5cff --description "Found by the nightly AI user" --force >/dev/null

summary=${GITHUB_STEP_SUMMARY:-/dev/stdout}
{
  echo "## Nightly AI user"
  echo
  echo "| Persona | Goal completed | Bugs | Summary |"
  echo "|---|---|---|---|"
} >> "$summary"

# Titles of the issues that are already open; we add to this as we file new ones.
open_titles=$(gh issue list --label "$label" --state open --limit 200 --json title --jq '.[].title')

reports=(reports/*.report.json)
[ ${#reports[@]} -gt 0 ] || { echo "No persona reports found"; exit 1; }

for report in "${reports[@]}"; do
  persona=$(jq -r '.persona' "$report")
  jq -r '"| \(.persona) | \(if .goal_completed then "✅" else "❌" end) | \(.bugs | length) | \(.summary | gsub("\n"; " ")) |"' "$report" >> "$summary"

  while read -r bug; do
    title="[AI user] $(jq -r '.title' <<<"$bug")"
    if grep -qxF "$title" <<<"$open_titles"; then
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
    open_titles+=$'\n'"$title"
    echo "Filed: $title"
  done < <(jq -c '.bugs[]' "$report")
done

#!/usr/bin/env bash
# Let Claude use the app as one persona, and save its bug report as JSON.
# Usage: bash qa/run-persona.sh qa/personas/impatient-clicker.md
set -euo pipefail
persona_file=$1
name=$(basename "$persona_file" .md)
app_url=${APP_URL:-http://localhost:3000}
out=reports
mkdir -p "$out/$name"

# A persona can ask for a phone with "device: iPhone 15" in its front matter.
device=$(sed -n 's/^device: *//p' "$persona_file")
args=("@playwright/mcp@0.0.86" --browser chrome --headless --isolated --output-dir "$PWD/$out/$name")
[ -n "$device" ] && args+=(--device "$device")
mcp=$(printf '%s\n' "${args[@]}" | jq -R . | jq -sc '{mcpServers: {playwright: {command: "npx", args: .}}}')

prompt="$(sed "s|{{APP_URL}}|$app_url|g" qa/explore.md)
$(sed '1,/^---$/d' "$persona_file")"

claude -p "$prompt" \
  --mcp-config "$mcp" --strict-mcp-config \
  --tools "" \
  --allowedTools "mcp__playwright__*" \
  --disallowedTools "mcp__playwright__browser_run_code_unsafe,mcp__playwright__browser_evaluate" \
  --permission-mode dontAsk \
  --model sonnet \
  --max-turns 60 \
  --output-format json \
  --json-schema "$(cat qa/report-schema.json)" \
  > "$out/$name.json"

# Keep the screenshots with the report, wherever the browser saved them.
find . -maxdepth 2 -name '*.png' -not -path "./$out/*" -not -path './node_modules/*' -exec mv {} "$out/$name/" \;

jq -e '.structured_output' "$out/$name.json" > /dev/null || {
  echo "No structured report for $name:"; jq -r '.result // .' "$out/$name.json"; exit 1; }
jq --arg p "$name" '.structured_output + {persona: $p, turns: .num_turns}' "$out/$name.json" > "$out/$name.report.json"
echo "$name: $(jq '.bugs | length' "$out/$name.report.json") bug(s), goal completed: $(jq '.goal_completed' "$out/$name.report.json")"

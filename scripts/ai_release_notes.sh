#!/usr/bin/env bash
set -euo pipefail

LOG_FILE="${1:-commit_log.txt}"
MODEL_API_BASE="${MODEL_API_BASE:-}"
MODEL_API_KEY="${MODEL_API_KEY:-}"
MODEL_NAME="${MODEL_NAME:-gpt-4o-mini}"

if [[ -z "$MODEL_API_BASE" || -z "$MODEL_API_KEY" ]]; then
  echo "⚠️ AI not configured. Set MODEL_API_BASE and MODEL_API_KEY as repository secrets."
  echo "# Release Notes (AI not configured)" > RELEASE_NOTES.md
  exit 0
fi

LOG_CONTENT=$(sed 's/\\/\\\\/g' "$LOG_FILE" | sed ':a;N;$!ba;s/\n/\\n/g')

read -r -d '' USER << EOF
Create concise release notes grouped by Features, Fixes, Docs, and Chore from these commits/PR titles:
$LOG_CONTENT
EOF

PAYLOAD=$(jq -n --arg usr "$USER" --arg mdl "$MODEL_NAME" '{
  model: $mdl,
  messages: [
    {role:"system", content:"You turn commit messages into crisp, categorized release notes."},
    {role:"user", content:$usr}
  ],
  temperature: 0.2,
  max_tokens: 600
}')

RESPONSE=$(curl -sS "$MODEL_API_BASE/v1/chat/completions" \
  -H "Authorization: Bearer $MODEL_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // "No response"')
echo "$CONTENT" > RELEASE_NOTES.md

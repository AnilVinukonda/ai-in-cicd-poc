#!/usr/bin/env bash
set -euo pipefail

DIFF_FILE="${1:-diff.patch}"
MODEL_API_BASE="${MODEL_API_BASE:-}"
MODEL_API_KEY="${MODEL_API_KEY:-}"
MODEL_NAME="${MODEL_NAME:-gpt-4o-mini}"

if [[ -z "$MODEL_API_BASE" || -z "$MODEL_API_KEY" ]]; then
  echo "⚠️ AI not configured. Set MODEL_API_BASE and MODEL_API_KEY as repository secrets."
  echo "No AI review available."
  exit 0
fi

DIFF_CONTENT=$(sed 's/\\/\\\\/g' "$DIFF_FILE" | sed ':a;N;$!ba;s/\n/\\n/g')

read -r -d '' SYSTEM << 'SYS'
You are a senior software reviewer. Produce a short PR summary and 3–7 actionable review checks. 
- Be polite and precise.
- Cite file paths and line hunks if clear.
- Flag potential bugs, security smells, and missing tests.
- Never recommend auto-merge.
SYS

read -r -d '' USER << EOF
Summarize and review this diff:\n$DIFF_CONTENT
EOF

PAYLOAD=$(jq -n --arg sys "$SYSTEM" --arg usr "$USER" --arg mdl "$MODEL_NAME" '{
  model: $mdl,
  messages: [
    {role:"system", content:$sys},
    {role:"user", content:$usr}
  ],
  temperature: 0.2,
  max_tokens: 800
}')

RESPONSE=$(curl -sS "$MODEL_API_BASE/v1/chat/completions" \
  -H "Authorization: Bearer $MODEL_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD")

CONTENT=$(echo "$RESPONSE" | jq -r '.choices[0].message.content // "No response"')

cat > review.md <<MD
### 🤖 AI PR Summary & Review (preview)

$CONTENT

> _Note: AI suggestions are advisory. Do not auto-merge based on AI output._
MD

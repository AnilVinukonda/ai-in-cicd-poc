#!/usr/bin/env bash
set -euo pipefail

DIFF_FILE="${1:-diff.patch}"
MODEL_API_BASE="${MODEL_API_BASE:-}"
MODEL_API_KEY="${MODEL_API_KEY:-}"
MODEL_NAME="${MODEL_NAME:-gpt-4o-mini}"

if [[ -z "$MODEL_API_BASE" || -z "$MODEL_API_KEY" ]]; then
  echo "❌ MODEL_API_BASE and/or MODEL_API_KEY not set. Add them as GitHub Actions secrets." >&2
  exit 1
fi

if [[ ! -s "$DIFF_FILE" ]]; then
  echo "⚠️ Diff file '$DIFF_FILE' is missing or empty; continuing with a minimal prompt." >&2
fi

# Build prompt
read -r -d '' SYSTEM << 'SYS'
You are a senior software reviewer. Produce a short PR summary and 3–7 actionable review checks.
- Be polite and precise.
- Cite file paths and line hunks if clear.
- Flag potential bugs, security smells, and missing tests.
- Never recommend auto-merge.
SYS

DIFF_CONTENT=""
if [[ -s "$DIFF_FILE" ]]; then
  # Escape content safely
  DIFF_CONTENT="$(sed 's/\\/\\\\/g' "$DIFF_FILE" | sed ':a;N;$!ba;s/\n/\\n/g')"
else
  DIFF_CONTENT="(no diff content available)"
fi

read -r -d '' USER << EOF
Summarize and review this diff:\n$DIFF_CONTENT
EOF

# Construct payload using jq to avoid JSON escaping issues
PAYLOAD=$(jq -n --arg sys "$SYSTEM" --arg usr "$USER" --arg mdl "$MODEL_NAME" '{
  model: $mdl,
  messages: [
    {role:"system", content:$sys},
    {role:"user",   content:$usr}
  ],
  temperature: 0.2,
  max_tokens: 800
}')

echo "➡️  POST $MODEL_API_BASE/v1/chat/completions (model=$MODEL_NAME)"
RESP_FILE="$(mktemp)"
HTTP_CODE=$(curl -sS -o "$RESP_FILE" -w '%{http_code}' \
  "$MODEL_API_BASE/v1/chat/completions" \
  -H "Authorization: Bearer $MODEL_API_KEY" \
  -H "Content-Type: application/json" \
  -d "$PAYLOAD") || { echo "❌ curl failed (network error). Body:"; cat "$RESP_FILE" || true; exit 1; }

echo "HTTP code: $HTTP_CODE"
if [[ "$HTTP_CODE" -ge 300 || "$HTTP_CODE" -lt 200 ]]; then
  echo "❌ Model API error response:"
  cat "$RESP_FILE" || true
  exit 1
fi

CONTENT=$(jq -r '.choices[0].message.content // empty' < "$RESP_FILE")
if [[ -z "$CONTENT" ]]; then
  echo "❌ No content returned by model. Full response:" >&2
  cat "$RESP_FILE" >&2 || true
  exit 1
fi

cat > review.md <<MD
### 🤖 AI PR Summary & Review (preview)

$CONTENT

> _Note: AI suggestions are advisory. Do not auto-merge based on AI output._
MD

echo "✅ Wrote review.md"

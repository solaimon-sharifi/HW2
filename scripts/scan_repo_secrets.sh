#!/usr/bin/env bash
set -euo pipefail

# scan_repo_secrets.sh
# Usage: ./scripts/scan_repo_secrets.sh /path/to/repo
#        ./scripts/scan_repo_secrets.sh https://github.com/user/repo.git
#
# This script locates likely secret patterns in a repository and prints
# file paths, line numbers, the detected key name (if any) and a redacted
# indicator (length or masked). It will NOT print full secret values.

# SECURITY NOTE:
# Do NOT embed any real private keys, tokens, or credentials inside this
# script. If you need example values for tests, store them in a separate
# `.env.example` or a test fixture and keep them redacted. This script
# intentionally reports matches and will redact values; however any
# committed literal secret remains in git history until removed with a
# history-rewriting tool (git-filter-repo or BFG). Use the repo-clean
# workflow or contact the repo owner to scrub history.

ROOT_ARG=${1:-.}
TMP_CLONE=""

cleanup() {
  if [ -n "$TMP_CLONE" ] && [ -d "$TMP_CLONE" ]; then
    rm -rf "$TMP_CLONE"
  fi
}
trap cleanup EXIT

is_url() {
  case "$1" in
    http://*|https://*|git@*|ssh://*) return 0;;
    *) return 1;;
  esac
}

if is_url "$ROOT_ARG"; then
  echo "Cloning repo $ROOT_ARG to a temporary folder..."
  TMP_CLONE="$(mktemp -d /tmp/scan-repo-XXXX)"
  git clone --depth 1 "$ROOT_ARG" "$TMP_CLONE" >/dev/null 2>&1 || {
    echo "Failed to clone $ROOT_ARG" >&2
    exit 2
  }
  ROOT_DIR="$TMP_CLONE"
else
  ROOT_DIR="$ROOT_ARG"
fi

if [ ! -d "$ROOT_DIR" ]; then
  echo "Path not found: $ROOT_DIR" >&2
  exit 2
fi

echo "Scanning: $ROOT_DIR"

# Patterns to search for (ripgrep or grep will use these as alternation)
PATTERNS=(
  "API[_-]?KEY"
  "APIKEY"
  "API[_-]?TOKEN"
  "ACCESS[_-]?TOKEN"
  "SECRET[_-]?KEY"
  "AWS_ACCESS_KEY_ID"
  "AWS_SECRET_ACCESS_KEY"
  "PGPASSWORD"
  "PASSWORD"
  "TOKEN"
  "SK_live"
  "SK_test"
  "AKIA[0-9A-Z]{16}"
  "xox[bprs]-[0-9A-Za-z-]+"
  "-----BEGIN PRIVATE KEY-----"
)

# join patterns for ripgrep
RG_PATTERN=$(printf '%s|' "${PATTERNS[@]}" | sed 's/|$//')

found=0

search_with_rg() {
  rg --hidden --no-ignore-vcs -n --no-heading -S -e "$RG_PATTERN" "$ROOT_DIR" || true
}

search_with_grep() {
  # fallback to grep
  grep -Rni --exclude-dir={.git,node_modules,venv,__pycache__} -E "$RG_PATTERN" "$ROOT_DIR" || true
}

if command -v rg >/dev/null 2>&1; then
  matches=$(search_with_rg)
else
  matches=$(search_with_grep)
fi

if [ -z "$matches" ]; then
  echo "No potential secrets found by pattern scan."
  exit 0
fi

echo "Potential matches (redacted):"
echo "----------------------------------------"

# Process each match line: format path:line:content
while IFS= read -r line; do
  # normalize fields
  filepath=$(echo "$line" | sed -E 's/^([^:]+):([0-9]+):.*$/\1/')
  lineno=$(echo "$line" | sed -E 's/^([^:]+):([0-9]+):.*$/\2/')
  content=$(echo "$line" | sed -E 's/^[^:]+:[0-9]+:(.*)$/\1/')

  # try to extract key name (word before = or :)
  key=$(echo "$content" | grep -oE "[A-Za-z0-9_\-]+(?=\s*[:=])" | head -1 || true)

  # try to extract a token-like value (after = or :)
  rawval=$(echo "$content" | sed -E 's/.*[:=]\s*"?([^\"\s]+)"?.*/\1/' || true)

  # Determine how to display the match safely
  display=""
  if echo "$content" | grep -qE "AKIA[0-9A-Z]{16}"; then
    matched=$(echo "$content" | grep -oE "AKIA[0-9A-Z]{16}" | head -1)
    display="AWS_ACCESS_KEY (masked): ${matched:0:4}...${matched: -4} (len=${#matched})"
  elif echo "$content" | grep -qE "sk_live|sk_test"; then
    matched=$(echo "$content" | grep -oE "sk_(live|test)_[A-Za-z0-9]+" | head -1)
    if [ -n "$matched" ]; then
      display="Stripe key (masked): ${matched:0:6}... (len=${#matched})"
    fi
  elif echo "$content" | grep -qE "xox[bprs]-"; then
    matched=$(echo "$content" | grep -oE "xox[bprs]-[0-9A-Za-z-]+" | head -1)
    display="Slack token (masked): ${matched:0:6}... (len=${#matched})"
  elif echo "$content" | grep -qE "-----BEGIN PRIVATE KEY-----"; then
    display="Private key file content detected (PEM header)"
  elif [ -n "$key" ] && [ -n "$rawval" ] && [ "$rawval" != "$content" ]; then
    # redact value but show length
    display="${key} = [REDACTED] (len=${#rawval})"
  else
    # fallback: show a short redacted snippet of the content
    snippet=$(echo "$content" | sed -E 's/\s+/ /g' | cut -c1-120)
    display="context: ${snippet//"/\"}"
  fi

  printf "%s:%s -> %s\n" "$filepath" "$lineno" "$display"
  found=1
done <<< "$matches"

if [ "$found" -eq 1 ]; then
  echo "----------------------------------------"
  echo "Scan complete. If you find a real secret, rotate it immediately and then remove it from git history (I can help)."
  exit 0
else
  echo "No matches found."
  exit 0
fi

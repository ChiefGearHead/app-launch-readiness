#!/usr/bin/env bash
# check-secrets.sh - grep a folder for the secret patterns from CHECKLIST.md check 22.
#
# Usage: scripts/check-secrets.sh [--binary] <path>
#   <path>      repo or unpacked build artifact folder to scan
#   --binary    also scan binary files (unzipped .apk/.aab/.ipa, libapp.so); prints file and match only
#
# Prints file:line, the pattern name and the first 8 characters of each match
# (never the full value, so the output is safe to paste into a ticket).
# Skips .git and node_modules.
#
# Exit codes: 0 no matches, 1 matches found, 2 usage error.
#
# A match is a lead, not a verdict: a public Firebase web key or a variable
# name in .env.example is expected. Read each hit and decide.

set -u

usage() {
  echo "Usage: $0 [--binary] <path>" >&2
  echo "Exit: 0 clean, 1 matches found, 2 usage error" >&2
}

binary=0
if [ "${1:-}" = "--binary" ]; then
  binary=1
  shift
fi

if [ $# -ne 1 ] || [ ! -d "$1" ]; then
  usage
  exit 2
fi

target=$1
found=0

scan() {
  local label=$1 regex=$2 out
  if [ "$binary" -eq 1 ]; then
    out=$(grep -rEao -H --exclude-dir=.git --exclude-dir=node_modules -e "$regex" "$target" 2>/dev/null |
      awk -v label="$label" '{ i = index($0, ":"); f = substr($0, 1, i - 1); m = substr($0, i + 1); sub(/^[^A-Za-z0-9-]/, "", m);
        print f ": [" label "] " substr(m, 1, 8) "..." }')
  else
    out=$(grep -rEnoI --exclude-dir=.git --exclude-dir=node_modules -e "$regex" "$target" 2>/dev/null |
      awk -v label="$label" '{ i = index($0, ":"); f = substr($0, 1, i - 1); rest = substr($0, i + 1);
        j = index(rest, ":"); n = substr(rest, 1, j - 1); m = substr(rest, j + 1); sub(/^[^A-Za-z0-9-]/, "", m);
        print f ":" n ": [" label "] " substr(m, 1, 8) "..." }')
  fi
  if [ -n "$out" ]; then
    echo "$out"
    found=1
  fi
}

scan "openai-style key (sk-, sk-proj-)" '(^|[^A-Za-z0-9_])sk-(proj-)?[A-Za-z0-9_-]{20,}'
scan "google api key (AIza)"            'AIza[0-9A-Za-z_-]{35}'
scan "service account json"             'service_account'
scan "private_key field"                'private_key'
scan "pem private key block"            '-----BEGIN [A-Z ]*PRIVATE KEY-----'
scan "supabase service role"            'SUPABASE_SERVICE_ROLE'
scan "secret in public env var"         '(NEXT_PUBLIC|VITE|EXPO_PUBLIC)_[A-Z0-9_]*(SECRET|SERVICE_ROLE|PRIVATE|PASSWORD|API_KEY|TOKEN)'

if [ "$found" -eq 1 ]; then
  echo "Matches found in $target. Review each one; rotate anything real." >&2
  exit 1
fi
echo "No matches in $target."
exit 0

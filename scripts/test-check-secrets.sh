#!/usr/bin/env bash
# Self-test for check-secrets.sh. Builds a throwaway folder of obviously fake
# matches (assembled at runtime so this file holds no key-shaped strings),
# runs the scanner, and checks every planted fake is reported and a clean
# folder passes. Usage: scripts/test-check-secrets.sh

set -u
here=$(cd "$(dirname "$0")" && pwd)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT

fail=0
expect() { # description, condition result (0 = ok)
  if [ "$2" -eq 0 ]; then echo "ok   $1"; else echo "FAIL $1"; fail=1; fi
}

mkdir -p "$tmp/dirty/lib" "$tmp/dirty/node_modules/x" "$tmp/clean"
pad=$(printf 'X%.0s' $(seq 1 40))

printf 'const k = "%s%s";\n'      "sk-"      "$pad"            > "$tmp/dirty/lib/openai.js"
printf 'const k = "%s%s";\n'      "sk-proj-" "$pad"            > "$tmp/dirty/lib/openai2.js"
printf 'apiKey: "%s%s"\n'         "AIza"     "$pad"            > "$tmp/dirty/lib/firebase.dart"
printf '{"type": "%s"}\n'         "service_account"            > "$tmp/dirty/sa.json"
printf '"%s": "fake"\n'           "private_key"                > "$tmp/dirty/sa2.json"
printf '%s\n' "-----BEGIN RSA PRIVATE KEY-----"                > "$tmp/dirty/key.pem"
printf '%s_KEY=fake\n'            "SUPABASE_SERVICE_ROLE"      > "$tmp/dirty/.env"
printf '%s=fake\n'                "NEXT_PUBLIC_STRIPE_SECRET"  > "$tmp/dirty/.env.local"
printf 'sk-%s\n' "$pad"                                        > "$tmp/dirty/node_modules/x/ignored.js"
printf 'task-management-feature-flags-enabled\n'               > "$tmp/clean/notes.txt"
printf 'NEXT_PUBLIC_SUPABASE_ANON_KEY=public-anon\n'           > "$tmp/clean/.env.example"

out=$("$here/check-secrets.sh" "$tmp/dirty" 2>/dev/null); code=$?
expect "dirty folder exits 1" $([ "$code" -eq 1 ]; echo $?)
for f in lib/openai.js lib/openai2.js lib/firebase.dart sa.json sa2.json key.pem .env .env.local; do
  echo "$out" | grep -q "$tmp/dirty/$f:" ; expect "reports $f" $?
done
echo "$out" | grep -q node_modules ; expect "skips node_modules" $([ $? -ne 0 ]; echo $?)
echo "$out" | grep -q "$pad" ; expect "never prints full match" $([ $? -ne 0 ]; echo $?)

"$here/check-secrets.sh" "$tmp/clean" >/dev/null 2>&1; code=$?
expect "clean folder exits 0" $([ "$code" -eq 0 ]; echo $?)

"$here/check-secrets.sh" >/dev/null 2>&1; code=$?
expect "no args exits 2" $([ "$code" -eq 2 ]; echo $?)

exit $fail

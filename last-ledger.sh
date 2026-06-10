#!/usr/bin/env bash
# Print the LEDGER of the most recent run (no shell command-substitution needed by the user).
set -euo pipefail
cd "$(dirname "$0")"
latest="$(ls -t runs 2>/dev/null | grep -v '^\.gitkeep$' | head -1 || true)"
if [ -z "${latest:-}" ]; then
  echo "no runs yet — run ./kernel.sh first"
  exit 0
fi
echo "===== runs/$latest/LEDGER.md ====="
cat "runs/$latest/LEDGER.md"

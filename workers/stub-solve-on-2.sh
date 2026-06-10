#!/usr/bin/env bash
# Deterministic stub worker.
# iter 1: do nothing (warm up). iter >=2: write the correct solution.
# Purpose: prove the loop ITERATES and the SUCCESS stop fires — no model involved.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
echo "[stub-solve-on-2] iter=${ITER:-?}"
if [ "${ITER:-1}" -ge 2 ]; then
  cp "$HERE/fixtures/solution_good.py" "$TASK_DIR/solution.py"
  echo "[stub-solve-on-2] wrote the good solution"
else
  echo "[stub-solve-on-2] noop (warming up)"
fi

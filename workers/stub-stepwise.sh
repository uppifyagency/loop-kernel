#!/usr/bin/env bash
# Deterministic stub worker for a multi-step task: completes ONE more feature each iteration
# by copying $TASK_DIR/fixtures/solution_step_<ITER>.py. Purpose: watch the score CLIMB across
# successive loops (succession), no model involved. Clamps to the highest available step.
set -euo pipefail
step="${ITER:-1}"
f="$TASK_DIR/fixtures/solution_step_$step.py"
if [ ! -f "$f" ]; then
  f="$(ls "$TASK_DIR"/fixtures/solution_step_*.py | sort | tail -1)"
fi
cp "$f" "$TASK_DIR/solution.py"
echo "[stub-stepwise] iter=$step → wrote $(basename "$f")"

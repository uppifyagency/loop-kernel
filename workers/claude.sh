#!/usr/bin/env bash
# The REAL worker: one iteration = one `claude -p` invocation (the Ralph pattern).
# The kernel hands it the spec + the durable ledger (its cross-iteration memory),
# then re-scores objectively. Claude edits files inside the task dir.
set -euo pipefail

PROMPT="$(cat "$PROMPT_FILE")

--- LEDGER (your memory across iterations — read before acting) ---
$(cat "$LEDGER")"

cd "$TASK_DIR"
# --dangerously-skip-permissions = auto mode (Cherny tip 1); scope is this task dir only.
claude -p "$PROMPT" --dangerously-skip-permissions

#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Loop kernel — the simplest control loop that PROVABLY HALTS.
#
# The 5 components of a loop (playbook §0), made concrete:
#   1. Goal     → score == 1.0000 (all tests pass)
#   2. Worker   → $WORKER_CMD (a stub, or `claude -p` — swappable)
#   3. Verifier → task/score.sh runs the REAL tests. The KERNEL runs them, not the
#                 worker → the worker cannot fabricate the result (fixes the
#                 "pasted evidence is fakeable" hole; this is a gate-3 script check).
#   4. Stops    → success | no-progress (objective: the SCORE is flat) | cap
#   5. Memory   → runs/<id>/LEDGER.md (durable file, survives context compaction)
#
# This deliberately uses an EXTERNAL loop (Ralph-style), not /loop nesting /goal —
# that composition is unverified (see SUPERVISOR-LOOP-ORCHESTRATION.md critique).
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# --- config precedence: inline env  >  config.env  >  built-in defaults ---
__TASK_DIR="${TASK_DIR:-}"; __WORKER_CMD="${WORKER_CMD:-}"
__MAX_ITERS="${MAX_ITERS:-}"; __NOPROGRESS_K="${NOPROGRESS_K:-}"
__SCORER="${SCORER:-}"; __PROMPT_FILE="${PROMPT_FILE:-}"
[ -f config.env ] && . ./config.env
TASK_DIR="${__TASK_DIR:-${TASK_DIR:-examples/roman}}"
WORKER_CMD="${__WORKER_CMD:-${WORKER_CMD:-workers/stub-solve-on-2.sh}}"
MAX_ITERS="${__MAX_ITERS:-${MAX_ITERS:-10}}"
NOPROGRESS_K="${__NOPROGRESS_K:-${NOPROGRESS_K:-3}}"

TASK_DIR="$(cd "$TASK_DIR" && pwd)"
SCORER="${__SCORER:-${SCORER:-$TASK_DIR/score.sh}}"
PROMPT_FILE="${__PROMPT_FILE:-${PROMPT_FILE:-$TASK_DIR/PROMPT.md}}"

RUN_ID="$(date +%Y%m%d-%H%M%S)-$$"
RUN_DIR="$SCRIPT_DIR/runs/$RUN_ID"
mkdir -p "$RUN_DIR"
LEDGER="$RUN_DIR/LEDGER.md"

log(){ printf '%s\n' "$*" | tee -a "$RUN_DIR/console.log"; }

{
  echo "# Run $RUN_ID"
  echo
  echo "- worker: \`$WORKER_CMD\`"
  echo "- task:   \`$TASK_DIR\`"
  echo "- stops:  success(score==1.0) | no-progress(${NOPROGRESS_K}x flat) | cap(${MAX_ITERS})"
  echo
  echo "| iter | score | event |"
  echo "|---|---|---|"
} > "$LEDGER"

log "▶ run $RUN_ID  worker=$WORKER_CMD  cap=$MAX_ITERS  noprogress_k=$NOPROGRESS_K"

prev_score="__none__"
plateau=0
iter=0

while : ; do
  iter=$((iter+1))

  # ── STOP: cap ────────────────────────────────────────────────────────────
  if [ "$iter" -gt "$MAX_ITERS" ]; then
    echo "| - | $prev_score | ■ STOP cap (MAX_ITERS=$MAX_ITERS) |" >> "$LEDGER"
    log "■ STOP cap: hit MAX_ITERS=$MAX_ITERS without success"
    exit 2
  fi

  # ── WORK: the worker may CONSULT the ledger, then act (one thing) ─────────
  log "── iter $iter ── WORK"
  ITER="$iter" TASK_DIR="$TASK_DIR" RUN_DIR="$RUN_DIR" LEDGER="$LEDGER" \
    PROMPT_FILE="$PROMPT_FILE" \
    bash "$WORKER_CMD" >>"$RUN_DIR/console.log" 2>&1 \
    || log "  (worker exited non-zero; kernel continues)"

  # ── VERIFY: the kernel runs the real tests (worker can't fake this) ──────
  score_out="$(bash "$SCORER" 2>>"$RUN_DIR/console.log")" && score_exit=0 || score_exit=$?
  score="$(printf '%s\n' "$score_out" | sed -n 's/^score=//p' | tail -1)"
  [ -n "$score" ] || score="0.0000"
  log "  VERIFY score=$score (scorer exit=$score_exit)"

  # ── STOP: success ────────────────────────────────────────────────────────
  if [ "${score_exit:-1}" -eq 0 ]; then
    echo "| $iter | $score | ✅ STOP success |" >> "$LEDGER"
    log "■ STOP success: goal reached at iter $iter"
    exit 0
  fi

  # ── STOP: no-progress (objective — the SCORE is flat, not the diff) ──────
  if [ "$score" = "$prev_score" ]; then plateau=$((plateau+1)); else plateau=0; fi
  if [ "$plateau" -ge "$NOPROGRESS_K" ]; then
    echo "| $iter | $score | ■ STOP no-progress (flat ${NOPROGRESS_K}x) |" >> "$LEDGER"
    log "■ STOP no-progress: score flat at $score for $NOPROGRESS_K iters"
    exit 3
  fi

  echo "| $iter | $score | work (plateau=$plateau) |" >> "$LEDGER"
  prev_score="$score"
done

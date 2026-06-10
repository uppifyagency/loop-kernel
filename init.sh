#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# loop init — the SCRIBE. Interviews you (TTY) or takes the answers as env vars
# (AI agents), then PRINTS the one thing you actually copy-paste: a filled-in
# nested supervisor /goal that runs itself until verified-shipped or a hard stop.
#
# Two callers, one contract:
#   · HUMAN in a terminal →  ./loop init [dir]   (guided six-question interview)
#   · AI AGENT (no TTY)   →  the AGENT asks the six questions in its own
#     conversation (protocol: AGENTS.md · questions: `loop intake`), then calls:
#       GOAL="…" NAME="…" STACK="…" LOOK_ALIKES="…" SKILLS="…" MCPS="…" \
#       REVIEW_METHOD="shell+adversarial" CHECK_CMD="npm test" ./init.sh [dir]
#
# The intake captures the six things a real autonomous run needs:
#   1. Goal / JTBD        what must become TRUE
#   2. Look-alikes        reference URLs + what to match / avoid
#   3. Stack              frameworks, languages, key libs
#   4. Skills / plugins   the packaged workflows to compose (names or GitHub URLs)
#   5. MCPs               servers the loop may use (incl. a browser MCP for self-verify)
#   6. Review method      how DONE is proven: shell check / browser-MCP / adversarial
#
# It writes a tiny .loop/ into the target project (PROJECT.md = the worker's brief,
# MEMORY.md = the cross-session store, score.sh/loop.env = the autonomous runner,
# goal.txt = the /goal for Claude Code, prompt.txt = the same loop as a plain
# prompt for Codex or any other agent), and ends by echoing the paste-ready /goal.
# The /goal text itself lives in templates/ — one source of truth for CLI and agents.
#
#   loop init [dir]            full rich intake (default)
#   loop init [dir] --minimal  the original 5-question kernel intake
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail
INSTALL_DIR="$(cd "$(dirname "$0")" && pwd)"
TEMPLATES="$INSTALL_DIR/templates"

# --- arg parsing: optional positional [dir] + --minimal flag ----------------
MINIMAL=0
POS_DIR=""
for a in "$@"; do
  case "$a" in
    --minimal|-m) MINIMAL=1 ;;
    *) [ -z "$POS_DIR" ] && POS_DIR="$a" ;;
  esac
done

# --- no TTY and no answers? teach the contract instead of dying silently ----
if [ ! -t 0 ] && [ -z "${GOAL:-}" ]; then
  cat >&2 <<'EOF'
✗ stdin is not a TTY and no GOAL was provided — the terminal interview cannot run here.

  If you are an AI coding agent: YOU are the interviewer, this script is the scribe.
    1. Read the six questions:   ./loop intake     (canonical: templates/INTAKE.md)
    2. Ask the USER in your conversation, one question at a time.
    3. Re-run with the answers as env vars (anything unset takes its default):

       GOAL="what must be TRUE when done" \
       NAME="feature-name" STACK="next.js 16, typescript" \
       LOOK_ALIKES="https://example.com — match the export flow" \
       SKILLS="none" MCPS="none" \
       REVIEW_METHOD="shell+adversarial" CHECK_CMD="npm test" \
       ./init.sh /path/to/project

       minimal: GOAL="…" CHECK_CMD="npm test" ./init.sh /path/to/project --minimal

  Full agent protocol: AGENTS.md
EOF
  exit 1
fi

ask() { # ask VAR "question" "default"
  local var="$1" q="$2" def="${3:-}" cur ans
  eval "cur=\${$var:-}"
  if [ -n "$cur" ]; then return; fi            # already provided via env
  if [ -t 0 ]; then
    if [ -n "$def" ]; then printf "  %s [%s]: " "$q" "$def"; else printf "  %s: " "$q"; fi
    read -r ans || ans=""
  else
    ans=""
  fi
  [ -z "$ans" ] && ans="$def"
  eval "$var=\$ans"
}

contains() { case "$2" in *"$1"*) return 0;; *) return 1;; esac; }   # contains NEEDLE HAYSTACK

render() { # render TEMPLATE_FILE — substitute <PLACEHOLDER> tokens from current vars
  local t; t="$(cat "$1")"
  t="${t//<NAME>/${NAME:-}}"
  t="${t//<GOAL>/${GOAL:-}}"
  t="${t//<STACK>/${STACK:-}}"
  t="${t//<SKILLS>/${SKILLS:-}}"
  t="${t//<MCPS>/${MCPS:-}}"
  t="${t//<VERIF>/${VERIF:-}}"
  t="${t//<CHECK_CMD>/${CHECK_CMD:-}}"
  t="${t//<MAX_ITERS>/${MAX_ITERS:-}}"
  printf '%s\n' "$t"
}

# ─────────────────────────────────────────────────────────────────────────────
echo "┌─ loop init ───────────────────────────────────────────────"
echo "│ Answer a few questions. Nothing runs until you say so —"
echo "│ at the end you get a /goal to paste into Claude Code."
echo "└───────────────────────────────────────────────────────────"

ask PROJECT_DIR "Project directory to build in" "${POS_DIR:-$(pwd)}"
ask GOAL        "Goal / Job-to-be-done — what must be TRUE when done?" ""
[ -n "${GOAL:-}" ] || { echo "✗ A goal is required. Re-run and describe what to build." >&2; exit 1; }

PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
LOOP_DIR="$PROJECT_DIR/.loop"
mkdir -p "$LOOP_DIR"

# ── MINIMAL path: the original kernel intake (5 questions) ───────────────────
if [ "$MINIMAL" -eq 1 ]; then
  ask CHECK_CMD    "Check command that defines DONE (exit 0 = done)" "npm test"
  ask MAX_ITERS    "Max iterations (hard cap)" "20"
  ask NOPROGRESS_K "Stop after N no-progress iterations" "4"

  cat > "$LOOP_DIR/GOAL.md" <<EOF
# Goal
$GOAL

You are ONE iteration of an autonomous loop building this project. The loop scores your
work by running this command and reading its exit code — you cannot fake it:

    $CHECK_CMD        # exit 0 means DONE

## Discipline (one thing per iteration)
- CONSULT the LEDGER appended below before acting; never repeat an approach that already failed.
- Make the smallest change that should move the check toward passing, then STOP and let the
  loop re-score.
- Do NOT weaken, skip, or delete checks/tests to make the command pass.

## Memory
If something failed, append one line: FAIL (what) -> INVESTIGATE (why) -> VERIFY (checked fact)
-> DISTILL (the rule) so the next iteration learns.
EOF
  cat > "$LOOP_DIR/score.sh" <<EOF
#!/usr/bin/env bash
# Auto-generated by loop init. Objective check for: $GOAL
set -uo pipefail
cd "$PROJECT_DIR"
if $CHECK_CMD >/dev/null 2>&1; then echo "score=1.0000"; exit 0; else echo "score=0.0000"; exit 1; fi
EOF
  chmod +x "$LOOP_DIR/score.sh"
  cat > "$LOOP_DIR/loop.env" <<EOF
# Auto-generated by loop init on $(date +%Y-%m-%d)
TASK_DIR="$PROJECT_DIR"
SCORER="$LOOP_DIR/score.sh"
PROMPT_FILE="$LOOP_DIR/GOAL.md"
MAX_ITERS=$MAX_ITERS
NOPROGRESS_K=$NOPROGRESS_K
EOF
  render "$TEMPLATES/goal-minimal.txt" > "$LOOP_DIR/goal.txt"
  sed 's|^/goal ||' "$LOOP_DIR/goal.txt" > "$LOOP_DIR/prompt.txt"
  echo
  echo "✓ Configured  $LOOP_DIR  (minimal)"
  echo "▶ Autonomous: $INSTALL_DIR/loop run \"$PROJECT_DIR\""
  echo "▶ Or paste into Claude Code (Codex/other agents: .loop/prompt.txt):"
  sed 's/^/    /' "$LOOP_DIR/goal.txt"
  exit 0
fi

# ── RICH path: the full intake ───────────────────────────────────────────────
ask NAME        "Short feature/project name (folder-safe)" "feature"
ask LOOK_ALIKES "Reference / look-alike URLs + what to match or avoid" "none"
ask STACK       "Stack — frameworks, languages, key libraries" ""
ask SKILLS      "Skills/plugins to compose (names or GitHub URLs, comma-sep)" "none"

# Show what MCPs are wired before asking which to use.
if [ -t 0 ] && command -v claude >/dev/null 2>&1; then
  echo "  · MCPs currently available to Claude Code:"
  claude mcp list 2>/dev/null | sed 's/^/      /' || echo "      (could not list — 'claude mcp list' failed)"
fi
ask MCPS        "MCPs the loop must use (comma-sep, or 'none')" "none"

echo "  · Review method — how is DONE proven? combine with '+':"
echo "      shell        a command that exits 0 (npm test, pytest -q, npm run check …)"
echo "      browser      self-verify by driving real Chrome via chrome-devtools MCP (:9222)"
echo "      adversarial  a fresh reviewer subagent over the diff (correctness/security)"
ask REVIEW_METHOD "Review method(s)" "shell+adversarial"

# Always capture a shell check (also powers the autonomous runner); required if 'shell' chosen.
_def_check="npm test"; contains shell "$REVIEW_METHOD" || _def_check="(none — verification is in-conversation)"
ask CHECK_CMD   "Shell check command (exit 0 = done)" "$_def_check"

# Browser self-verify needs to know how to boot the app and what flow to exercise.
if contains browser "$REVIEW_METHOD"; then
  ask PREVIEW_CMD "How to start the app for the browser check" "npm run dev"
  ask PREVIEW_URL "URL the app serves on" "http://localhost:3000"
  ask KEY_FLOW    "The ONE critical flow to verify live in the browser" ""
fi

ask MAX_ITERS   "Max turns (hard cap on the /goal)" "120"
ask NOPROGRESS_K "Stop after N no-progress iterations (autonomous runner)" "4"
: "${PREVIEW_CMD:=}"; : "${PREVIEW_URL:=}"; : "${KEY_FLOW:=}"

# ── Assemble the VERIFICATION-loop body from the chosen method(s) ─────────────
# (no backticks here — the generated /goal is plain text, paste-safe)
VERIF="Assume it is all broken: hunt correctness bugs, edge-cases, regressions."
contains shell "$REVIEW_METHOD" && \
  VERIF="$VERIF Run the shell check ($CHECK_CMD) yourself and paste its full output here."
if contains browser "$REVIEW_METHOD"; then
  VERIF="$VERIF Boot the app ($PREVIEW_CMD) and drive $PREVIEW_URL through the chrome-devtools MCP on port 9222: exercise the key flow — $KEY_FLOW — and paste the browser-MCP transcript (HTTP 200 plus the flow visibly working), not a description of it."
fi
if contains adversarial "$REVIEW_METHOD" || contains all "$REVIEW_METHOD"; then
  VERIF="$VERIF Spawn a FRESH reviewer subagent that sees ONLY the diff (git diff main...HEAD) and the criteria (correctness, broken contracts, security, the JTBD, parity vs the look-alikes in .loop/PROJECT.md); fix or refute each finding with evidence pasted here; SATISFIED needs a second fresh pass reporting zero correctness findings."
fi

# Suggest the browser MCP install line if the user wants browser review but it is not wired.
MCP_HINT=""
if contains browser "$REVIEW_METHOD" && ! contains chrome "$MCPS"; then
  MCP_HINT="npx -y chrome-devtools-mcp@latest   # add the browser MCP, then: claude mcp add chrome-devtools"
fi

# ── 1) PROJECT.md — the worker's brief, re-read every turn ───────────────────
cat > "$LOOP_DIR/PROJECT.md" <<EOF
# PROJECT — $NAME

## Goal / Job-to-be-done
$GOAL

## Look-alikes (match / avoid)
$LOOK_ALIKES

## Stack
$STACK

## Skills / plugins to compose
$SKILLS

## MCPs to use
$MCPS

## Definition of DONE — review method: $REVIEW_METHOD
- shell check: $CHECK_CMD
- browser self-verify: ${PREVIEW_URL:-n/a} via chrome-devtools MCP (:9222); boot: ${PREVIEW_CMD:-n/a}; key flow: ${KEY_FLOW:-n/a}
- adversarial: fresh reviewer subagent over git diff main...HEAD (correctness/security/parity)
${MCP_HINT:+- setup needed: $MCP_HINT}

## Scope / constraints / legal
- Edit only under this project's paths for feature "$NAME".
- Do NOT weaken, skip, or delete checks/tests to make them pass — that is the failure, not the fix.
- Anything unknown is marked [TO CONFIRM: owner], never invented.

## Budgets / caps
- Max $MAX_ITERS turns. No-progress: two turns with no diff ⇒ stop and report the blocking loop.
EOF

# ── 2) MEMORY.md — the cross-session store the loops append to ────────────────
cat > "$LOOP_DIR/MEMORY.md" <<EOF
# MEMORY — $NAME
> Cross-iteration memory. Each turn appends; the next turn CONSULTS before acting.
> Progression: FAIL (what broke) -> INVESTIGATE (why) -> VERIFY (the checked fact) -> DISTILL (the rule).

EOF

# ── 3) Autonomous-runner config (only meaningful with a shell check) ──────────
cat > "$LOOP_DIR/score.sh" <<EOF
#!/usr/bin/env bash
# Auto-generated by loop init. Objective check for: $NAME
set -uo pipefail
cd "$PROJECT_DIR"
if $CHECK_CMD >/dev/null 2>&1; then echo "score=1.0000"; exit 0; else echo "score=0.0000"; exit 1; fi
EOF
chmod +x "$LOOP_DIR/score.sh"
cat > "$LOOP_DIR/loop.env" <<EOF
# Auto-generated by loop init on $(date +%Y-%m-%d)
TASK_DIR="$PROJECT_DIR"
SCORER="$LOOP_DIR/score.sh"
PROMPT_FILE="$LOOP_DIR/PROJECT.md"
MAX_ITERS=$MAX_ITERS
NOPROGRESS_K=$NOPROGRESS_K
EOF

# ── 4) THE OUTPUT — the filled-in nested supervisor /goal, ready to paste ─────
# Rendered from templates/goal-supervisor.txt — the single source of truth.
render "$TEMPLATES/goal-supervisor.txt" > "$LOOP_DIR/goal.txt"
sed 's|^/goal ||' "$LOOP_DIR/goal.txt" > "$LOOP_DIR/prompt.txt"

# Guard the official /goal limit (≤ 4000 chars).
GOAL_CHARS=$(wc -c < "$LOOP_DIR/goal.txt" | tr -d ' ')

echo
echo "✓ Configured  $LOOP_DIR"
echo "    PROJECT.md   the worker's brief (goal · look-alikes · stack · skills · MCPs · review)"
echo "    MEMORY.md    the cross-session memory store"
echo "    score.sh     shell scorer for the autonomous runner ($CHECK_CMD)"
echo "    goal.txt     the paste-ready /goal below (Claude Code)"
echo "    prompt.txt   the same loop as a plain prompt (Codex / any other agent)"
[ -n "$MCP_HINT" ] && { echo; echo "  ⚠ browser review chosen but no chrome MCP detected. First run:"; echo "      $MCP_HINT"; }
if [ "$GOAL_CHARS" -gt 4000 ]; then
  echo "  ⚠ generated /goal is $GOAL_CHARS chars (> 4000 limit) — trim look-alikes/skills, the rest lives in PROJECT.md."
fi
echo
echo "▶ Three ways to run it — pick one:"
echo
echo "  A) Inside Claude Code (recommended — nested loops, self-verify, max power):"
echo "     paste the /goal below. Turn on auto mode so it runs solo."
echo
echo "  B) Codex or any other agent: hand it .loop/prompt.txt (same loop, plain prompt)."
echo
echo "  C) Headless autonomous runner (one claude -p per iteration, shell-scored):"
echo "     $INSTALL_DIR/loop run \"$PROJECT_DIR\""
echo
echo "─────────────────────────  COPY FROM HERE  ─────────────────────────"
cat "$LOOP_DIR/goal.txt"
echo "──────────────────────────  TO HERE  ───────────────────────────────"

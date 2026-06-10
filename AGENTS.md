# AGENTS.md — operating manual for AI coding agents

> **You — the agent reading this — are the interviewer. The scripts are the scribe.**
> The terminal interview (`./loop init`) needs a TTY your shell tool doesn't have:
> run it bare and every question is silently skipped. Don't. Follow this protocol instead.

## When to act

The user says anything like — in any language: *"set up a loop"*, *"create a goal loop"*,
*"loop this project"*, *"make it build itself"*, *"design a loop for X"*, *"start the
interview"*, *"avvia l'intervista"*, *"crea un loop"*.

## The protocol (3 steps)

### 1 · Run the interview IN-conversation

Ask the **six intake questions one at a time** — never as a single wall of questions.
The canonical list with examples, env-var names and defaults is
[templates/INTAKE.md](templates/INTAKE.md) (also printed by `./loop intake`):

1. **Goal / JTBD** — the one end state that must become TRUE
2. **Look-alikes** — reference URLs + what to match / avoid
3. **Stack** — frameworks, languages, key libraries
4. **Skills / plugins** — packaged workflows to compose (`none` is fine)
5. **MCPs** — servers the loop may use (`claude mcp list` helps; `none` is fine)
6. **Review method** — how DONE is proven: `shell` · `browser` · `adversarial`, combinable with `+`

Push back on vague answers — the loop is only as good as its check (Q6).
Record unknowns as `[TO CONFIRM: owner]`; never invent. Ask the derived questions
(`CHECK_CMD`, `NAME`, browser details, caps) only when relevant — see the INTAKE table.

### 2 · Call the scribe (non-interactive, env vars)

```bash
GOAL="…" NAME="…" STACK="…" LOOK_ALIKES="…" SKILLS="…" MCPS="…" \
REVIEW_METHOD="shell+adversarial" CHECK_CMD="npm run check" \
./init.sh /path/to/the/user/project
```

Every answer is an env var; anything unset takes a sane default (full table in
[templates/INTAKE.md](templates/INTAKE.md)). The scribe writes `.loop/` into the
target project and prints the filled-in goal block.

### 3 · Deliver the loop (pick by host)

| Host | Deliver |
|------|---------|
| Claude Code | the printed `/goal` block (also at `.loop/goal.txt`) — the user pastes it and turns on auto mode |
| Codex / any other agent | `.loop/prompt.txt` — the same loop as a plain prompt (`./loop goal <dir> --plain`) |
| Headless | `./loop run /path/to/project` — kernel-scored: unfakeable check, three hard stops, durable ledger |

## Zero-setup variant

No project wiring at all: `./loop nwave <name>` prints one self-contained `/goal`
that runs the interview as its WAVE 0 *inside the conversation* and drives a full
SDLC — stories → architecture → acceptance tests → TDD → adversarial verify.
Nothing executes until the user replies `CONFIRMED`. Details: [docs/NWAVE-KERNEL.md](docs/NWAVE-KERNEL.md).

## Hard rules

- **Never run `./loop init` or `./init.sh` without env vars** — it is a TTY interview;
  under your shell tool it exits (by design) with the contract printed above.
- **Never weaken the check** to make a loop pass: no editing `score.sh`, no skipping or
  deleting tests, no `.skip`/`.only`. The kernel runs the check itself — faking it *is* the failure.
- **The judge is never the worker** — verification is a fresh reviewer/evaluator, never self-approval.
- **Edit only inside the target project** the user named. This repo is the toolbox, not the workpiece.

## Repo map

| Path | What |
|------|------|
| `loop` | the one entrypoint (`init` · `intake` · `nwave` · `run` · `goal` · `ledger` · `demo`) |
| `init.sh` | the scribe — TTY interview for humans, env-var contract for agents → `.loop/` + `/goal` |
| `templates/` | single source of truth: the six questions (`INTAKE.md`) + the `/goal` templates |
| `kernel.sh` | the ~100-line control loop: work → verify → ledger → stop (success · no-progress · cap) |
| `kernels/nwave.txt` | the zero-setup full-SDLC `/goal` |
| `workers/` | one iteration each: `claude.sh` (real), `stub-*` (deterministic demos) |
| `.claude/skills/loop-init/` | the Claude Code skill — install globally: `cp -r .claude/skills/loop-init ~/.claude/skills/` |
| `docs/` | the playbook, the nWave kernel notes, the supervisor-orchestration design |

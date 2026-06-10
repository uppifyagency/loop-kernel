---
name: loop-init
description: Interview the user with six questions, then generate a self-driving goal-loop for their project — a .loop/ config plus a paste-ready /goal with an unfakeable check and three hard stops. Use when the user says "set up a loop", "create a loop", "goal loop", "loop init", "design a loop", "autonomous loop", "make it build itself", "loop engineering", or mentions loop-kernel — in any language ("crea un loop", "avvia l'intervista").
---

# loop-init — interview, then write the loop

You are the **interviewer**; the loop-kernel scripts are the **scribe**.
Never run `./loop init` or `init.sh` bare — it is a TTY interview and your shell
tool has no TTY: it will refuse and print the env-var contract. Follow these steps.

## Step 0 · Locate the kernel

Find a loop-kernel checkout: a directory containing `loop`, `init.sh`, and `templates/`.
Try, in order: the current repo; `~/tools/loop-kernel`; ask the user. If none exists, offer:

```bash
git clone https://github.com/uppifyagency/loop-kernel ~/tools/loop-kernel
```

Set `KERNEL=<that path>` for the steps below. Also confirm **which project** the loop
is for (the target directory — usually the user's current repo, never the kernel itself).

## Step 1 · The interview (in this conversation, ONE question at a time)

Read `$KERNEL/templates/INTAKE.md` for the canonical questions, examples, and defaults.
Ask the six questions one at a time — short, conversational, with an example each:

1. **Goal / JTBD** — what must be TRUE when this is done? (one measurable end state)
2. **Look-alikes** — reference URLs + what to match or avoid
3. **Stack** — frameworks, languages, key libraries
4. **Skills / plugins** — packaged workflows to compose (`none` is fine)
5. **MCPs** — servers the loop may use (`none` is fine)
6. **Review method** — how is DONE proven: `shell` · `browser` · `adversarial` (combinable with `+`)

Then the derived answers, only when relevant: `CHECK_CMD` (always — the shell command
that exits 0 when done), `NAME` (folder-safe), and for `browser`: `PREVIEW_CMD`,
`PREVIEW_URL`, `KEY_FLOW`. Caps default to `MAX_ITERS=120`, `NOPROGRESS_K=4`.

Push back on vague answers — especially Q6: the loop is only as good as its check.
Record unknowns as `[TO CONFIRM: owner]`; never invent.

## Step 2 · Call the scribe (non-interactive)

```bash
GOAL="…" NAME="…" STACK="…" LOOK_ALIKES="…" SKILLS="…" MCPS="…" \
REVIEW_METHOD="shell+adversarial" CHECK_CMD="npm run check" \
"$KERNEL/init.sh" /path/to/target/project
```

Anything unset takes its default. The scribe writes `.loop/` (PROJECT.md · MEMORY.md ·
score.sh · loop.env · goal.txt · prompt.txt) and prints the filled-in `/goal`.

## Step 3 · Deliver

- **Claude Code**: show the `/goal` block in a copyable code block and tell the user:
  paste it, turn on auto mode, walk away. (Also saved at `.loop/goal.txt`.)
- **Codex / other agents**: hand over `.loop/prompt.txt` (same loop, plain prompt).
- **Headless**: `"$KERNEL/loop" run /path/to/target/project` — the kernel re-runs the
  real check every iteration (unfakeable) and halts on success · no-progress · cap.

## Zero-setup variant

If the user wants no project wiring at all: `"$KERNEL/loop" nwave <name>` prints one
self-contained `/goal` that runs this same interview as its WAVE 0 *in-conversation*
and drives a full SDLC. Nothing executes until the user replies `CONFIRMED`.

## Guardrails

- Never weaken a check to make a loop pass — no editing `score.sh`, no skipped or
  deleted tests, no `.skip`/`.only`. Faking the check *is* the failure.
- The judge is never the worker: verification is a fresh reviewer, never self-approval.
- Edit only inside the target project. The kernel repo is the toolbox, not the workpiece.

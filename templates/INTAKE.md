# The Loop Intake — six questions, one contract

The single source of truth for the interview that turns an intent into a loop.
Three consumers: the terminal interview (`./loop init`), the agent protocol
(`AGENTS.md` + the `loop-init` skill), and `./loop intake` (prints this file).

**Rule for interviewers — human or agent: ask ONE question at a time, push back
on vague answers, never invent — unknowns are recorded as `[TO CONFIRM: owner]`.**
The loop is only as good as its check (Q6). Spend your follow-ups there.

## The six questions

| # | Question | env var | A good answer |
|---|----------|---------|---------------|
| 1 | **Goal / JTBD** — what must be TRUE when this is done? | `GOAL` | one measurable end state, not a feature list: "a logged-in reseller can download a quote PDF that matches the cart" |
| 2 | **Look-alikes** — reference URLs + what to match or avoid | `LOOK_ALIKES` | "https://linear.app — match the command palette; avoid their onboarding" |
| 3 | **Stack** — frameworks, languages, key libraries | `STACK` | "Next.js 16, TypeScript strict, Tailwind v4, Convex" |
| 4 | **Skills / plugins** — packaged workflows to compose | `SKILLS` | names or GitHub URLs, comma-separated; `none` is a fine answer |
| 5 | **MCPs** — servers the loop may use | `MCPS` | "chrome-devtools" for browser self-verify; `none` is fine |
| 6 | **Review method** — how is DONE proven? combine with `+` | `REVIEW_METHOD` | `shell` (a command that exits 0) · `browser` (drive real Chrome via the chrome-devtools MCP on :9222) · `adversarial` (a fresh reviewer subagent over the diff). Default: `shell+adversarial` |

## Derived answers (ask only when relevant)

| When | Question | env var | default |
|------|----------|---------|---------|
| always | short folder-safe feature name | `NAME` | `feature` |
| always (also powers the headless runner) | shell check command (exit 0 = done) | `CHECK_CMD` | `npm test` |
| `browser` in Q6 | how to start the app | `PREVIEW_CMD` | `npm run dev` |
| `browser` in Q6 | URL the app serves on | `PREVIEW_URL` | `http://localhost:3000` |
| `browser` in Q6 | the ONE critical flow to verify live | `KEY_FLOW` | — (required) |
| always | max turns (hard cap) | `MAX_ITERS` | `120` |
| always | stop after N no-progress iterations | `NOPROGRESS_K` | `4` |

## The non-interactive contract (how agents call the scribe)

`./init.sh` run bare needs a TTY: under an agent's shell tool every question is
silently skipped. So the **agent runs the interview in its own conversation**, then
calls the scribe with the answers as env vars — anything unset takes its default:

```bash
GOAL="what must be TRUE when done" \
NAME="quote-pdf" STACK="next.js 16, typescript" \
LOOK_ALIKES="https://example.com — match the export flow" \
SKILLS="none" MCPS="chrome-devtools" \
REVIEW_METHOD="shell+adversarial" CHECK_CMD="npm run check" \
./init.sh /path/to/project
```

Minimal variant (goal + check + caps, no orchestration):

```bash
GOAL="…" CHECK_CMD="npm test" MAX_ITERS=20 NOPROGRESS_K=4 ./init.sh /path/to/project --minimal
```

## What the scribe writes

```
.loop/PROJECT.md   the worker's brief — re-read every turn
.loop/MEMORY.md    cross-session memory store
.loop/score.sh     objective scorer (the kernel runs it — the worker can't fake it)
.loop/loop.env     config for the headless runner (./loop run)
.loop/goal.txt     the paste-ready /goal            (Claude Code)
.loop/prompt.txt   the same loop as a plain prompt  (Codex / any other agent)
```

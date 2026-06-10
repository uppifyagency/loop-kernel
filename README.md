<p align="center">
  <img src="assets/hero.svg" alt="loop-kernel — the simplest AI coding-agent loop that provably halts. Loop engineering, goal, verifier, three hard stops, durable memory." width="100%">
</p>

<h1 align="center">loop-kernel</h1>

<p align="center">
  <b>Point it at your repo, give it a goal, walk away.</b><br>
  The simplest autonomous AI-agent loop that <i>provably halts</i> — goal · an unfakeable verifier ·
  three hard stops · durable memory.<br>
  No framework, no dependencies, ~110 lines of bash.
</p>

<p align="center">
  <img alt="License: MIT" src="https://img.shields.io/badge/license-MIT-22c55e">
  <img alt="bash 3.2+" src="https://img.shields.io/badge/bash-3.2%2B-3b82f6">
  <img alt="python 3.8+" src="https://img.shields.io/badge/python-3.8%2B-8b5cf6">
  <img alt="dependencies: none" src="https://img.shields.io/badge/dependencies-none-fb7185">
  <img alt="PRs welcome" src="https://img.shields.io/badge/PRs-welcome-22c55e">
</p>

---

> **"You shouldn't be prompting coding agents anymore. You should be designing loops that prompt your agents."**

The romantic version of loops is a thousand agents building your company overnight. The
production version is that you write the loops, and **most of the work is making them stop.**
`loop-kernel` packages that: a Ralph-style loop with the three hard stops and an objective,
unfakeable check wired in — driven by a guided one-command setup.

## Use it on your project

```bash
git clone https://github.com/uppifyagency/loop-kernel
cd loop-kernel
```
```bash
./loop init /path/to/your/project
```
```bash
./loop run /path/to/your/project
```

`loop init` asks four things — your **project**, the one-line **goal**, the **check command that
defines “done”** (`npm test`, `pytest -q`, `npm run check`, `go test ./...` — anything that exits
`0` when finished), and the **caps** — then writes a tiny `.loop/` into your project. `loop run`
then drives the agent (`claude -p`) iteration after iteration, re-running your real check each
time, until it passes or a guardrail stops it. Close your laptop.

Prefer to stay inside Claude Code? `loop init` also prints a ready-to-paste **`/goal`**:

```
/goal <your goal> Done when `npm test` exits 0. Check: paste the command's output in the
conversation. Constraints: do not modify, skip, or delete tests to pass; keep the diff minimal.
Or stop after 20 turns.
```

## See it work first (30 seconds, no model, no cost)

```bash
./loop demo
```

That runs the loop on a bundled example with a deterministic stub worker — you watch it iterate
and halt. To see each of the three stops fire:

```bash
./reset.sh examples/roman && WORKER_CMD=workers/stub-solve-on-2.sh ./kernel.sh
```
```bash
./reset.sh examples/roman && WORKER_CMD=workers/stub-noop.sh ./kernel.sh
```
```bash
./reset.sh examples/roman && WORKER_CMD=workers/stub-noop.sh MAX_ITERS=4 NOPROGRESS_K=99 ./kernel.sh
```
```bash
./loop ledger
```

Exit codes: `0` success · `2` cap · `3` no-progress.

## What is loop engineering?

Loop engineering is the shift from *writing prompts* to *designing the control system that
prompts the agent on every tick*. A good loop turns the goal into feedback the agent runs
against: it acts, gets scored, self-corrects, and repeats **until the goal is met or a guardrail
stops it**. The leverage moved from crafting one prompt to designing the loop.

## The five components

| # | Component | Where it lives |
|---|---|---|
| 1 | **Goal** — one measurable end state | your check command exits `0` |
| 2 | **Worker** — does the work | `workers/claude.sh` (or any agent CLI) |
| 3 | **Verifier** — independent, can't be faked | the kernel runs your check itself, every iteration |
| 4 | **Stops** — the three hard stops | success · no-progress · cap |
| 5 | **Memory** — durable across iterations | `runs/<id>/LEDGER.md` |

Every iteration is the same cycle — this is the whole system:

```
 ┌────────────────────────── one iteration ──────────────────────────┐
 │  WORK              VERIFY               LEDGER          TRIGGER?    │
 │  worker reads  →   kernel runs your →   append      →   success |  │
 │  GOAL + LEDGER     REAL check            iter/score      no-progress│
 │                    (worker can't fake)                  | cap      │
 └──────────── no stop fired? go again ◀──────────────────────────────┘
```

## The three hard stops

Every serious 2026 write-up on loops converges on the same three guardrails. All three are
first-class here, and all three are tested:

- **success** — the check passes (exit `0`).
- **no-progress** — the objective **score** stays flat for *K* iterations (exit `3`). Progress is
  the score moving, **not** "did files change" — a busy-but-stuck agent still halts.
- **cap** — a hard ceiling on iterations (exit `2`).

## Architecture

```
  you ──init: goal + check──▶  loop / kernel.sh  ──spawns──▶  worker  (swappable)
                                  │   ▲                       claude -p | any CLI
                      your check  │   │ score
                       command ──▶ .loop/score.sh ──runs──▶  YOUR real tests / build / lint
                                  │
                                  └──▶  runs/<id>/LEDGER.md   (durable memory)
```

The worker is stochastic and swappable; the **control system is fixed and deterministic.** That
separation is what makes a loop *engineered* instead of an ad-hoc prompt. The kernel deliberately
uses an **external loop** (the Ralph lineage), not an unverified nesting of in-session primitives.

## Under the hood: the scorer contract

`loop init` generates `.loop/score.sh` for you, but the interface is tiny and you can write your
own (see `examples/`): a scorer prints one `score=<fraction>` line and exits `0` **iff** the goal
is met. Tests, a build exit code, a mutation score, a lint count — anything reducible to a number.

## Use a different agent

`workers/claude.sh` is the Ralph pattern: one iteration = one `claude -p` call, handed the goal
plus the ledger (its cross-iteration memory). Swap it for any CLI agent that edits files — point
`WORKER_CMD` at your own script. The worker contract is five env vars: `ITER`, `TASK_DIR`,
`RUN_DIR`, `LEDGER`, `PROMPT_FILE`.

## Verified vs opinionated

This repo is deliberate about what it claims:

- **Verified (mechanics):** an external loop driving a CLI agent; the three hard stops; a script
  verifier so the check is *run*, never trusted. Demonstrated by running the kernel.
- **Opinionated (design, unproven at scale):** larger layered "supervisor / N-loop"
  architectures. Research notes, not load-bearing claims — and intentionally **not** what this
  kernel ships. See [docs/](docs/).

## Documentation

- **[The Loop Engineering Playbook](docs/GOAL-LOOP-PLAYBOOK.md)** — verified `/goal` & `/loop`
  prompts for every phase of code development, from a multi-source, adversarially-verified research
  run cross-checked against official Claude docs. *(IT, with English prompts.)*
- **[Supervisor-Loop Orchestration](docs/SUPERVISOR-LOOP-ORCHESTRATION.md)** — the layered
  "Russian-doll" design, a single-`/goal` nested variant, and an honest verified-vs-synthesized
  split. *(IT.)*

## FAQ

**How is this different from a Ralph loop?** Same external-loop spirit, but the three hard stops,
an objective unfakeable check, durable memory, and a guided setup are first-class — not bolted on.

**Does it only work with Claude?** No. The worker is any script that edits files. `workers/claude.sh`
is one example; point `WORKER_CMD` at your own.

**Can the agent cheat the check?** No. The **kernel** runs it, not the worker. Editing or skipping
your tests changes nothing — the kernel re-runs the real command every iteration.

**Why bash instead of a framework?** The whole value is the smallest thing that *provably halts*.
A framework would hide the stop logic — the one part you must see and trust.

**What if I have no tests yet?** Give it a goal whose check is "write the failing tests, then make
them pass," or start with a build/lint command as the check. The loop is only as good as the check
you give it — that honesty is the point.

## Roadmap

- More reference tasks with objective scorers (harder, multi-step, real repos).
- A `/goal`-evaluator worker variant (model-judged, for non-deterministic goals).
- Optional second-opinion verification stage (a fresh reviewer subagent).

## Credits

Built on ideas from Boris Cherny ("my job is to write loops"), Geoffrey Huntley (the Ralph loop),
and Anthropic's engineering on harnesses for long-running agents.

## License

MIT © 2026 [Uppify Agency](https://github.com/uppifyagency). See [LICENSE](LICENSE).

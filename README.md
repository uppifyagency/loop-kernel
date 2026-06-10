<p align="center">
  <img src="assets/hero.svg" alt="loop-kernel — the simplest AI coding-agent loop that provably halts. Loop engineering: goal, an unfakeable verifier, three hard stops, durable memory." width="100%">
</p>

<h1 align="center">loop-kernel</h1>

<p align="center">
  <b>Answer six questions. Get a self-driving loop that provably halts.</b><br>
  <code>loop init</code> interviews you about the job, then prints a ready-to-paste <code>/goal</code> —
  nested loops, an unfakeable check, three hard stops, durable memory — that runs itself until it's
  verified-shipped or a guardrail stops it.<br>
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
`loop-kernel` packages that: one guided command turns your intent into a loop with three hard
stops and an objective, unfakeable check wired in.

## One command. It interviews you, then writes the loop.

```bash
git clone https://github.com/uppifyagency/loop-kernel
cd loop-kernel
```
```bash
./loop init /path/to/your/project
```

`loop init` asks the six things a real autonomous run actually needs:

| | It asks | Why it matters |
|---|---|---|
| 1 | **Goal / JTBD** | the one end state that must become true |
| 2 | **Look-alikes** | reference URLs + what to match or avoid |
| 3 | **Stack** | frameworks, languages, key libraries |
| 4 | **Skills / plugins** | the packaged workflows to compose (names or GitHub URLs) |
| 5 | **MCPs** | servers the loop may use — it shows `claude mcp list` first |
| 6 | **Review method** | how DONE is proven: `shell` check · `browser` (chrome-devtools MCP, :9222) · `adversarial` reviewer — pick one or combine |

Then it writes a tiny `.loop/` into your project (`PROJECT.md` = the brief the worker re-reads every
turn, `MEMORY.md` = the cross-session store, `score.sh` = the objective scorer) and **ends by printing
the one thing you copy-paste**: a filled-in nested supervisor `/goal`.

```
─────────────────────────  COPY FROM HERE  ─────────────────────────
/goal Feature <name> is verified-shipped. … You are the SUPERVISOR: you orchestrate the
nested loops, you do NOT free-code. Operate at maximum autonomy and effort …
  > ARCHITECTURE LOOP — explore >=2 options, weigh trade-offs vs the look-alikes …
  > CODING LOOP (one story/turn, on the <stack>) — tests FAIL before & PASS after …
  > VERIFICATION LOOP (adversarial) — run the shell check and paste its output; drive
    <url> through the chrome-devtools MCP on port 9222; spawn a FRESH reviewer over the diff …
  MEMORY LOOP (every turn) — FAIL → INVESTIGATE → VERIFY → DISTILL …
DONE only when ARCHITECTURE + every story's CODING + VERIFICATION are SATISFIED … Or stop after 120 turns.
──────────────────────────  TO HERE  ───────────────────────────────
```

The review method you pick **shapes the VERIFICATION loop**: choose `browser` and it wires in a
live self-verify that drives real Chrome via [`chrome-devtools-mcp`](https://github.com/ChromeDevTools/chrome-devtools-mcp);
choose `adversarial` and it spawns a fresh reviewer over `git diff`. The rich context (look-alikes,
scope, legal) lives in `PROJECT.md`, so the `/goal` stays under the official 4,000-character limit.

### Two ways to run it (both printed at the end)

- **A — inside Claude Code (recommended):** paste the `/goal`, turn on auto mode, walk away. The
  nested loops, the browser self-verify, and the durable memory all run in-session, at full power.
- **B — headless runner:** `./loop run /path/to/your/project` drives the agent (`claude -p`) one
  iteration at a time, re-running your real shell check each time until it passes or a guardrail fires.

> Just want the bare check, no orchestration? `./loop init <dir> --minimal` is the original
> five-question intake (goal + check command + caps).

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
  you ──init: 6-question intake──▶  loop / kernel.sh  ──spawns──▶  worker  (swappable)
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
- **Opinionated (design):** the **nested supervisor `/goal`** that `loop init` generates, and the
  larger layered "supervisor / N-loop" architecture behind it. It is a coherent operating
  framework built on verified primitives — not a benchmarked SOTA claim. See [docs/](docs/).

## Documentation

- **[The Loop Engineering Playbook](docs/GOAL-LOOP-PLAYBOOK.md)** — verified `/goal` & `/loop`
  prompts for every phase of code development, from a multi-source, adversarially-verified research
  run cross-checked against official Claude docs. *(IT, with English prompts.)*
- **[Supervisor-Loop Orchestration](docs/SUPERVISOR-LOOP-ORCHESTRATION.md)** — the layered
  "Russian-doll" design `loop init` draws from: the INTAKE, the operational-loop template, and an
  honest verified-vs-synthesized split. *(IT.)*

## FAQ

**What exactly does `loop init` produce?** A `.loop/` folder (`PROJECT.md`, `MEMORY.md`, `score.sh`,
`loop.env`) and a printed, paste-ready nested `/goal`. Paste it into Claude Code, or run it headless
with `./loop run`.

**How is this different from a Ralph loop?** Same external-loop spirit, but the three hard stops,
an objective unfakeable check, durable memory, and a guided rich intake are first-class — not bolted on.

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
- A first-class browser-MCP scorer for the headless runner (today the browser self-verify runs
  inside the pasted `/goal`).

## Credits

Built on ideas from Boris Cherny ("my job is to write loops"), Geoffrey Huntley (the Ralph loop),
and Anthropic's engineering on harnesses for long-running agents.

## License

MIT © 2026 [Uppify Agency](https://github.com/uppifyagency). See [LICENSE](LICENSE).

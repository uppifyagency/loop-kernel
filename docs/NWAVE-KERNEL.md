# The nWave Kernel `/goal` — a full SDLC in one paste, under 4,000 characters

> Canonical artifact: [`kernels/nwave.txt`](../kernels/nwave.txt) · printed by `./loop nwave <name>`
> Provenance: [nWave](https://github.com/nWave-ai/nWave) (the 7-wave ATDD methodology) compressed
> through the rules of the [Loop Engineering Playbook](GOAL-LOOP-PLAYBOOK.md) §2 and the
> single-`/goal` variant of [Supervisor-Loop Orchestration](SUPERVISOR-LOOP-ORCHESTRATION.md) §9.

## What it is

One `/goal` condition (3,938 chars; `<NAME>` appears twice, so feature names up to ~35 chars fit)
that turns Claude Code into a **supervisor over five nested waves** — requirements, architecture,
acceptance tests, TDD implementation, adversarial verification — with the six intake questions
asked **in-conversation** instead of in your terminal. Nothing dispatches until you reply
`CONFIRMED`.

```bash
./loop nwave quote-pdf   # prints the filled kernel + char count; paste into Claude Code
```

## `loop init` vs `loop nwave`

| | `loop init` | `loop nwave` |
|---|---|---|
| Intake | 6 questions in your terminal | WAVE 0 interview in-conversation |
| Setup | writes `.loop/` (brief, memory, scorer) | zero — the kernel creates its own `docs/feature/<name>/` |
| Phases | ARCHITECTURE → CODING → VERIFICATION | DISCUSS → DESIGN → DISTILL → DELIVER → VERIFY (nWave) |
| Headless runner | yes (`loop run`, kernel-scored) | no — in-session `/goal` only |
| Best for | repos you control, repeat runs | one-paste starts, full SDLC discipline incl. ATDD |

## How nWave's seven waves compress into five nested loops

| nWave | In the kernel | How |
|---|---|---|
| DISCOVER + DIVERGE | **WAVE 0 · INTAKE** | JTBD + look-alikes *are* discovery and divergence, compressed into questions; human gate (`CONFIRMED`) |
| DISCUSS | **DISCUSS** | user stories with Given/When/Then + explicit out-of-scope |
| DESIGN | **DESIGN** | ≥2 options, trade-offs vs look-alikes, risks, rationale |
| DEVOPS | folded into **VERIFY** | "if CI exists, make it green" + browser-MCP live check |
| DISTILL | **DISTILL** | ATDD: acceptance tests *before* code, failing for the right reason (assertion, not setup error) |
| DELIVER | **DELIVER** | outside-in TDD, ONE story per turn (Ralph discipline), red+green pasted |
| Reviewers as hard gates | **VERIFY** + invariant | fresh reviewer subagent sees only `git diff` + criteria; the goal closes only via the external evaluator |

## v1.1 hardening (from an adversarial first-principles review)

| # | Fix | Failure mode closed |
|---|---|---|
| 1 | NO-PROGRESS exempts the `CONFIRMED` wait | self-contradiction: waiting for the human = no diff = the worker had to declare itself blocked |
| 2 | LEDGER pasted every turn + closing turn re-runs all checks fresh | evidence decay under context compaction made DONE undecidable (or closable on assertion) |
| 3 | intake asks for **allowed code paths**; final constraint references them | "the feature's paths" was an undefined set — an unevaluable constraint |
| 4 | `wc -l` of new files required; rule scoped to **new** files | a 300-line rule with no required evidence is invisible to a transcript-only judge |
| 5 | `JTBD` added to the reviewer's criteria | the reviewer could approve look-alike parity while missing the actual job-to-be-done |

**Deliberately unchanged** (the steelman against the fix won): no "pre-existing CI failures"
carve-out (more hackable than the conflict it resolves); VERIFY cadence stays self-healing via
the evaluator's "no" reasons; no human gate on the spec mid-run (it would deadlock an unattended
session).

## Trust model — read this before walking away

The `/goal` evaluator judges the **transcript only** and runs no tools. The worker therefore
mediates *all* evidence the judge sees: judge **independence** is real, observation independence
is zero. This kernel is **trust-but-review** — unlike `loop run`, where the kernel executes your
check itself and the score is unfakeable. Remedies that live outside the kernel: pair it with a
deterministic Stop-hook script or CI, and supervise the first run. Mutation testing was dropped
for character budget — opt in via the REVIEW METHOD intake question.

## Launch preconditions (yours, not the judge's)

1. **Dedicated, clean branch off `main`** — VERIFY reviews `git diff main...HEAD`; unrelated
   dirt pollutes the review.
2. Reply with the literal token **`CONFIRMED`** at the intake gate (rigid token = decidable).
3. While the worker awaits `CONFIRMED`, the Stop hook may force up to ~8 idle continuations
   before yielding the turn — expected noise, not a bug.
4. Enforced clauses (red/green, `wc -l`, LEDGER, reviewer pass, browser transcript) are judged
   on pasted evidence; aspirational ones (coverage, behavior-preserving) guide the worker and
   are covered by the VERIFY reviewer instead.

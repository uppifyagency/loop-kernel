# Contributing to loop-kernel

Thanks for considering a contribution. This project stays small on purpose: the value is the
smallest loop that *provably halts*. Additions should preserve that.

## Good first contributions

- **A new reference task** under a `task-*/` folder, with its own `score.sh` (the contract:
  print one `score=<fraction>` line, exit `0` iff the goal is met) and `tests/`.
- **A new worker** under `workers/` for another agent CLI (the interface is the env contract:
  `ITER`, `TASK_DIR`, `RUN_DIR`, `LEDGER`, `PROMPT_FILE`).
- **Docs / examples** that clarify the five components or the three hard stops.

## Ground rules

1. **Don't hide the stop logic.** Anything that makes the halting behavior less visible or less
   verifiable will be declined.
2. **Verified vs opinionated.** Keep mechanics (things demonstrated by running) separate from
   design opinions. Label opinions as such.
3. **Run it.** Before opening a PR, run the three deterministic demos and paste the exit codes
   (`0` success · `2` cap · `3` no-progress) in the PR description.
4. **No new runtime dependencies** in the kernel. Bash + the task's own toolchain only.

## Bugs

Open an issue with the exact command, the run's `LEDGER.md`, and your OS / bash / python versions.

# Task: implement `roman_to_int`

You are ONE iteration of an autonomous loop. The loop scores your work objectively by
running the real test suite — you cannot fake the result, so make the tests actually pass.

## Goal (the loop stops only when this is true)
Every test under `tests/` passes. The objective scorer runs `python3 score.py` and the loop
halts when `score=1.0000`.

## Where to work
- Implement `roman_to_int(s: str) -> int` in `solution.py` (it currently raises
  `NotImplementedError`).
- Do NOT edit anything under `tests/` and do NOT weaken `score.py`. (The kernel re-runs the
  real tests itself, so tampering with them changes nothing and is pure waste.)

## Discipline — one thing per iteration
- CONSULT the LEDGER appended below before acting; do not repeat an approach that already failed.
- Make the smallest change that should raise the score, then STOP and let the loop re-score.

## Memory
If something you tried did not work, note it in one line so the next iteration learns:
FAIL (what) → INVESTIGATE (why) → VERIFY (the checked fact) → DISTILL (the rule).

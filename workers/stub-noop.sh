#!/usr/bin/env bash
# Deterministic stub worker that never changes anything.
# Purpose: prove the NO-PROGRESS stop fires (the score stays flat) — no model involved.
echo "[stub-noop] iter=${ITER:-?} — doing nothing"

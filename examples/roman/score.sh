#!/usr/bin/env bash
# Pluggable scorer contract: print one `score=<frac>` line; exit 0 iff goal reached.
# Swap this file (and tests/) to retarget the kernel at any language/task.
set -euo pipefail
cd "$(dirname "$0")"
exec python3 score.py

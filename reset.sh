#!/usr/bin/env bash
# Restore the task to its RED state so runs are repeatable.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
TASK="${1:-task}"
cp "$SCRIPT_DIR/$TASK/solution_template.py" "$SCRIPT_DIR/$TASK/solution.py"
echo "reset: $TASK/solution.py restored to the RED template (raises NotImplementedError)"

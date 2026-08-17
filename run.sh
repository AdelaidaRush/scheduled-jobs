#!/usr/bin/env bash
# Decrypt into a temporary directory, run one script, filter its output, encrypt
# the state back. Nothing decrypted outlives the machine it runs on.
#
#   ./run.sh main.py [args]

set -euo pipefail
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="${WORK_DIR:-$HERE/work}"
SCRIPT="${1:?usage: ./run.sh <script.py> [args]}"
shift || true

"$HERE/vault.sh" unlock-code "$WORK" >/dev/null
"$HERE/vault.sh" unlock-state "$WORK/data" >/dev/null

cd "$WORK"
export STATE_DIR="$WORK/data"

status=0
python3 "$SCRIPT" "$@" 2>&1 | python3 mask.py || status=${PIPESTATUS[0]}

cd "$HERE"
"$HERE/vault.sh" lock-state "$WORK/data" >/dev/null
exit $status

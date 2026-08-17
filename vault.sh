#!/usr/bin/env bash
# Encrypt and decrypt the archives. AES-256-CTR, key derived from a passphrase
# (PBKDF2, 300k iterations). The passphrase comes from VAULT_PASS in the
# environment, or from ~/.config/vault/pass locally. It is never stored here.
#
#   ./vault.sh lock-code    <dir>
#   ./vault.sh lock-state   <dir>
#   ./vault.sh lock-harvest <dir>
#   ./vault.sh unlock-code    <dir>
#   ./vault.sh unlock-state   <dir>
#   ./vault.sh unlock-harvest <dir>

set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS="${VAULT_PASS:-}"
if [ -z "$PASS" ] && [ -f "$HOME/.config/vault/pass" ]; then
  PASS="$(cat "$HOME/.config/vault/pass")"
fi
[ -n "$PASS" ] || { echo "no passphrase"; exit 1; }

export VAULT_PASS="$PASS"
enc() { openssl enc -aes-256-ctr -pbkdf2 -iter 300000 -salt -pass env:VAULT_PASS; }
dec() { openssl enc -d -aes-256-ctr -pbkdf2 -iter 300000 -salt -pass env:VAULT_PASS; }

find_list() {
  for c in "${BIG_LIST:-}" "$HERE/work/harvest.list" "$(dirname "$1")/harvest.list"; do
    [ -n "$c" ] && [ -f "$c" ] && { echo "$c"; return; }
  done
  echo ""
}

EXCLUDES=(--exclude=.git --exclude=.DS_Store --exclude=data --exclude=public
          --exclude=.env --exclude='*.pyc' --exclude=__pycache__ --exclude='*.enc')

case "${1:-}" in
  lock-code)
    tar -czf - -C "${2:-.}" "${EXCLUDES[@]}" . | enc > "$HERE/code.enc"
    echo "code.enc: $(wc -c < "$HERE/code.enc") bytes" ;;
  lock-state)
    src="${2:-./data}"
    big="$(find_list "$src")"
    ex=(--exclude=.DS_Store --exclude='*.log')
    if [ -n "$big" ]; then
      while read -r f; do [ -n "$f" ] && ex+=(--exclude="$f"); done < "$big"
    fi
    tar -czf - -C "$src" "${ex[@]}" . | enc > "$HERE/state.enc"
    echo "state.enc: $(wc -c < "$HERE/state.enc") bytes" ;;
  lock-harvest)
    src="${2:-./data}"
    big="$(find_list "$src")"
    [ -n "$big" ] || { echo "no manifest, nothing to pack"; exit 1; }
    tar -czf - -C "$src" -T "$big" | enc > "$HERE/harvest.enc"
    echo "harvest.enc: $(wc -c < "$HERE/harvest.enc") bytes" ;;
  unlock-code)
    mkdir -p "${2:-./work}"; dec < "$HERE/code.enc" | tar -xzf - -C "${2:-./work}" ;;
  unlock-state)
    mkdir -p "${2:-./work/data}"
    [ -s "$HERE/state.enc" ] && dec < "$HERE/state.enc" | tar -xzf - -C "${2:-./work/data}" || true ;;
  unlock-harvest)
    mkdir -p "${2:-./work/data}"
    [ -s "$HERE/harvest.enc" ] && dec < "$HERE/harvest.enc" | tar -xzf - -C "${2:-./work/data}" || true ;;
  *)
    echo "usage: lock-code|lock-state|lock-harvest|unlock-code|unlock-state|unlock-harvest"; exit 2 ;;
esac

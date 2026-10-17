#!/bin/sh
# Run a Shadowfax security test with or without the patch that reintroduces
# the corresponding vulnerability.
#
# Usage: attacks/run.sh <flaw> [--vulnerable]
#   flaw: 01 | 02a | 02b
#
# The RISC-V toolchain (riscv64-unknown-linux-gnu- for the firmware and
# riscv64-unknown-elf- for the tests) must be in PATH. Keys must have been
# generated once with `make -C shadowfax generate-keys`.
set -eu

ATTACKS=$(cd "$(dirname "$0")" && pwd)
SHADOWFAX="$ATTACKS/../shadowfax"
export PYTHON3="${PYTHON3:-uv run --with-requirements $SHADOWFAX/requirements.txt python3}"

case "${1:-}" in
    01)  patch=01-convert-no-revoke.diff;     test=converted-memory-isolation ;;
    02a) patch=02a-reclaim-no-sanitize.diff;  test=reclaimed-memory-zero ;;
    02b) patch=02b-reclaim-no-ownership.diff; test=cross-domain-reclaim ;;
    *)   sed -n '5,6p' "$0" >&2; exit 2 ;;
esac

if [ "${2:-}" = "--vulnerable" ]; then
    git -C "$SHADOWFAX" apply --check "$ATTACKS/$patch"
    git -C "$SHADOWFAX" apply "$ATTACKS/$patch"
    trap 'git -C "$SHADOWFAX" apply -R "$ATTACKS/$patch"' EXIT
    trap 'exit 130' INT TERM
fi

# The firmware rule tracks Rust sources, so this rebuilds whenever the
# patch is applied or reverted.
make -C "$SHADOWFAX" firmware
make -C "$SHADOWFAX/test/security/$test" run

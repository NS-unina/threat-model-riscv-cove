#!/bin/sh
# Run a Shadowfax security test with or without the patch that reintroduces
# the corresponding vulnerability. See usage() or run with --help.
set -eu

ATTACKS=$(cd "$(dirname "$0")" && pwd)
SHADOWFAX="$ATTACKS/../shadowfax"
export PYTHON3="${PYTHON3:-uv run --with-requirements $SHADOWFAX/requirements.txt python3}"

usage() {
    cat <<EOF
Usage: $0 <flaw> [--vulnerable]
       $0 -h | --help

Run the Shadowfax security test for <flaw>. Without --vulnerable the test runs
on the current firmware and the attack must be blocked. With --vulnerable the
patch that removes the fix is applied to the submodule, the firmware is rebuilt,
and the patch is reverted when the script exits.

Flaws:
  01   Trusted memory accessible from the untrusted domain
       patch: 01-convert-no-revoke.diff      test: converted-memory-isolation
  02a  Confidentiality leakage after TVM disposal
       patch: 02a-reclaim-no-sanitize.diff   test: reclaimed-memory-zero
  02b  Cross-domain interference (TVM tampering, destruction, memory stealing)
       patch: 02b-no-ownership.diff         test: cross-domain-reclaim

Options:
  --vulnerable  apply the patch that reintroduces the vulnerability
  -h, --help    show this help and exit

Environment:
  PYTHON3  Python command for Shadowfax's build scripts
           (default: uv run --with-requirements <shadowfax>/requirements.txt python3)

The RISC-V toolchain (riscv64-unknown-linux-gnu- for the firmware and
riscv64-unknown-elf- for the tests) must be in PATH, and the keys must have
been generated once with: make -C shadowfax generate-keys

Examples:
  $0 01                # fixed firmware: attack blocked
  $0 01 --vulnerable   # fix removed: attack succeeds
EOF
}

case "${1:-}" in
    -h|--help) usage; exit 0 ;;
    01)  patch=01-convert-no-revoke.diff;     test=converted-memory-isolation ;;
    02a) patch=02a-reclaim-no-sanitize.diff;  test=reclaimed-memory-zero ;;
    02b) patch=02b-no-ownership.diff;         test=cross-domain-reclaim ;;
    *)   usage >&2; exit 2 ;;
esac

case "${2:-}" in
    ""|--vulnerable) ;;
    -h|--help) usage; exit 0 ;;
    *) echo "$0: unknown option: $2" >&2; usage >&2; exit 2 ;;
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

#!/bin/sh
# Measure the TVM lifecycle with and without the security fixes.
#
# Usage: attacks/overhead/measure.sh [runs] [sizes-in-MiB...]
#   SHADOWFAX=<tree>  Shadowfax tree to build (default: the submodule).
#                     no-fixes.diff is applied to it and reverted on exit.
#
# Writes results.csv (variant,guest_mib,run,kind,operation,cycles,instructions,
# time_ticks) and prints the mean lifecycle time and the fixes' overhead.
set -eu

HERE=$(cd "$(dirname "$0")" && pwd)
SHADOWFAX=$(cd "${SHADOWFAX:-$HERE/../../shadowfax}" && pwd)
export PYTHON3="${PYTHON3:-uv run --with-requirements $SHADOWFAX/requirements.txt python3}"
RUNS=${1:-5}
[ $# -gt 0 ] && shift
SIZES=${*:-2 8 32}
OUT=${OUT:-$HERE/results.csv}

echo 'variant,guest_mib,run,kind,operation,cycles,instructions,time_ticks' > "$OUT"

measure() {
    variant=$1
    make -C "$SHADOWFAX" firmware >/dev/null
    for mib in $SIZES; do
        size=$((mib * 1024 * 1024))
        make -C "$HERE" ROOT="$SHADOWFAX" GUEST_RAM_SIZE=$size all >/dev/null
        for run in $(seq 1 "$RUNS"); do
            echo "[$variant ${mib} MiB run $run/$RUNS]"
            taskset -c 0 timeout 900 make -s -C "$HERE" ROOT="$SHADOWFAX" \
                GUEST_RAM_SIZE=$size run </dev/null 2>&1 | tr -d '\r' |
                sed -n "s/^LATENCY,/$variant,$mib,$run,/p" >> "$OUT"
        done
    done
}

measure fixed

git -C "$SHADOWFAX" apply "$HERE/no-fixes.diff"
trap 'git -C "$SHADOWFAX" apply -R "$HERE/no-fixes.diff"; make -C "$SHADOWFAX" firmware >/dev/null' EXIT
trap 'exit 130' INT TERM
measure no-fixes

awk -F, '
$4 == "lifecycle" { t[$1","$2] += $8; n[$1","$2]++; sizes[$2] = 1 }
END {
    printf "%-9s %14s %14s %9s\n", "guest", "no-fixes (s)", "fixed (s)", "overhead"
    for (s in sizes) {
        a = t["no-fixes,"s] / n["no-fixes,"s] / 1e7
        b = t["fixed,"s] / n["fixed,"s] / 1e7
        printf "%3d MiB   %14.3f %14.3f %8.1f%%\n", s, a, b, (b / a - 1) * 100
    }
}' "$OUT" | sort -n
echo "Results: $OUT"

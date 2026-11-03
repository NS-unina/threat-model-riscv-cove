#!/usr/bin/env python3
"""Summarize measure.sh results for the overhead table.

    evaluation/overhead/table.py [results.csv]

Prints, per guest size, the mean TVM lifecycle time without and with the
fixes, the overhead factor, and how much of the added time is zeroing, then
the LaTeX rows for tab:fix-overhead and the figures quoted in the text.

Zeroing happens in Shadowfax's convert and reclaim paths, so the extra time
of those calls is attributed to it. That extra time also contains the
ticketing and ownership checks on those calls, which are negligible next to
zeroing; the "other" column is everything else the fixes add.
"""

import csv
import statistics
import sys
from collections import defaultdict
from pathlib import Path

TIMEBASE_HZ = 10_000_000  # QEMU virt timebase: time_ticks per second
ZEROING_OPERATIONS = {
    "CONVERT_META_PAGES",
    "CONVERT_GUEST_PAGES",
    "RECLAIM_META_PAGES",
    "RECLAIM_GUEST_PAGES",
}


def load(path):
    # lifecycle[variant][mib] = [seconds per run]
    # calls[variant][mib][operation] = [seconds per run]
    lifecycle = defaultdict(lambda: defaultdict(list))
    calls = defaultdict(lambda: defaultdict(lambda: defaultdict(list)))
    with open(path, newline="") as f:
        for row in csv.DictReader(f):
            if row["variant"] == "variant":  # header repeated by a concatenated file
                continue
            seconds = int(row["time_ticks"]) / TIMEBASE_HZ
            mib = int(row["guest_mib"])
            if row["kind"] == "lifecycle":
                lifecycle[row["variant"]][mib].append(seconds)
            else:
                calls[row["variant"]][mib][row["operation"]].append(seconds)
    return lifecycle, calls


def summarize(lifecycle, calls):
    sizes = sorted(set(lifecycle["fixed"]) & set(lifecycle["no-fixes"]))
    if not sizes:
        sys.exit("table.py: no guest size has both 'fixed' and 'no-fixes' runs yet")
    rows = []
    for mib in sizes:
        base = statistics.mean(lifecycle["no-fixes"][mib])
        fixed = statistics.mean(lifecycle["fixed"][mib])
        added = fixed - base
        zeroing = sum(
            statistics.mean(calls["fixed"][mib][op]) - statistics.mean(calls["no-fixes"][mib][op])
            for op in ZEROING_OPERATIONS
            if calls["fixed"][mib][op] and calls["no-fixes"][mib][op]
        )
        runs = lifecycle["fixed"][mib] + lifecycle["no-fixes"][mib]
        spread = max(
            (max(v) - min(v)) / statistics.mean(v)
            for v in (lifecycle["fixed"][mib], lifecycle["no-fixes"][mib])
        )
        rows.append(
            {
                "mib": mib,
                "runs": (len(lifecycle["no-fixes"][mib]), len(lifecycle["fixed"][mib])),
                "base": base,
                "fixed": fixed,
                "factor": fixed / base,
                "zeroing_share": zeroing / added if added > 0 else float("nan"),
                "other": added - zeroing,
                "spread": spread,
            }
        )
    return rows


def seconds(value):
    """Three decimals below 10 s, one above: 0.041, 1.132, 60.1."""
    return f"{value:.3f}" if value < 10 else f"{value:.1f}"


def factor(value):
    return f"{value:.1f}" if value < 10 else f"{value:.0f}"


def main():
    path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).with_name("results.csv")
    rows = summarize(*load(path))

    print(f"{path}\n")
    print(f"{'guest':>6} {'runs':>7} {'no fixes':>10} {'fixed':>10} {'overhead':>9} "
          f"{'zeroing':>8} {'other':>9} {'spread':>7}")
    for r in rows:
        print(f"{r['mib']:>3} MiB {r['runs'][0]:>3}/{r['runs'][1]:<3} {r['base']:>9.3f}s "
              f"{r['fixed']:>9.3f}s {r['factor']:>8.1f}x {r['zeroing_share']:>7.2%} "
              f"{r['other']:>8.3f}s {r['spread']:>6.1%}")

    # When the other fixes cost next to nothing, run-to-run noise can push the
    # zeroing share slightly past 100%; cap it for the paper.
    print("\n% LaTeX rows for tab:fix-overhead")
    for r in rows:
        share = min(r["zeroing_share"], 1.0) * 100
        print(f"    {r['mib']:>4} & {seconds(r['base'])} & {seconds(r['fixed'])} & "
              f"{factor(r['factor'])}$\\times$ & {share:.1f}\\% \\\\")

    smallest = rows[0]
    print("\n% Figures for the text")
    print(f"% {smallest['mib']} MiB lifecycle: {seconds(smallest['fixed'])} s with the fixes, "
          f"{seconds(smallest['base'])} s without")
    print(f"% zeroing share of the added time: {min(r['zeroing_share'] for r in rows):.2%} "
          f"to {max(r['zeroing_share'] for r in rows):.2%}")
    print(f"% other fixes per lifecycle: {min(r['other'] for r in rows):.3f} "
          f"to {max(r['other'] for r in rows):.3f} s")
    print(f"% largest run-to-run spread (max-min over mean): {max(r['spread'] for r in rows):.1%}")


if __name__ == "__main__":
    main()

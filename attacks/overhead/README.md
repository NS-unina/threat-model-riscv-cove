# Overhead of the security fixes

This directory measures how much the fixes for the vulnerabilities in this
repository slow down a confidential VM's lifecycle.

`main.c` is a Shadowfax bare-metal launcher that times every COVH call of one
complete TVM lifecycle: convert, create, load, finalize, run, destroy and
reclaim. The guest (`guest.c`) shuts down immediately, so only the lifecycle
is measured. Code running inside a TVM never reaches the fixed paths, so it
pays no overhead.

`no-fixes.diff` builds the baseline. It removes every fix described in the
paper:

- the two-phase ticketing protocol and ownership tracking;
- revocation of converted memory from the untrusted domain (flaw 01);
- zeroing on convert, on reclaim and in the TSM's `destroy_tvm` (flaw 02a);
- the ownership checks on reclaim (flaw 02b).

The baseline only checks a range's shape, lends it to the TSM on convert, and
removes it from the TSM on reclaim.

## Running

Generate the Shadowfax keys once, put the RISC-V toolchain in `PATH`, then:

```sh
attacks/overhead/measure.sh 5 2 8 32    # 5 runs each for 2, 8 and 32 MiB guests
```

The script builds and measures the fixed firmware, applies `no-fixes.diff`,
measures again and reverts the patch. Set `SHADOWFAX=<tree>` to measure a
Shadowfax tree other than the submodule. Raw samples go to `results.csv`, in
the same format as Shadowfax's `tvm-launch-latency`.

## Results

These are the debug Shadowfax firmware under QEMU (TCG), with each run pinned
to one host CPU. Values are the mean of 5 runs, and runs vary by less than 5%.

| Guest RAM | No fixes | Fixed | Zeroization share of the added time |
|-----------|----------|-------|---------------------------|
| 2 MiB     | 0.166 s  | 6.66 s | 98.3% |
| 8 MiB     | 0.190 s  | 22.2 s | 99.5% |
| 32 MiB    | 0.312 s  | 85.2 s | 99.8% |

Nearly all of the overhead is zeroing confidential memory on convert and on
reclaim. In the unoptimized build this costs about 1.2 s per MiB, so it grows
linearly with TVM memory. The other fixes (revocation, ticketing, ownership
checks) add about 0.1 s per lifecycle at 2 MiB and 0.13 s at 32 MiB.

The ticket and allocation tables add about 72 KiB of static firmware state:
1024 ticket slots × 40 B plus 1023 allocations × 32 B. This is a fixed cost
that does not depend on the number or size of TVMs.

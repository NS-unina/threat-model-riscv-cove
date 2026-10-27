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

- the two-phase ticketing protocol;
- revocation of converted memory from the untrusted domain (flaw 01);
- zeroing on convert, on reclaim and in the TSM's `destroy_tvm` (flaw 02a);
- ownership tracking and its checks in Shadowfax (flaw 02b): the owner of each
  confidential page and of each TVM, checked on reclaim, on the pages a TVM
  maps, and on every operation that names a TVM.

The baseline only checks a range's shape, lends it to the TSM on convert, and
removes it from the TSM on reclaim. Routing TVM exits back to their caller and
the `CREATE_TVM` bootstrap stay in both builds: they are needed to run a TVM,
not security fixes.

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

These are the debug Shadowfax firmware (commit `85352b6`) under QEMU (TCG),
with each run pinned to one host CPU. Values are the mean of 5 runs. Runs vary
by up to about 10%; the largest outlier is one 32 MiB run at 66 s against
about 59 s for the others.

| Guest RAM | No fixes | Fixed | Zeroization share of the added time |
|-----------|----------|-------|---------------------------|
| 2 MiB     | 0.159 s  | 4.75 s | 99.6% |
| 8 MiB     | 0.192 s  | 16.0 s | 99.9% |
| 32 MiB    | 0.314 s  | 60.1 s | 99.96% |

Nearly all of the overhead is zeroing confidential memory on convert and on
reclaim. In the unoptimized build this costs about 0.9 s per MiB zeroed, and
each byte of TVM memory is zeroed twice, so the overhead grows linearly with
TVM memory. The other fixes (revocation, ticketing, ownership tracking and
checks) add about 0.02 s per lifecycle.

The ticket, allocation and TVM-ownership tables add about 4.8 KiB of static
firmware state: 64 ticket slots × 40 B, 64 allocations × 32 B, and a 64 × 2
table of 2-byte TVM owners. These limits are fixed for small platforms and do
not depend on the number or size of TVMs.

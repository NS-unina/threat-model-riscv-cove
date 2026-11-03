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
- zeroing on convert and on reclaim, done by Shadowfax (flaw 02);
- ownership tracking and its checks in Shadowfax (flaw 03): the owner of each
  confidential page and of each TVM, checked on reclaim, on the pages a TVM
  maps, and on every operation that names a TVM.

The baseline only checks a range's shape, lends it to the TSM on convert, and
removes it from the TSM on reclaim. Routing TVM exits back to their caller and
the `CREATE_TVM` bootstrap stay in both builds: they are needed to run a TVM,
not security fixes.

## Running

Generate the Shadowfax keys once, put the RISC-V toolchain in `PATH`, then:

```sh
evaluation/overhead/measure.sh            # 5 runs each for 2 MiB to 1 GiB guests
evaluation/overhead/measure.sh 5 2 8 32   # 5 runs each for 2, 8 and 32 MiB guests
```

The script builds and measures the fixed firmware, applies `no-fixes.diff`,
measures again and reverts the patch. Both builds use the release profile
(`PROFILE=release`), which the script passes to every `make`: the launcher
boots the firmware of the profile it is given, debug by default. A run that
prints no `TVM_LIFECYCLE` result (for example a firmware panic) stops the
script. Set `SHADOWFAX=<tree>` to measure a Shadowfax tree other than the
submodule. Raw samples go to `results.csv`, in the same format as Shadowfax's
`tvm-launch-latency`.

The memory map (`device-tree.dts.in`) supports guests from 2 MiB to 1 GiB. The
Makefile sizes, for each `GUEST_RAM_SIZE`:

- the guest region, to max(32 MiB, guest RAM). A region much larger than the
  guest would leave the host so many NAPOT fragments after `CONVERT` that
  Shadowfax runs out of PMP entries;
- the page directory and the metadata region holding it. The TSM maps 4 KiB
  leaves, so 1 GiB needs 514 page-table pages; the metadata stays 512 KiB up
  to 128 MiB and grows to 4 MiB at 1 GiB.

## Results

These are the release Shadowfax firmware with Zicboz and Zicbom (commit
`40edcf9`) under QEMU (TCG), with each run pinned to one host CPU. Values are
the mean of 5 runs; the sample standard deviation of the lifecycle time is at
most 4.6% of the mean (0.3 to 4.6%), so it is not reported per row. *Zeroing*
is the time the fixes add to `CONVERT` and `RECLAIM` (guest and metadata
pages), where Shadowfax clears the memory; *share* is its fraction of the
added time. `table.py` computes these figures and the LaTeX rows from
`results.csv`.

| Guest RAM | No fixes | Fixed   | Overhead | Zeroing | Share  |
|-----------|----------|---------|----------|---------|--------|
| 2 MiB     | 0.032 s  | 0.043 s | 1.36×    | 0.009 s | 76%    |
| 8 MiB     | 0.037 s  | 0.063 s | 1.72×    | 0.024 s | 92%    |
| 32 MiB    | 0.056 s  | 0.144 s | 2.57×    | 0.086 s | 98%    |
| 64 MiB    | 0.081 s  | 0.252 s | 3.09×    | 0.169 s | 99.1%  |
| 128 MiB   | 0.133 s  | 0.468 s | 3.53×    | 0.334 s | 99.5%  |
| 256 MiB   | 0.236 s  | 0.900 s | 3.82×    | 0.664 s | 100%   |
| 512 MiB   | 0.441 s  | 1.80 s  | 4.09×    | 1.36 s  | 99.6%  |
| 1 GiB     | 0.860 s  | 3.55 s  | 4.13×    | 2.71 s  | 100%   |

Nearly all of the overhead is clearing confidential memory on convert and on
reclaim. Each pass zeroes the memory with `cbo.zero` and then writes it back
with `cbo.clean`, so that agents that bypass the cache, such as non-coherent
DMA devices, also observe zeros. A pass costs about 1.3 ms per MiB, and each
byte of TVM memory is cleared twice (on donation and on reclamation), so the
overhead grows linearly with TVM memory at about 2.6 ms per MiB. Zeroing
accounts for more than 99% of the added latency for guests with 64 MiB of
memory and upwards. The other fixes (revocation, ticketing, ownership tracking
and checks) add a roughly constant few milliseconds per lifecycle (up to about
5 ms; at 256 MiB and 1 GiB the difference is within run-to-run noise, which is
also why the share rounds to 100% there). This is why the zeroing share is
lower for small guests.

The overhead ratio levels off at about 4× because the baseline grows linearly
too: most of its lifecycle is `LOAD_GUEST` (0.83 s at 1 GiB), where the TSM
clears the guest's zero pages while building the TVM. That clearing is part of
TVM construction, not a security fix, so both builds pay it. Compared with
Zicboz alone (commit `4c3d8f4`, 2.6× at 1 GiB), the `cbo.clean` pass roughly
doubles the cost of each clearing pass.

QEMU (TCG) does not model caches: every `cbo.zero` and `cbo.clean` is an
emulated helper call with no real write-back traffic, so these times reflect
instruction overhead in emulation rather than memory traffic on hardware.

The ticket, allocation and TVM-ownership tables add about 4.8 KiB of static
firmware state: 64 ticket slots × 40 B, 64 allocations × 32 B, and a 64 × 2
table of 2-byte TVM owners. These limits are fixed for small platforms and do
not depend on the number or size of TVMs.

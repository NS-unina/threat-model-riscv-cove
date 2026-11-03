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

These are the release Shadowfax firmware with Zicboz (commit `4c3d8f4`) under
QEMU (TCG), with each run pinned to one host CPU. Values are the mean of 5
runs; the sample standard deviation of the lifecycle time is at most 3.2% of
the mean (0.2 to 3.2%), so it is not reported per row. *Zeroing* is the time
the fixes add to `CONVERT` and `RECLAIM` (guest and metadata pages), where
Shadowfax clears the memory; *share* is its fraction of the added time.

| Guest RAM | No fixes | Fixed   | Overhead | Zeroing | Share  |
|-----------|----------|---------|----------|---------|--------|
| 2 MiB     | 0.032 s  | 0.041 s | 1.27×    | 0.006 s | 69%    |
| 8 MiB     | 0.037 s  | 0.054 s | 1.46×    | 0.015 s | 87%    |
| 32 MiB    | 0.056 s  | 0.103 s | 1.84×    | 0.046 s | 97%    |
| 64 MiB    | 0.082 s  | 0.171 s | 2.10×    | 0.089 s | 99.0%  |
| 128 MiB   | 0.132 s  | 0.312 s | 2.36×    | 0.179 s | 99.3%  |
| 256 MiB   | 0.235 s  | 0.581 s | 2.47×    | 0.346 s | 100%   |
| 512 MiB   | 0.438 s  | 1.13 s  | 2.59×    | 0.693 s | 99.9%  |
| 1 GiB     | 0.847 s  | 2.23 s  | 2.63×    | 1.38 s  | 99.8%  |

Nearly all of the overhead is zeroing confidential memory on convert and on
reclaim. It costs about 0.68 ms per MiB per pass, and each byte of TVM memory
is cleared twice (on donation and on reclamation), so it grows linearly with
TVM memory at about 1.35 ms per MiB. The other fixes (revocation, ticketing,
ownership tracking and checks) add a constant 1 to 3 ms per lifecycle; this
is why the zeroing share is lower for small guests.

The overhead ratio levels off at about 2.6× because the baseline grows
linearly too: most of its lifecycle is `LOAD_GUEST` (0.82 s at 1 GiB), where
the TSM clears the guest's zero pages while building the TVM. That clearing
is part of TVM construction, not a security fix, so both builds pay it.

Under QEMU (TCG) every `cbo.zero` is an emulated helper call, so the absolute
zeroing times are an upper bound for real hardware.

The ticket, allocation and TVM-ownership tables add about 4.8 KiB of static
firmware state: 64 ticket slots × 40 B, 64 allocations × 32 B, and a 64 × 2
table of 2-byte TVM owners. These limits are fixed for small platforms and do
not depend on the number or size of TVMs.

# Reproducing the vulnerabilities

Each patch reintroduces one vulnerability on top of the pinned Shadowfax
submodule. Without a patch, the matching security test in
`shadowfax/test/security` passes. With the patch, it fails. Everything else is
the current Shadowfax.

| Flaw | Patch | Test | Fixed (main) | Vulnerable (patched) |
|------|-------|------|--------------|----------------------|
| 01: Trusted memory accessible from the untrusted domain | `01-convert-no-revoke.diff` | `converted-memory-isolation` | `[HOST] PASS: converted memory is not accessible` | `[ATTACK] FAIL: read TVM secret at 0x...` |
| 02a: Confidentiality leakage after TVM disposal | `02a-reclaim-no-sanitize.diff` | `reclaimed-memory-zero` | `[ATTACK] PASS: no reclaimed TVM data is visible` | `[ATTACK] leaked byte in ...` |
| 02b: Memory stealing | `02b-reclaim-no-ownership.diff` | `cross-domain-reclaim` | `[HOST] PASS: only the owner could reclaim its confidential pages` | `[ATTACKER] FAIL: stole host pages at 0x...` |

What each patch removes:

- **01** removes the convert TEERET step that takes the donated range out of
  the untrusted domain's regions (`compute_new_regions`). The host's PMP map
  therefore still covers the TVM memory.
- **02a** removes both clears of reclaimed memory: Shadowfax's `zeroize` on
  reclaim TEERET and the TSM's clear in `destroy_tvm`.
- **02b** removes the owner check on reclaim, both in Shadowfax (validation and
  ticket commit) and in the TSM.

## Running

Clone with submodules, put the RISC-V toolchain in `PATH`, and generate the
development keys once:

```sh
git clone --recursive https://github.com/NS-unina/threat-model-riscv-cove
cd threat-model-riscv-cove
make -C shadowfax generate-keys
```

Then run each test against the fixed and the vulnerable firmware:

```sh
attacks/run.sh 01                 # fixed: attack blocked
attacks/run.sh 01 --vulnerable    # patch applied: attack succeeds
```

`run.sh` applies the patch to the submodule, rebuilds the firmware, runs the
test, and reverts the patch on exit. A failing test prints its result and
powers QEMU off, just as a passing one does.

# Reproducing the vulnerabilities

Each patch reintroduces one vulnerability on top of the pinned Shadowfax
submodule. Without a patch, the matching security test in
`shadowfax/test/security` passes. With the patch, it fails. Everything else is
the current Shadowfax.

| Flaw | Patch | Test | Fixed (main) | Vulnerable (patched) |
|------|-------|------|--------------|----------------------|
| 01: Trusted memory accessible from the untrusted domain | `01-convert-no-revoke.diff` | `converted-memory-isolation` | `[HOST] PASS: converted memory is not accessible` | `[ATTACK] FAIL: read TVM secret at 0x...` |
| 02a: Confidentiality leakage after TVM disposal | `02a-reclaim-no-sanitize.diff` | `reclaimed-memory-zero` | `[ATTACK] PASS: no reclaimed TVM data is visible` | `[ATTACK] leaked byte in ...` |
| 02b: Cross-domain interference | `02b-no-ownership.diff` | `cross-domain-reclaim` | `[HOST] PASS: another domain could not touch the host TVM or its pages` | `[ATTACKER] FAIL: ... succeeded` for each of the three attacks |

What each patch removes:

- **01** removes the convert TEERET step that takes the donated range out of
  the untrusted domain's regions (`compute_new_regions`). The host's PMP map
  therefore still covers the TVM memory.
- **02a** removes both clears of reclaimed memory: Shadowfax's `zeroize` on
  reclaim TEERET and the TSM's clear in `destroy_tvm`.
- **02b** removes the ownership checks, which Shadowfax (the TSM driver)
  enforces before entering the TSM: the per-page owner check on reclaim
  (validation and ticket commit) and on the pages a TVM maps, and the per-TVM
  owner check on every operation that names a TVM. Another trusted domain can
  then add memory regions to the host's TVM, destroy it, and reclaim the host's
  pages.

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
evaluation/run.sh 01                 # fixed: attack blocked
evaluation/run.sh 01 --vulnerable    # patch applied: attack succeeds
```

`run.sh` applies the patch to the submodule, rebuilds the firmware, runs the
test, and reverts the patch on exit. A failing test prints its result and
powers QEMU off, just as a passing one does.

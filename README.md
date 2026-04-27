# Threat Model RISCV

This repository contains the threat model for RISC-V CoVE using STPA-SEC and DARC methodologies.

[CoVE](https://arxiv.org/pdf/2304.06167) is a non-ISA specification to enable VM-based TEE for RISC-V application class processors.

The repository is structured as follows:

- [ThreatModel_RISCV](./ThreatModel_RISCV/): contains the Capella project used to model the architecture and perform the analysis
- [attack-graphs](./attack-graphs/): contains the attack graphs files used for Mulval
- [data](./data): contains tables (in CSVs format) extracted from Capella

The target implementation is [Shadowfax](https://github.com/HiSA-Team/shadowfax). The Shadowfax platform (submodule in this repository) includes a trusted firmware leveraging OpenSBI firmware and a trusted hypervisor that can spawn bare-metal workloads.

## Reproducing vulnerabilities

Clone this repository with:

```sh
git clone --recursive https://github.com/NS-unina/threat-model-riscv-cove
```

**NOTE**: make sure to checkout the unpatched version otherwise the vulnerabilities will not appear:

```sh
cd shadowfax
git checkout d6b29ab35bb55d19316028863492016d539d446a
```

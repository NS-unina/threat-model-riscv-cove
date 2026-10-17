# Threat Model RISCV

This repository contains the threat model for RISC-V CoVE using STPA-SEC and DARC methodologies.

[CoVE](https://arxiv.org/pdf/2304.06167) is a non-ISA specification to enable VM-based TEE for RISC-V application class processors.

The repository is structured as follows:

- [stpa-sec-analysis](./stpa-sec-analysis/): contains the Capella project used to model the architecture and perform the analysis
- [attack-graphs](./attack-graphs/): contains code to generate attack-graphs using Mulval
- [shadowfax](./ahadoqfax): submodule reference to Shadowfax platform used for experiments

The target implementation is [Shadowfax](https://github.com/HiSA-Team/shadowfax). The Shadowfax platform (submodule in this repository) includes a trusted firmware and a trusted hypervisor.

## Reproducing vulnerabilities

Clone this repository including shadowfax:

```sh
git clone --recursive https://github.com/NS-unina/threat-model-riscv-cove
```

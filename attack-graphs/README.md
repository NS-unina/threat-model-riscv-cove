# Attack Graphs Generation

This directory contains the necessary files to generate attack graphs using [MulVAL](https://github.com/risksense/mulval). The generation process is automated via a script utilizing a Docker container to avoid local installation of MulVAL.

## Prerequisites

- **Docker**: Ensure Docker is installed and the daemon is running.
- **Execute Permissions**: The `run_mulval.sh` must be executable. If not, run:
  ```bash
  chmod +x run_mulval.sh
  ```

## Usage

You can generate attack graphs by running the `run_mulval.sh` script with the architecture, rules, and output directory as arguments.

### Scenario 1: Page Donation
To generate the attack graph for Scenario 1:
```bash
./run_mulval.sh -a scenario1_arch.pl -r scenario1_rules.P -o scenario1
```
The output will be generated in the `scenario1/` directory.

### Scenario 2: Memory Reclaim (CWE-459)
To generate the attack graph for Scenario 2:
```bash
./run_mulval.sh -a scenario2_arch.pl -r scenario2_rules.P -o scenario2
```
The output will be generated in the `scenario2/` directory.

### Clean Up
To remove the generated output directories:
```bash
rm -rf scenario1 scenario2
```

## How it works

1. `run_mulval.sh` takes the architecture file (`-a`), interaction rules (`-r`), and output directory (`-o`).
2. It creates the output directory (overwriting if it exists) and copies the input files into it.
3. A Docker container (`wilbercui/mulval`) is started to process the files using `graph_gen.sh`.
4. The container is removed automatically after execution, and the results are available in the specified output directory.

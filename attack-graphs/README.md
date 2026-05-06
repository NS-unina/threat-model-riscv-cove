# Attack Graphs Generation

This directory contains the necessary files to generate attack graphs using [MulVAL](https://github.com/risksense/mulval). The generation process is automated via a script and a Makefile, utilizing a Docker container to avoid local installation of MulVAL.

## Prerequisites

- **Docker**: Ensure Docker is installed and the daemon is running.
- **Execute Permissions**: The `genScript.sh` must be executable. If not, run:
  ```bash
  chmod +x genScript.sh
  ```

## Usage

You can generate attack graphs for different scenarios using the provided `Makefile`.

### Run Scenario 1
To generate the attack graph for Scenario 1 (`scenario1_arch.pl`):
```bash
make scenario1
```
The output will be generated in the `scenario1/` directory.

### Run Scenario 2
To generate the attack graph for Scenario 2 (`scenario2_arch.pl`):
```bash
make scenario2
```
The output will be generated in the `scenario2/` directory.

### Run All Scenarios
To generate graphs for all defined scenarios:
```bash
make all
```

### Clean Up
To remove the generated output directories:
```bash
make clean
```

## How it works

1. The `Makefile` calls `genScript.sh` with the appropriate architecture and rules files.
2. `genScript.sh` checks if the output directory exists and prompts for deletion.
3. A Docker container (`wilbercui/mulval`) is started in the background.
4. The necessary `.pl` and `.P` files are copied into the container.
5. The `graph_gen.sh` command is executed inside the container to produce the attack graph.
6. The container is stopped and removed automatically.

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

## Known Issues & Parser Constraints

### Rule Description Syntax
MulVAL's underlying Prolog/Java trace parser is highly sensitive to the formatting of the `rule_desc` field in `interaction_rule` rules.
- **Always use single quotes**: Use single quotes (e.g., `'my rule description'`). Double quotes (`"..."`) will cause the parser to treat the description as a list of ASCII codes, leading to runtime crashes.
- **Use spaces for stability**: The parser often incorrectly strips quotes from single-word tokens (atoms) in the trace output, which then causes syntax errors in downstream tools. Always include at least one space in your rule description (e.g., `'my rule description'`) to force the parser to treat it as a quoted string literal.
- **Avoid camelCase for labels**: Due to the same tokenization issue, avoid simple single-word camelCase labels as they are likely to be treated as unquoted Prolog atoms and stripped.


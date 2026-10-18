# Attack Graphs Generation

This directory contains the necessary files to generate attack graphs using [MulVAL](https://github.com/risksense/mulval). Generation runs in a Docker container (`wilbercui/mulval`), so MulVAL does not need to be installed locally.

## Prerequisites

- **Docker**: Ensure Docker is installed and the daemon is running.
- **Make**

## Usage

Each scenario is a pair of files, `scenario<N>_arch.pl` (architecture) and `scenario<N>_rules.P` (rules). The Makefile finds every pair automatically:

```bash
make              # generate every scenario
make scenario3    # generate one scenario
make help         # list the scenarios found
make clean        # remove all generated output directories
```

Each scenario's output, including `AttackGraph.pdf`, is written to its own `scenario<N>/` directory. A scenario is regenerated only when its architecture or rules file changes. If MulVAL finds no attack path to the goal, the target fails with a message saying so.

### Scenario 1: Page Donation
`make scenario1`

### Scenario 2: Memory Reclaim (CWE-459)
`make scenario2`

### Scenario 3: Memory Stealing (CWE-862)
A second untrusted supervisor domain, present in the TSM trust map, reclaims
confidential memory converted by another domain. The Domain Manager does not
check ownership, so the reclaimed pages are mapped into the attacker's PMP.

`make scenario3`

Removing `weaknessExist(domainManager, cwe862)` from `scenario3_arch.pl`, which
models the ownership check, leaves MulVAL with no attack path to the goal.

## Known Issues & Parser Constraints

### Rule Description Syntax
MulVAL's underlying Prolog/Java trace parser is highly sensitive to the formatting of the `rule_desc` field in `interaction_rule` rules.
- **Always use single quotes**: Use single quotes (e.g., `'my rule description'`). Double quotes (`"..."`) will cause the parser to treat the description as a list of ASCII codes, leading to runtime crashes.
- **Use spaces for stability**: The parser often incorrectly strips quotes from single-word tokens (atoms) in the trace output, which then causes syntax errors in downstream tools. Always include at least one space in your rule description (e.g., `'my rule description'`) to force the parser to treat it as a quoted string literal.
- **Avoid camelCase for labels**: Due to the same tokenization issue, avoid simple single-word camelCase labels as they are likely to be treated as unquoted Prolog atoms and stripped.


# Makefile for generating attack graphs using MulVAL
# Targets:
#   scenario1: Run MulVAL on scenario1.pl
#   scenario2: Run MulVAL on scenario2.pl
#   all: runs all scenario by default
#
# Requirements:
#   - Docker must be installed and running.
#   - The script genScript.sh must have execution permissions.

all: scenario1 scenario2

# Scenario 1: Basic architecture analysis
scenario1:
	./genScript.sh -a scenario1.pl -r interaction_rules.P -o ex1

# Scenario 2: Alternative scenario analysis
scenario2:
	./genScript.sh -a scenario2.pl -r interaction_rules.P -o ex2

# Clean: removes build artifacts
clean:
	rm -rf ex1 ex2

# Makefile for generating attack graphs using MulVAL

# Configuration
GEN = ./genScript.sh
SHELL := /bin/bash

.PHONY: all clean scenario1 scenario2

all: scenario1 scenario2

# Scenario 1: Page Donation (CWE-459)
scenario1: scenario1_arch.pl scenario1_rules.P
	@echo "Generating Attack Graph for Scenario 1..."
	rm -rf scenario1
	$(GEN) -a scenario1_arch.pl -r scenario1_rules.P -o scenario1

# Scenario 2: Memory Reclaim (CWE-459)
scenario2: scenario2_arch.pl scenario2_rules.P
	@echo "Generating Attack Graph for Scenario 2..."
	rm -rf scenario2
	$(GEN) -a scenario2_arch.pl -r scenario2_rules.P -o scenario2

# Clean build artifacts
clean:
	rm -rf scenario1 scenario2

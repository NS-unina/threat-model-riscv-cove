# Generate MulVAL attack graphs in Docker, one per scenario.
#
#   make              # every scenario<N>_arch.pl / scenario<N>_rules.P pair
#   make scenario3    # one scenario; output in scenario3/AttackGraph.pdf
#   make clean        # remove all generated output directories
#
# A scenario is rebuilt only when its architecture or rules file changes.

DOCKER       ?= docker
MULVAL_IMAGE ?= wilbercui/mulval
# MulVAL lives under /root in the image, so it runs as root; the outputs are
# handed back to the invoking user afterwards.
DOCKER_USER  ?= $(shell id -u):$(shell id -g)

SCENARIOS := $(sort $(patsubst %_arch.pl,%,$(wildcard scenario*_arch.pl)))

.PHONY: all clean help $(SCENARIOS)

all: $(SCENARIOS)

$(SCENARIOS): %: %/AttackGraph.pdf

%/AttackGraph.pdf: %_arch.pl %_rules.P
	rm -rf $*
	mkdir -p $*
	cp $^ $*/
	$(DOCKER) run --rm -v "$(CURDIR)/$*":/input -w /input $(MULVAL_IMAGE) \
		sh -c 'graph_gen.sh $(notdir $<) -v -p -r $(notdir $(word 2,$^)) --nometric; \
		status=$$?; chown -R $(DOCKER_USER) /input; exit $$status'
	@test -f $@ || { echo "$*: MulVAL found no attack path to the goal" >&2; exit 1; }

# Delete through the container too: older outputs may be owned by root.
clean:
	$(DOCKER) run --rm -v "$(CURDIR)":/work -w /work $(MULVAL_IMAGE) \
		rm -rf $(SCENARIOS)

help:
	@echo "Targets: all (default), $(SCENARIOS), clean"
	@echo "Variables: DOCKER=$(DOCKER) MULVAL_IMAGE=$(MULVAL_IMAGE)"

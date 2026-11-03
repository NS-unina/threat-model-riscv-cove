# Full TVM lifecycle benchmark, built with Shadowfax's launcher framework.
# ROOT points at the Shadowfax tree to measure (default: the submodule).
ROOT                ?= $(abspath ../../shadowfax)
LAUNCHER_NAME       := tvm-lifecycle-latency
BUILD_DIR           ?= $(ROOT)/target/$(LAUNCHER_NAME)
PAYLOAD_SRC         := guest.c
GUEST_RAM_SIZE      ?= 2097152
# Page directory (see main.c) plus the TVM state page, rounded up to a power
# of two (CONVERT needs a NAPOT range); 512K up to 64 MiB, 4M for 1 GiB.
LAUNCHER_METADATA   := $(shell n=$$(( 2 + $(GUEST_RAM_SIZE) / 2097152 )); \
	[ $$n -lt 64 ] && n=64; b=$$(( (n + 1) * 4096 )); m=524288; \
	while [ $$m -lt $$b ]; do m=$$(( m * 2 )); done; echo $$m)
RUN_QEMU_FLAGS       = $(QEMU_FLAGS) -monitor none -no-reboot

LAUNCHER_DOMAIN     := UNTRUSTED_DOMAIN
LAUNCHER_RAM_REGION := UMEM
GUEST_RAM_REGION    := UMEM_HIGH

# The guest region is sized per GUEST_RAM_SIZE (see device-tree.dts.in). The
# generated tree is rewritten only when its content changes, so the layout is
# rebuilt only when the order does.
GUEST_REGION_ORDER  := $(shell o=25; while [ $$(( 1 << o )) -lt $(GUEST_RAM_SIZE) ]; \
	do o=$$(( o + 1 )); done; echo $$o)
LAUNCHER_DTS        := $(BUILD_DIR)/device-tree.dts

$(LAUNCHER_DTS): device-tree.dts.in FORCE
	@mkdir -p $(@D)
	@sed 's/@GUEST_REGION_ORDER@/$(GUEST_REGION_ORDER)/' $< > $@.tmp
	@if cmp -s $@.tmp $@; then rm $@.tmp; else mv $@.tmp $@; fi

include $(ROOT)/guests/bare-metal/launcher.mk

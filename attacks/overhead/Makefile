# Full TVM lifecycle benchmark, built with Shadowfax's launcher framework.
# ROOT points at the Shadowfax tree to measure (default: the submodule).
ROOT                ?= $(abspath ../../shadowfax)
LAUNCHER_NAME       := tvm-lifecycle-latency
BUILD_DIR           ?= $(ROOT)/target/$(LAUNCHER_NAME)
PAYLOAD_SRC         := guest.c
GUEST_RAM_SIZE      ?= 2097152
RUN_QEMU_FLAGS       = $(QEMU_FLAGS) -monitor none -no-reboot

LAUNCHER_DOMAIN     := UNTRUSTED_DOMAIN
LAUNCHER_RAM_REGION := UMEM
GUEST_RAM_REGION    := UMEM_HIGH

include $(ROOT)/guests/bare-metal/launcher.mk

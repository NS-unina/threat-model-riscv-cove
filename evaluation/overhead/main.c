/*
 * Full TVM lifecycle latency: every COVH call from the first convert to the
 * last reclaim, so each fix (revocation, zeroing on convert and reclaim, the
 * TSM clear on destroy, ownership checks) is on the measured path.
 *
 * Output uses the tvm-launch-latency format:
 *   LATENCY,<kind>,<operation>,<cycles>,<instructions>,<time_ticks>
 */
#include <stddef.h>
#include <stdint.h>

#include "baremetal.h"
#include "baremetal_elf.h"

#define PAGE_SIZE               4096UL
#define PAGE_DIRECTORY_SIZE     (64UL * PAGE_SIZE)
#define SEGMENT_STAGING_SIZE    (64UL * 1024UL)
#define MAX_OPERATIONS          16

extern const unsigned char __guest_elf[];
extern const char __guest_elf_size[];
extern unsigned char __confidential_metadata_start[];
extern unsigned char __confidential_metadata_end[];
extern unsigned char __confidential_guest_start[];
extern unsigned char __confidential_guest_end[];

static unsigned char segment_staging[SEGMENT_STAGING_SIZE]
    __attribute__((aligned(PAGE_SIZE)));

struct counters {
    uint64_t cycle;
    uint64_t instret;
    uint64_t time;
};

static struct {
    const char *operation;
    struct counters elapsed;
} results[MAX_OPERATIONS];
static size_t result_count;

static struct counters read_counters(void)
{
    struct counters c;

    asm volatile("rdcycle %0" : "=r"(c.cycle));
    asm volatile("rdinstret %0" : "=r"(c.instret));
    asm volatile("rdtime %0" : "=r"(c.time));
    return c;
}

static void record(const char *operation, struct counters before,
                   struct counters after)
{
    results[result_count].operation = operation;
    results[result_count].elapsed = (struct counters){
        after.cycle - before.cycle,
        after.instret - before.instret,
        after.time - before.time,
    };
    result_count++;
}

static uintptr_t measured(const char *operation, uintptr_t fid,
                          uintptr_t a0, uintptr_t a1, uintptr_t a2)
{
    struct counters before = read_counters();
    struct sbiret ret = covh_call(fid, a0, a1, a2, 0, 0, 0);
    struct counters after = read_counters();

    /* RUN_VCPU returns the guest's exit reason, not an SBI error. */
    if (ret.error != 0 && fid != COVH_RUN_VCPU)
        fail(operation, ret.error);
    record(operation, before, after);
    return (uintptr_t)ret.value;
}

static void emit(const char *kind, const char *operation, struct counters c)
{
    puts("LATENCY,");
    puts(kind);
    putchar(',');
    puts(operation);
    putchar(',');
    putdec(c.cycle);
    putchar(',');
    putdec(c.instret);
    putchar(',');
    putdec(c.time);
    putchar('\n');
}

int main(void)
{
    const uintptr_t metadata = (uintptr_t)__confidential_metadata_start;
    const uintptr_t metadata_pages =
        ((uintptr_t)__confidential_metadata_end - metadata) / PAGE_SIZE;
    const uintptr_t guest = (uintptr_t)__confidential_guest_start;
    uintptr_t create_params[2] __attribute__((aligned(16)));
    const struct baremetal_elf_loader loader = {
        .elf = __guest_elf,
        .elf_size = (size_t)__guest_elf_size,
        .staging = segment_staging,
        .staging_size = sizeof(segment_staging),
        .physical_start = guest,
        .physical_end = (uintptr_t)__confidential_guest_end,
        .guest_ram_size = GUEST_RAM_SIZE,
        .premapped = 0,
        .require_ok = require_ok_silent,
        .fail = fail,
    };
    struct counters before, after, total = {0};
    uintptr_t tvm_id, entry;

    /* Same starting state for both builds; not measured. */
    clear_bytes(__confidential_metadata_start, metadata_pages * PAGE_SIZE);
    clear_bytes(__confidential_guest_start, GUEST_RAM_SIZE);

    measured("CONVERT_META_PAGES", COVH_CONVERT_PAGES, metadata, metadata_pages, 0);
    measured("CONVERT_GUEST_PAGES", COVH_CONVERT_PAGES, guest,
             GUEST_RAM_SIZE / PAGE_SIZE, 0);

    create_params[0] = metadata;
    create_params[1] = metadata + PAGE_DIRECTORY_SIZE;
    tvm_id = measured("CREATE_TVM", COVH_CREATE_TVM,
                      (uintptr_t)create_params, sizeof(create_params), 0);
    measured("ADD_MEMORY_REGION", COVH_ADD_MEMORY_REGION, tvm_id, 0,
             GUEST_RAM_SIZE);

    /* Measured and zero pages for the whole guest RAM. */
    before = read_counters();
    entry = baremetal_load_guest_elf(tvm_id, &loader);
    after = read_counters();
    record("LOAD_GUEST", before, after);

    measured("CREATE_VCPU", COVH_CREATE_VCPU, tvm_id, 0, 0);
    before = read_counters();
    require_ok_silent("FINALIZE_TVM",
        covh_call(COVH_FINALIZE_TVM, tvm_id, entry, 0, 0, 0, 0));
    after = read_counters();
    record("FINALIZE_TVM", before, after);

    /* The guest shuts down immediately; this stops the TVM. */
    measured("RUN_VCPU", COVH_RUN_VCPU, tvm_id, 0, 0);
    measured("DESTROY_TVM", COVH_DESTROY_TVM, tvm_id, 0, 0);
    measured("RECLAIM_META_PAGES", COVH_RECLAIM_PAGES, metadata, metadata_pages, 0);
    measured("RECLAIM_GUEST_PAGES", COVH_RECLAIM_PAGES, guest,
             GUEST_RAM_SIZE / PAGE_SIZE, 0);

    for (size_t i = 0; i < result_count; ++i) {
        total.cycle += results[i].elapsed.cycle;
        total.instret += results[i].elapsed.instret;
        total.time += results[i].elapsed.time;
        emit("covh", results[i].operation, results[i].elapsed);
    }
    emit("lifecycle", "TVM_LIFECYCLE", total);

    puts("[HOST] PASS: TVM lifecycle latency measured\n");
    shutdown();
}

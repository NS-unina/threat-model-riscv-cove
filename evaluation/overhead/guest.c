#include "baremetal.h"

/* Stop immediately: the benchmark measures the lifecycle, not guest work. */
int main(void)
{
    shutdown();
}

#define PROG \
    set -ex; \
    ./minicc gcc -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc gcc -ansi -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc gcc -std=c99 -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc gcc -std=c11 -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc clang -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc clang -ansi -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc clang -std=c99 -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc clang -std=c11 -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    ./minicc clang -std=c17 -pedantic -W -Wall -Werror -nostdinc -I"${0%/*}/include" -c "$0"; \
    : "$0" OK.; \
    exit 0

/* It compiles with GCC 4.8.4, GCC 7.5.0 and Clang 6.0.0:
 *
 * gcc -c
 * gcc -c -ansi -pedantic
 * gcc -c -std=c99 -pedantic
 * gcc -c -std=c11 -pedantic
 * clang -c
 * clang -c -ansi -pedantic
 * clang -c -std=c99 -pedantic
 * clang -c -std=c11 -pedantic
 * clang -c -std=c17 -pedantic
 */

#include <ctype.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <math.h>
#include <stdarg.h>
#include <stdarg_internal.h>
#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <sys/time.h>
#include <sys/types.h>
#include <time.h>
#include <unistd.h>
#include <utime.h>

#include <_preincl.h>
__LIBC_STATIC_ASSERT(stat64_size, sizeof(struct stat64) == 96);

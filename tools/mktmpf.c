/*
 * mktmpf.c: create a temporary file based on pathname template
 * by pts@fazekas.hu at Sun Jun  4 12:52:12 CEST 2023
 *
 * uClibc doesn't have mkstemps(3), and other functions for generating
 * temporary files (e.g. mkstemp(3)) doesn't let the caller specify an
 * extension.
 */

#include <errno.h>
#include <fcntl.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <unistd.h>


#ifndef __MINILIBC686__
extern char **environ;
#endif

/*
 * mix3 is a period 2**32-1 PNRG ([13,17,5]).
 *
 * !! Add it to minilibc686 with srand(...) doing 10 iterations.
 *
 * https://stackoverflow.com/a/54708697
 * https://stackoverflow.com/a/70960914
 *
 * The iteration count of 10 was chosen empirically by looking at key
 * values 0..19 and the upper 2 and 3 bits of mixes3(key). Even 6 and 7 are
 * bad, 9 is much better, 10 is good enough.
 */
static uint32_t mix3(uint32_t key) {
  key ^= (key << 13);
  key ^= (key >> 17);
  key ^= (key << 5);
  return key;
}

/* Eeither <unistd.h> or <stdlib.h> defines `extern char **environ;', so we
 * don't have to. We don't even want to, because for __MINILIBC64__ it has a
 * different symbol name (__asm__("mini_environ")).
 */
/*extern char **environ;*/

static uint32_t get_seed(uint32_t v1, uint32_t v2, uint32_t v3, uint32_t v4) {
  struct timeval tv;
  uint32_t v = mix3(mix3(v4));
  v = mix3(mix3(v)) + mix3(geteuid());
  if (!gettimeofday(&tv, NULL)) {
    v = mix3(v) + tv.tv_sec;
    v = mix3(v) + tv.tv_usec;
  }
  v = mix3(v) + (uint32_t)environ;
  v = mix3(v) + (uint32_t)environ[0];
  v = mix3(v) + v1;
  v = mix3(v) + v2;
  v = mix3(v) + v3;
  return mix3(v);
}

void u32_to_6_letters(uint32_t v, char *p) {
  unsigned u;
  unsigned char digit;
  for (u = 0; u < 6; ++u) {
    digit = v % (2 * 26);
    v /= 2 * 26;
    if (digit >= 26) digit += 'A' - 'a' - 26;
    *p++ = digit + 'a';
  }
}

#define TRY_COUNT 1024

int main(int argc, char **argv) {
  uint32_t seed;
  char *template_str, *p, *q;
  unsigned u;
  int fd;
  uint32_t pid = getpid();

  if (!argv[0] || !argv[1] || argv[2] || strcmp(argv[1], "--help") == 0) {
    fprintf(stderr, "Usage: %s <pathname-template>\n"
            "The last @@@@@@ in the template will be replaced by random.\n",
            argv[0]);
    return !argv[0] || !argv[1];  /* 0 (EXIT_SUCCESS) for--help. */
  }
  template_str = argv[1];

  for (p = template_str, q = NULL; (p = strstr(p, "@@@@@@")) != NULL; q = p++) {}
  if (!q) {
    fprintf(stderr, "fatal: missing @@@@@@ in template: %s\n", template_str);
    return 2;
  }
  seed = get_seed(argc, (uint32_t)argv, (uint32_t)argv[0], pid);
  for (u = TRY_COUNT;;) {
    u32_to_6_letters(seed, q);
    fd = open(template_str, O_RDWR | O_CREAT | O_EXCL, 0600);
    if (fd >= 0) break;
    if (errno != EEXIST) return 3;
    if (u-- == 0) return 4;  /* Too many unsuccessful tries. */
    seed = mix3(seed + pid);
  }  
  puts(template_str);
  return 0;
}

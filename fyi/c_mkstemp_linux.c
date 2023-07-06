/* Based on ../dietlibc-0.34/libcruft/mkstemp.c */

#define EEXIST 17
#define EINVAL 22

#define O_CREAT 0100
#define O_RDWR   2
#define O_EXCL  0200
#define O_NOFOLLOW 0400000

typedef unsigned uint32_t;

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

extern int mini_errno;
extern int mini_rand(void);
extern int mini_getpid(void);

int mini_open(const char *pathname, int flags, ...);

int mini_mkstemp(char *template) {
  char *tmp;
  unsigned i, hexdigit, random;
  int res;
  for (tmp = template; *tmp != '\0'; ++tmp) {}
  tmp -= 6;
  if (tmp < template) goto error;
  for (i = 0; i < 6; ++i) {
    if (tmp[i] != 'X') { error: mini_errno = EINVAL; return -1; }
  }
  for (;;) {
    random = mix3(mix3(mini_rand()) + mini_getpid());
    for (i = 0; i < 6; ++i) {  /* Adds 30 bits of randomness. */
      hexdigit = random & 0x1f;
      tmp[i] = hexdigit>9 ? hexdigit + 'a' - 10 : hexdigit + '0';
      random >>= 5;
    }
    res = mini_open(template, O_CREAT | O_RDWR | O_EXCL | O_NOFOLLOW, 0600);
    if (res >= 0 || mini_errno != EEXIST) break;
  }
  return res;
}

#define _NSIG 65
typedef void (*sighandler_t)(int);
#define SIG_ERR ((sighandler_t)-1L)
#if 0
#  define _SIGSET_WORDS (1024 / (8 * sizeof(unsigned long)))  /* diet libc, it's too large. */
#else
#  define _SIGSET_WORDS ((_NSIG - 1 + 8 * sizeof(unsigned long) + (8 * sizeof(unsigned long) - 1)) / (8 * sizeof(unsigned long)))
#endif
typedef struct {
  unsigned long sig[_SIGSET_WORDS];
} sigset_t;
struct siginfo_t;
struct sigaction {
  union {
    sighandler_t _sa_handler;
    void (*_sa_sigaction)(int, struct siginfo_t*, void*);
  } _u;
  unsigned long sa_flags;
  void (*sa_restorer)(void);
  sigset_t sa_mask;
};
#define sa_handler _u._sa_handler
#define sa_sigaction _u._sa_sigaction
#define SA_RESTART 0x10000000

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

int rt_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact, unsigned sigsetsize);

/* Limitation: always uses SA_RESTART, even if siginterrupt(sig, 1) is in effect. */
sighandler_t mini_bsd_signal(int sig, sighandler_t handler) {
  struct sigaction act, oact;
  act.sa_handler = handler;
  act.sa_flags = SA_RESTART;
  /* __sigemptyset(&act.sa_mask); */
  act.sa_mask.sig[0] = 0;
  if (_NSIG - 1 >= 8 * sizeof(unsigned long)) {
    act.sa_mask.sig[1] = 0;  /* Only 4+4 bytes to clear for i386. */
    if (_NSIG - 1 >= 2 * 8 * sizeof(unsigned long)) {
      act.sa_mask.sig[2] = 0;
      if (_NSIG - 1 >= 3 * 8 * sizeof(unsigned long)) {
        act.sa_mask.sig[3] = 0;
      }
    }
  }
  if (rt_sigaction(sig, &act, &oact, _NSIG >> 3) < 0) return SIG_ERR;
  return oact.sa_handler;
}

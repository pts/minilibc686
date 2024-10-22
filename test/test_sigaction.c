/* This test program works with or without __MINILIBC686__. */

#if defined(DO_TEST_MINILIBC686_SIGSET_T_IMPL) && !defined(__MINILIBC686__)
#  error DO_TEST_MINILIBC686_SIGSET_T_IMPL used without __MINILIBC686__
#endif

#include <signal.h>
#include <stdlib.h>
#include <unistd.h>
#ifndef DO_TEST_MINILIBC686_SIGSET_T_IMPL
#  include <string.h>  /* memcmp(...), memset(...). */
#endif

enum { exit_code0 = 2 * (SIGTERM + 100) };
static volatile int exit_code = exit_code0;

void handler(int sig) { exit_code -= (sig + 100); }

#ifdef __MINILIBC686__
  extern int raise(int sig);  /* Function under test. */
  extern int sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);  /* Function under test. */
  extern int sigemptyset(sigset_t *set);  /* Function under test. */
  extern int sigfillset(sigset_t *set);  /* Function under test. */
  extern int sigaddset(sigset_t *set, int signum);  /* Function under test. */
  extern int sigdelset(sigset_t *set, int signum);  /* Function under test. */
  extern int sigismember(const sigset_t *set, int signum);  /* Function under test. */
  typedef sighandler_t my_sighandler_t;
#  define cast_to_sighandler_t(x) (x)
#else
  typedef void (*my_sighandler_t)(int);  /* sighandler_t is a GNU extension (i.e. glibc). */
#  define cast_to_sighandler_t(x) ((void*)x)
#endif

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

static char is_sigset_eq(const sigset_t *sa, const sigset_t *sb) {
#  ifdef DO_TEST_MINILIBC686_SIGSET_T_IMPL
    return (sa->sig[0] == sb->sig[0]) &&
           (_NSIG - 1 <=     8 * sizeof(unsigned long) || sa->sig[1] == sb->sig[1]) &&
           (_NSIG - 1 <= 2 * 8 * sizeof(unsigned long) || sa->sig[2] == sb->sig[2]) &&
           (_NSIG - 1 <= 3 * 8 * sizeof(unsigned long) || sa->sig[3] == sb->sig[3]);
#  else
    return memcmp(sa, sb, (_NSIG - 1 + 7) / 8) == 0;
#  endif
}

static my_sighandler_t my_bsd_signal(int sig, my_sighandler_t handler) {
  struct sigaction act, oact;
  act.sa_handler = cast_to_sighandler_t(handler);
  act.sa_flags = SA_RESTART;
  /* Not needed for bsd_signal(...), just check that sigemptyset(...) below works. */
#  ifdef DO_TEST_MINILIBC686_SIGSET_T_IMPL
    act.sa_mask.sig[0] = -1UL;
    if (_NSIG - 1 > 8 * sizeof(unsigned long)) {
      act.sa_mask.sig[1] = -1UL;  /* Only 4+4 bytes to clear for i386. */
      if (_NSIG - 1 > 2 * 8 * sizeof(unsigned long)) {
        act.sa_mask.sig[2] = -1UL;
        if (_NSIG - 1 > 3 * 8 * sizeof(unsigned long)) {
          act.sa_mask.sig[3] = -1UL;
        }
      }
    }
#  else
    memset(&act.sa_mask, -1, sizeof(act.sa_mask));
#  endif
  sigemptyset(&act.sa_mask);
/* Not needed for bsd_signal(...), just check that sigemptyset(...) below works. */
#  ifdef DO_TEST_MINILIBC686_SIGSET_T_IMPL
    if (sig - 1 < 8 * sizeof(unsigned long)) act.sa_mask.sig[0] |= 1 << (sig - 1);
    if (64 - 1 >= 8 * sizeof(unsigned long)) act.sa_mask.sig[1] |= 1 << ((64 - 1) - sizeof(unsigned long) * 8);
#  else
    sigaddset(&act.sa_mask, sig);
    sigaddset(&act.sa_mask, 64);
#  endif
  if (sigaction(sig, &act, &oact) < 0) return SIG_ERR;
  return oact.sa_handler;
}

int main(int argc, char **argv) {
  struct sigaction oact;
  sigset_t se;
  (void)argc; (void)argv;
  if (my_bsd_signal(SIGALRM, SIG_IGN) == SIG_ERR) return 101;
  if (my_bsd_signal(SIGTERM, handler) == SIG_ERR) return 102;
  if (my_bsd_signal(SIGALRM, SIG_DFL) != SIG_IGN) return 103;
  if (my_bsd_signal(SIGALRM, SIG_IGN) != SIG_DFL) return 104;
  if (raise(SIGALRM) != 0) return 105;  /* Signal ignored. */
  if (exit_code != exit_code0) return 106;
  if (exit_code != 2 * (SIGTERM + 100)) return 99;
  if (raise(SIGTERM) != 0) return 107; /* Runs handler(SIGTERM) above. */
  if (exit_code != SIGTERM + 100) return 98;
  if (raise(SIGTERM) != 0) return 108; /* Runs handler(SIGTERM) above again. */
  if (exit_code != 0) return 97;
  if (sigaction(SIGTERM, NULL, &oact) != 0) return 109;
  if (sigemptyset(&se) != 0) return 110;
  if (sigaddset(&se, SIGTERM) != 0) return 111;
  if (sigaddset(&se, 64) != 0) return 112;
  if (sigaddset(&se, _NSIG) != -1) return 99;  /* signal number too large. */
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 113;
  if (sigdelset(&se, 64) != 0) return 114;
  if (sigdelset(&se, _NSIG) != -1) return 98;  /* signal number too large. */
  if (is_sigset_eq(&se, &oact.sa_mask)) return 115;
  if (sigdelset(&oact.sa_mask, 64) != 0) return 116;
  if (sigismember(&oact.sa_mask, 64)) return 117;
  if (sigismember(&oact.sa_mask, 63)) return 118;
  if (sigismember(&oact.sa_mask, SIGINT)) return 119;
  if (sigismember(&oact.sa_mask, _NSIG) != -1) return 98;  /* signal number too large. */
  if (!sigismember(&oact.sa_mask, SIGTERM)) return 120;
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 121;
  if (sigfillset(&oact.sa_mask) != 0) return 122;
#  ifdef DO_TEST_MINILIBC686_SIGSET_T_IMPL
    se.sig[0] = -1UL;
    if (_NSIG - 1 > 8 * sizeof(unsigned long)) {
      se.sig[1] = -1UL;  /* Only 4+4 bytes to clear for i386. */
      if (_NSIG - 1 > 2 * 8 * sizeof(unsigned long)) {
        se.sig[2] = -1UL;
        if (_NSIG - 1 > 3 * 8 * sizeof(unsigned long)) {
          se.sig[3] = -1UL;
        }
      }
    }
#  else
    memset(&se, -1, sizeof(se));
#  endif
#  ifdef __linux__  /* There are no signals 32 and 33, glibc always removes form the set, don't test for them. */
    sigdelset(&se, 32);
    sigdelset(&oact.sa_mask, 32);
    sigdelset(&se, 33);
    sigdelset(&oact.sa_mask, 33);
#  endif
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 123;
  return exit_code;  /* The signal handler changes it to 0. */
}

#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

enum { exit_code0 = 2 * (SIGTERM + 100) };
static volatile int exit_code = exit_code0;

void handler(int sig) { exit_code -= (sig + 100); }

extern int mini_raise(int sig);  /* Function under test. */
extern int mini_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);  /* Function under test. */
extern int mini_sigemptyset(sigset_t *set);  /* Function under test. */
extern int mini_sigfillset(sigset_t *set);  /* Function under test. */
extern int mini_sigaddset(sigset_t *set, int signum);  /* Function under test. */
extern int mini_sigdelset(sigset_t *set, int signum);  /* Function under test. */
extern int mini_sigismember(const sigset_t *set, int signum);  /* Function under test. */

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

static char is_sigset_eq(const sigset_t *sa, const sigset_t *sb) {
  return (sa->sig[0] == sb->sig[0]) &&
         (_NSIG - 1 <=     8 * sizeof(unsigned long) || sa->sig[1] == sb->sig[1]) &&
         (_NSIG - 1 <= 2 * 8 * sizeof(unsigned long) || sa->sig[2] == sb->sig[2]) &&
         (_NSIG - 1 <= 3 * 8 * sizeof(unsigned long) || sa->sig[3] == sb->sig[3]);
}

static sighandler_t my_bsd_signal(int sig, sighandler_t handler) {
  struct sigaction act, oact;
  act.sa_handler = handler;
  act.sa_flags = SA_RESTART;
  if (1) { /* Not needed, just check that mini_sigemptyset(...) below works. */
    act.sa_mask.sig[0] = -1UL;
    if (_NSIG - 1 >= 8 * sizeof(unsigned long)) {
      act.sa_mask.sig[1] = -1UL;  /* Only 4+4 bytes to clear for i386. */
      if (_NSIG - 1 >= 2 * 8 * sizeof(unsigned long)) {
        act.sa_mask.sig[2] = -1UL;
        if (_NSIG - 1 >= 3 * 8 * sizeof(unsigned long)) {
          act.sa_mask.sig[3] = -1UL;
        }
      }
    }
  }
  mini_sigemptyset(&act.sa_mask);
  if (1) {  /* Not needed, just for checking mini_sigaddset(...) later. */
    if (sig - 1 < sizeof(unsigned long) * 8) act.sa_mask.sig[0] |= 1 << (sig - 1);
    if (64 - 1 >= sizeof(unsigned long) * 8) act.sa_mask.sig[1] |= 1 << ((64 - 1) - sizeof(unsigned long) * 8);
  }
  if (mini_sigaction(sig, &act, &oact) < 0) return SIG_ERR;
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
  if (mini_raise(SIGALRM) != 0) return 105;  /* Signal ignored. */
  if (exit_code != exit_code0) return 106;
  if (mini_raise(SIGTERM) != 0) return 107; /* Runs handler(SIGTERM) above. */
  if (mini_raise(SIGTERM) != 0) return 108; /* Runs handler(SIGTERM) above again. */
  if (mini_sigaction(SIGTERM, NULL, &oact) != 0) return 109;
  if (mini_sigemptyset(&se) != 0) return 110;
  if (mini_sigaddset(&se, SIGTERM) != 0) return 111;
  if (mini_sigaddset(&se, 64) != 0) return 112;
  if (mini_sigaddset(&se, _NSIG) != -1) return 99;  /* signal number too large. */
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 113;
  if (mini_sigdelset(&se, 64) != 0) return 114;
  if (mini_sigdelset(&se, _NSIG) != -1) return 98;  /* signal number too large. */
  if (is_sigset_eq(&se, &oact.sa_mask)) return 115;
  if (mini_sigdelset(&oact.sa_mask, 64) != 0) return 116;
  if (mini_sigismember(&oact.sa_mask, 64)) return 117;
  if (mini_sigismember(&oact.sa_mask, 63)) return 118;
  if (mini_sigismember(&oact.sa_mask, SIGINT)) return 119;
  if (mini_sigismember(&oact.sa_mask, _NSIG) != -1) return 98;  /* signal number too large. */
  if (!mini_sigismember(&oact.sa_mask, SIGTERM)) return 120;
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 121;
  if (mini_sigfillset(&oact.sa_mask) != 0) return 122;
  se.sig[0] = -1UL;
  if (_NSIG - 1 >= 8 * sizeof(unsigned long)) {
    se.sig[1] = -1UL;  /* Only 4+4 bytes to clear for i386. */
    if (_NSIG - 1 >= 2 * 8 * sizeof(unsigned long)) {
      se.sig[2] = -1UL;
      if (_NSIG - 1 >= 3 * 8 * sizeof(unsigned long)) {
        se.sig[3] = -1UL;
      }
    }
  }
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 123;
  return exit_code;  /* The signal handler changes it to 0. */
}

#include <signal.h>
#include <stdlib.h>
#include <unistd.h>

enum { exit_code0 = 2 * (SIGTERM + 100) };
static volatile int exit_code = exit_code0;

void handler(int sig) { exit_code -= (sig + 100); }

extern int mini_raise(int sig);  /* Function under test. */
extern int mini_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);  /* Function under test. */
extern int mini_sigemptyset(sigset_t *set);  /* Function under test. */

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

static sighandler_t my_bsd_signal(int sig, sighandler_t handler) {
  struct sigaction act, oact;
  act.sa_handler = handler;
  act.sa_flags = SA_RESTART;
  if (1) { /* Not needed, just check that mini_sigemptyset(...) below works. */
    act.sa_mask.sig[0] = -1ULL;
    if (_NSIG - 1 >= 8 * sizeof(unsigned long)) {
      act.sa_mask.sig[1] = -1ULL;  /* Only 4+4 bytes to clear for i386. */
      if (_NSIG - 1 >= 2 * 8 * sizeof(unsigned long)) {
        act.sa_mask.sig[2] = -1ULL;
        if (_NSIG - 1 >= 3 * 8 * sizeof(unsigned long)) {
          act.sa_mask.sig[3] = -1ULL;
        }
      }
    }
  }
  mini_sigemptyset(&act.sa_mask);
  if (mini_sigaction(sig, &act, &oact) < 0) return SIG_ERR;
  return oact.sa_handler;
}

static is_sigset_eq(const sigset_t *sa, const sigset_t *sb) {
  return (sa->sig[0] == sb->sig[0]) &&
         (_NSIG - 1 <     8 * sizeof(unsigned long) || sa->sig[1] == sb->sig[1]) &&
         (_NSIG - 1 < 2 * 8 * sizeof(unsigned long) || sa->sig[2] == sb->sig[2]) &&
         (_NSIG - 1 < 3 * 8 * sizeof(unsigned long) || sa->sig[3] == sb->sig[3]);
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
  mini_sigemptyset(&se);
  if (!is_sigset_eq(&se, &oact.sa_mask)) return 110;
  return exit_code;  /* The signal handler changes it to 0. */
}

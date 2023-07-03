#include <signal.h>
#include <unistd.h>

enum { exit_code0 = 2 * (SIGTERM + 100) };
static volatile int exit_code = exit_code0;

void handler(int sig) { exit_code -= (sig + 100); }

extern int mini_raise(int sig);  /* Function under test. */
extern int mini_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);  /* Function under test. */

#ifdef __WATCOMC__
#  pragma warning 201 5  /* Disable the ``unreachable code'' warning. */
#endif

static sighandler_t my_bsd_signal(int sig, sighandler_t handler) {
  struct sigaction act, oact;
  act.sa_handler = handler;
  act.sa_flags = SA_RESTART;
  /* !! __sigemptyset(&act.sa_mask); */
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
  if (mini_sigaction(sig, &act, &oact) < 0) return SIG_ERR;
  return oact.sa_handler;
}

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (my_bsd_signal(SIGALRM, SIG_IGN) == SIG_ERR) return 101;
  if (my_bsd_signal(SIGTERM, handler) == SIG_ERR) return 102;
  if (my_bsd_signal(SIGALRM, SIG_DFL) != SIG_IGN) return 103;
  if (my_bsd_signal(SIGALRM, SIG_IGN) != SIG_DFL) return 104;
  if (mini_raise(SIGALRM) != 0) return 105;  /* Signal ignored. */
  if (exit_code != exit_code0) return 106;
  if (mini_raise(SIGTERM) != 0) return 107; /* Runs handler(SIGTERM) above. */
  if (mini_raise(SIGTERM) != 0) return 108; /* Runs handler(SIGTERM) above again. */
  return exit_code;  /* The signal handler changes it to 0. */
}

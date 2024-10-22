#include <signal.h>
#include <unistd.h>

void _start(void) {
  struct sigaction act, oldact;
  act.sa_handler = SIG_IGN;
  act.sa_mask.sig[0] = 1 << (SIGQUIT - 1) | 1 << (SIGFPE - 1) | 1 << (SIGRTMAX - 1);
  act.sa_flags = SA_RESTART | SA_SIGINFO;
  sigaction(SIGINT, &act, &oldact);
  sysv_signal(SIGINT, SIG_IGN);
  bsd_signal(SIGINT, SIG_IGN);
  _exit(0);
}

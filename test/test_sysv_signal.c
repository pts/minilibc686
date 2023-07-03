#include <signal.h>
#include <unistd.h>

enum { exit_code0 = (SIGTERM + 100) };
static volatile int exit_code = exit_code0;

void handler(int sig) { exit_code -= (sig + 100); }

extern int mini_raise(int sig);  /* Function under test. */
extern sighandler_t mini_sysv_signal(int signum, sighandler_t handler);  /* Function under test. */

int main(int argc, char **argv) {
  (void)argc; (void)argv;
  if (mini_sysv_signal(SIGALRM, SIG_IGN) == SIG_ERR) return 101;
  if (mini_sysv_signal(SIGTERM, handler) == SIG_ERR) return 102;
  if (mini_sysv_signal(SIGALRM, SIG_DFL) != SIG_IGN) return 103;
  if (mini_sysv_signal(SIGALRM, SIG_IGN) != SIG_DFL) return 104;
  if (mini_raise(SIGALRM) != 0) return 105;  /* Signal ignored. */
  if (exit_code != exit_code0) return 106;
  if (mini_raise(SIGTERM) != 0) return 107; /* Runs handler(SIGTERM) above. */
  if (mini_sysv_signal(SIGTERM, SIG_IGN) != SIG_DFL) return 108;  /* SYSV semantics: after call to signal handler function, it has been restored to SIG_DFL. */
  if (mini_raise(SIGTERM) != 0) return 109;  /* Signal ignored. */
  if (mini_raise(SIGTERM) != 0) return 110;  /* Signal ignored again. */
  return exit_code;  /* The signal handler changes it to 0. */
}

#ifndef _SYS_WAIT_H
#  define _SYS_WAIT_H
#  include <_preincl.h>
#  include <sys/types.h>
#  define WNOHANG 1
#  define WUNTRACED 2
#  define WSTOPPED WUNTRACED
#  define WEXITED 4
#  define WCONTINUED 8
#  define WNOWAIT 0x01000000
#  define __WNOTHREAD 0x20000000
#  define __WALL 0x40000000
#  define __WCLONE 0x80000000
#  define __WEXITSTATUS(status) (((status) & 0xff00) >> 8)
#  define WEXITSTATUS __WEXITSTATUS
#  define __WTERMSIG(status) ((status) & 0x7f)
#  define WTERMSIG __WTERMSIG
#  define __WSTOPSIG(status) __WEXITSTATUS(status)
#  define WSTOPSIG __WSTOPSIG
#  define WIFEXITED(status) (__WTERMSIG(status) == 0)
#  define WIFSIGNALED(status) (!WIFSTOPPED(status) && !WIFEXITED(status))
#  define WIFSTOPPED(status) (((status) & 0xff) == 0x7f)
#  define WCOREDUMP(status) ((status) & 0x80)
#  define W_STOPCODE(sig) ((sig) << 8 | 0x7f)
  typedef enum { P_ALL, P_PID, P_PGID } idtype_t;
  struct rusage;
  struct siginfo_t;
  __LIBC_FUNC(pid_t, wait, (int *status), __LIBC_NOATTR);
  __LIBC_FUNC(pid_t, waitpid, (pid_t pid, int *status, int options), __LIBC_NOATTR);
  __LIBC_FUNC(pid_t, wait3, (int *status, int options, struct rusage *rusage), __LIBC_NOATTR);
  __LIBC_FUNC(pid_t, wait4, (pid_t pid, int *status, int options, struct rusage *rusage), __LIBC_NOATTR);
  __LIBC_FUNC(int, waitid, (idtype_t idtype, id_t id, struct siginfo_t *infop, int options), __LIBC_NOATTR);
  __LIBC_FUNC(int, sys_waitid, (idtype_t idtype, id_t id, struct siginfo_t *infop, int options, struct rusage *usage), __LIBC_NOATTR);
#endif   /* _SYS_WAIT_H */

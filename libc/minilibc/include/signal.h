#ifndef _SIGNAL_H
#  define _SIGNAL_H
#  include <_preincl.h>
  typedef int sig_atomic_t;
  typedef void (*sighandler_t)(int);
  typedef sighandler_t sig_t;  /* For BSD. */

#  define __WANT_POSIX1B_SIGNALS__
#  define NSIG 32  /* Unused, use _NSIG instead. */

#  define SIG_DFL ((sighandler_t)0L)
#  define SIG_IGN ((sighandler_t)1L)
#  define SIG_ERR ((sighandler_t)-1L)

#  define SA_NOCLDSTOP 0x00000001
#  define SA_NOCLDWAIT 0x00000002
#  define SA_SIGINFO 0x00000004
#  define SA_RESTORER 0x04000000
#  define SA_ONSTACK 0x08000000
#  define SA_RESTART 0x10000000
#  define SA_INTERRUPT 0x20000000
#  define SA_NODEFER 0x40000000
#  define SA_RESETHAND 0x80000000
#  define SA_NOMASK SA_NODEFER
#  define SA_ONESHOT SA_RESETHAND

#  define SIG_BLOCK 0
#  define SIG_UNBLOCK 1
#  define SIG_SETMASK 2

#  if defined(__i386__) || defined(__386__) || defined(_M_IX86) || defined(__amd64__) || defined(__x86_64__) || defined(_M_X64) || defined(_M_AMD64) || defined(__X86_64__)
#    define _NSIG 65
#    define SIGHUP 1
#    define SIGINT 2
#    define SIGQUIT 3
#    define SIGILL 4
#    define SIGTRAP 5
#    define SIGABRT 6
#    define SIGIOT 6
#    define SIGFPE 8
#    define SIGKILL 9
#    define SIGSEGV 11
#    define SIGPIPE 13
#    define SIGALRM 14
#    define SIGTERM 15
#    define SIGUNUSED 31
#    define SIGBUS 7
#    define SIGUSR1 10
#    define SIGUSR2 12
#    define SIGSTKFLT 16
#    define SIGCHLD 17
#    define SIGCONT 18
#    define SIGSTOP 19
#    define SIGTSTP 20
#    define SIGTTIN 21
#    define SIGTTOU 22
#    define SIGURG 23
#    define SIGXCPU 24
#    define SIGXFSZ 25
#    define SIGVTALRM 26
#    define SIGPROF 27
#    define SIGWINCH 28
#    define SIGIO 29
#    define SIGPWR 30
#    define SIGSYS 31
#    define SIGCLD SIGCHLD
#    define SIGPOLL SIGIO
#    define SIGLOST SIGPWR
#    define SIGRTMIN 32
#    define SIGRTMAX (_NSIG-1)
    typedef struct sigset_t {
      unsigned long sig[(_NSIG - 1 + 8 * sizeof(unsigned long) + (8 * sizeof(unsigned long) - 1)) / (8 * sizeof(unsigned long))];
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
#    define sa_handler _u._sa_handler
#    define sa_sigaction _u._sa_sigaction
#  else  /* else i386 or amd64 */
#    error Unsupported architecture for <signal.h>.
#  endif  /* else i386 or amd64 */

  __LIBC_FUNC(int, raise, (int sig), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigaction, (int signum, const struct sigaction *act, struct sigaction *oldact), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigemptyset, (sigset_t *set), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigfillset, (sigset_t *set), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigaddset, (sigset_t *set, int signum), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigdelset, (sigset_t *set, int signum), __LIBC_NOATTR);
  __LIBC_FUNC(int, sigismember, (const sigset_t *set, int signum), __LIBC_NOATTR);
#  if defined(__UCLIBC__) || defined(__GLIBC__) || defined(__MINILIBC686__)  /* On __dietlibc__, don't use signal(...), it's .sa_flags are unreliable. Use sigaction(...) instead with .sa_flags == SA_RESTART. */
    __LIBC_FUNC(sighandler_t, bsd_signal,  (int signum, sighandler_t handler), __LIBC_NOATTR);  /* BSD semantics: .sa_flags == SA_RESTART. */
    __LIBC_FUNC(sighandler_t, sysv_signal, (int signum, sighandler_t handler), __LIBC_NOATTR);  /* SYSV semantics: .sa_flags == SA_RESETHAND | SA_NODEFER. */
#    ifdef __MINILIBC686__
      __LIBC_FUNC(sighandler_t, sys_signal,  (int signum, sighandler_t handler), __LIBC_NOATTR);  /* SYSV semantics: .sa_flags == SA_RESETHAND | SA_NODEFER. Linux-specific. */
#    else
#      include <features.h>
#    endif
#    if (defined(__MINILIBC686__) && defined(CONFIG_SIGNAL_BSD)) || (!defined(__MINILIBC686__) && (defined(_BSD_SOURCE) || defined(_DEFAULT_SOURCE)))  /* Not defined by default in minilibc686. */
#      ifdef __WATCOMC__
        sighandler_t signal(int signum, sighandler_t handler);
#        ifdef __MINILIBC686__
#          pragma aux signal "_mini_bsd_signal"
#        else
#          pragma aux signal "_bsd_signal"
#        endif
#      else
        sighandler_t signal(int signum, sighandler_t handler) __asm__(__LIBC_MINI "bsd_signal");
#      endif
#    endif
#    if (defined(__MINILIBC686__) && defined(CONFIG_SIGNAL_SYSV)) || (!defined(__MINILIBC686__) && !(defined(_BSD_SOURCE) || defined(_DEFAULT_SOURCE)))  /* Not defined by default in minilibc686. */
#      ifdef __WATCOMC__
        sighandler_t signal(int signum, sighandler_t handler);
#        ifdef __MINILIBC686__
#          pragma aux signal "_mini_sysv_signal"
#        else
#          pragma aux signal "_sysv_signal"
#        endif
#      else
        sighandler_t signal(int signum, sighandler_t handler) __asm__(__LIBC_MINI "sysv_signal");
#      endif
#    endif
#  endif
#endif  /* _SIGNAL_H */

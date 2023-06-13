# Linux i386 syscalls

General notes:

* Not all syscalls and libc functions listed here have been implemented yet
  in minilibc686.

* All syscall numbers for i386:
  https://github.com/torvalds/linux/blob/master/arch/x86/entry/syscalls/syscall_32.tbl

* Most syscall function declarations, with argument types:
  https://github.com/torvalds/linux/blob/master/include/linux/syscalls.h

* See https://man7.org/linux/man-pages/man2/syscalls.2.html for a list of
  Linux syscalls and the kernel version in which they appeared.

* Quote https://man7.org/linux/man-pages/man2/syscalls.2.html from Although
  slots are reserved for them in the system call table, the following system
  calls are not implemented in the standard kernel: afs_syscall(2), break(2),
  ftime(2), getpmsg(2), gtty(2), idle(2), lock(2), madvise1(2), mpx(2),
  phys(2), prof(2), profil(2), putpmsg(2), security(2), stty(2), tuxcall(2),
  ulimit(2), and vserver(2) (see also unimplemented(2)). However, ftime(3),
  profil(3), and ulimit(3) exist as library routines. The slot for phys(2) is
  in use since kernel 2.1.116 for umount(2); phys(2) will never be
  implemented. The getpmsg(2) and putpmsg(2) calls are for kernels patched to
  support STREAMS, and may never be in the standard kernel.

* The timerfd_create function in diet libc was fixed by pts. It called
  SYS_timerfd_create with the wrong API.

* The sys_... function always correspons to the syscall with number SYS_....
  Other functions can be ambiguous.

Syscall aliases in libc:

* mq_setattr: alias to mq_getsetattr
* getrlimit: alias to sys_ugetrlimit (SuS compliant getrlimit; sys_getrlimit isn't SuS-compliant)
* chown: alias to sys_chown32
* fchown: alias to sys_fchown32
* getegid: alias to sys_getegid32
* geteuid: alias to sys_geteuid32
* getgid: alias to sys_getgid32
* getgroups: alias to sys_getgroups32
* getresgid: alias to sys_getresgid32
* getuid: alias to sys_getuid32
* lchown: alias to sys_lchown32
* setfsgid: alias to sys_setfsgid32
* setfsuid: alias to sys_setfsuid32
* setgid: alias to sys_setgid32
* setgroups: alias to sys_setgroups32
* setregid: alias to sys_setregid32
* setresgid: alias to sys_setresgid32
* setreuid: alias to sys_setreuid32
* setresuid: alias to sys_setresuid32
* getresuid: alias to sys_getresuid32
* _exit: alias to sys_exit
* llseek:  alias to sys_llseek; a more useful libc wrapper (with direct off64_t argument) is lseek64
* _llseek: alias to sys_llseek; a more useful libc wrapper (with direct off64_t argument) is lseek64
* posix_fadvise: alias to fadvise64_64
* klogctl: alias to sys_syslog
* select: alias to sys_newselect (available since Linux 2.0)

libc wrappers:

* mq_getattr: wrapper around mq_getsetattr
* !! madvise1: fake ENOSYS
* !! phys: fake ENOSYS
* !! security: fake ENOSYS
* !! tuxcall: fake ENOSYS
* !! fattach: fake ENOSYS
* !! fdetach: fake ENOSYS
* !! getmsg: fake ENOSYS
* !! putmsg: fake ENOSYS
* !! isastream: fake ENOSYS
* mmap: wrapper around sys_mmap2; use sys_mmap2 directly for file offsets larger than 31 bits
* lseek64: wrapper around sys_llseek, copies to a struct
* () ipc: common entry point for:
* msgctl: diet libc wrapper for ipc
* msgget: diet libc wrapper for ipc
* msgrcv: diet libc wrapper for ipc
* msgsnd: diet libc wrapper for ipc
* semctl: diet libc wrapper for ipc
* semget: diet libc wrapper for ipc
* semop: diet libc wrapper for ipc
* semtimedop: diet libc wrapper for ipc
* shmat: diet libc wrapper for ipc
* shmctl: diet libc wrapper for ipc
* shmdt: diet libc wrapper for ipc
* shmget: diet libc wrapper for ipc
* () socketcall: common entry point for: accept accept4 bind connect getpeername getsockname getsockopt listen recv recvfrom recvmmsg recvmsg send sendmmsg sendmsg sendto setsockopt shutdown socket socketpair
  Linux 4.3 (released on 2015-11-01) added direct system calls on top of socketcall, to facilitate seccomp(2) filtering
* accept: diet libc wrapper for socketcall
* accept4: diet libc wrapper for socketcall
* bind: diet libc wrapper for socketcall
* connect: diet libc wrapper for socketcall
* getpeername: diet libc wrapper for socketcall
* getsockname: diet libc wrapper for socketcall
* getsockopt: diet libc wrapper for socketcall
* listen: diet libc wrapper for socketcall
* recv: diet libc wrapper for socketcall
* recvfrom: diet libc wrapper for socketcall
* recvmmsg: diet libc wrapper for socketcall
* recvmsg: diet libc wrapper for socketcall
* send: diet libc wrapper for socketcall
* sendmmsg: diet libc wrapper for socketcall
* sendmsg: diet libc wrapper for socketcall
* sendto: diet libc wrapper for socketcall
* setsockopt: diet libc wrapper for socketcall
* shutdown: diet libc wrapper for socketcall
* socket: diet libc wrapper for socketcall
* socketpair: diet libc wrapper for socketcall
* sched_getaffinity: diet libc wrapper around sys_sched_getaffinity
* sysctl: diet libc wrapper around sys_sysctl, copies to a struct (like lseek64)
* signalfd: diet libc wrapper around signalfd4
* fcntl64: diet libc around sys_fcntl64, does some ABI transformations
* eventfd: diet libc wrapper around sys_eventfd2, with fallback to sys_eventfd
* syslog: a libc function talking to syslogd, unrelated to sys_slog; minilibc686 and diet libc doesn't have it, uClibc and EGLIBC have it
* ftruncate64: diet libc wrapper for sys_ftruncate64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to fstat)
* truncate64: diet libc wrapper for sys_truncate64  (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to fstat)
* fstat64: diet libc wrapper for sys_fstat64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to fstat, fstat64 is since Linux 2.4)
* lstat64: diet libc wrapper for sys_lstat64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to lstat)
* stat64: diet libc wrapper for sys_lstat64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to stat)
* sendfile64: diet libc wrapper for sys_sendfile64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to sendfile)
* statfs64: diet libc wrapper for sys_statfs64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to statfs)
* fstatfs64: diet libc wrapper for sys_fstatfs64 (WANT_LARGEFILE_BACKCOMPAT by default, with fallback to fstatfs)
* getpriority: diet libc wrapper for sys_getpriority, it reverses the prioirty of positive values
* sigaction: diet libc wrapper, it uses rt_sigaction instead of sys_sigaction, with larger sigset_t
* sigpending: diet libc wrapper, it uses rt_sigpending instead of sys_sigpending
* sigprocmask: diet libc wrapper, it uses rt_sigprocmask instead of sys_sigprocmask
* sigsuspend: diet libc wrapper, it uses rt_sigsuspend instead of sys_sigsuspend
* reboot: diet libc wrapper around sys_reboot, adds some magic numbers to registers
* getcwd: diet libc wrapper around sys_getcwd, adds terminating NUL, and checks for zero buffer size
* ptrace: diet libc wrapper around sys_ptrace, does some simple ABI transformations
* brk: a libc function calling sys_brk, but provides a different API

Syscall functions with the sys_ prefix:

* sys_ipc
* sys_mmap
* sys_mmap2
* sys_select
* sys_newselect
* sys_exit
* sys_eventfd
* sys_fcntl64
* sys_reboot
* sys_signalfd
* sys_brk
* sys_getcwd
* sys_getpriority
* sys_sigaction
* sys_sigpending
* sys_sigprocmask
* sys_sigsuspend
* sys_ptrace
* sys_sched_getaffinity
* sys_syslog
* sys_llseek
* sys_getrlimit
* sys_ugetrlimit
* sys_sysctl

Syscall functions with the sys_ prefix, with a 32-bit and a 16-bit variant:

* sys_chown
* sys_chown32
* sys_fchown
* sys_fchown32
* sys_getegid
* sys_getegid32
* sys_geteuid
* sys_geteuid32
* sys_getgid
* sys_getgid32
* sys_getgroups, uses gid16_t[]
* sys_getgroups32
* sys_getresgid
* sys_getresgid32
* sys_getresuid
* sys_getresuid32
* sys_getuid
* sys_getuid32
* sys_lchown
* sys_lchown32
* sys_setfsgid
* sys_setfsgid32
* sys_setfsuid
* sys_setfsuid32
* sys_setgid
* sys_setgid32
* sys_setgroups, uses gid16_t[]
* sys_setgroups32
* sys_setregid
* sys_setregid32
* sys_setresgid
* sys_setresgid32
* sys_setresuid
* sys_setresuid32
* sys_setreuid
* sys_setreuid32
* sys_setuid
* sys_setuid32

Syscall functions without a prefix, with a diet libc wrapper:

* truncate64
* ftruncate64
* eventfd2
* pread64
* pwrite64
* signalfd4
* access
* add_key
* adjtimex
* alarm
* bdflush
* capget
* capset
* chdir
* chmod
* chroot
* clock_getres
* clock_gettime
* clock_nanosleep
* clock_settime
* close
* create_module
* delete_module
* dup
* dup2
* dup3
* epoll_create
* epoll_create1
* epoll_ctl
* epoll_wait
* execve
* faccessat
* fadvise64
* fadvise64_64
* fallocate
* fanotify_init
* fanotify_mark
* fchdir
* fchmod
* fchmodat
* fchownat
* fcntl
* fdatasync
* fgetxattr
* flistxattr
* flock
* fork
* fremovexattr
* fsetxattr
* fstat
* fstat64
* fstatat64
* fstatfs
* fstatfs64
* fsync
* ftruncate
* futex
* futimesat
* get_mempolicy
* get_thread_area
* getdents
* getdents64
* getitimer
* getpgid
* getpid
* getppid
* getrandom
* getrusage
* getsid
* gettid
* gettimeofday
* getxattr
* init_module
* inotify_add_watch
* inotify_init
* inotify_init1
* inotify_rm_watch
* io_cancel
* io_destroy
* io_getevents
* io_setup
* io_submit
* ioctl
* ioperm
* iopl
* keyctl
* kill
* lgetxattr
* link
* linkat
* listxattr
* llistxattr
* lremovexattr
* lseek
* lsetxattr
* lstat
* lstat64
* madvise
* mbind
* memfd_create
* mincore
* mkdir
* mkdirat
* mknod
* mknodat
* mlock
* mlock2
* mlockall
* mount
* mprotect
* mq_getsetattr
* mq_notify
* mq_open
* mq_timedreceive
* mq_timedsend
* mq_unlink
* mremap
* msync
* munlock
* munlockall
* munmap
* nanosleep
* open
* openat
* pause
* personality
* pipe
* pipe2
* pivot_root
* poll
* prctl
* preadv
* pwritev
* query_module
* quotactl
* read
* readahead
* readlink
* readlinkat
* readv
* remap_file_pages
* removexattr
* rename
* renameat
* request_key
* rmdir
* rt_sigaction
* rt_sigpending
* rt_sigprocmask
* rt_sigqueueinfo
* rt_sigreturn
* rt_sigsuspend
* rt_sigtimedwait
* sched_get_priority_max
* sched_get_priority_min
* sched_getparam
* sched_getscheduler
* sched_rr_get_interval
* sched_setaffinity
* sched_setparam
* sched_setscheduler
* sched_yield
* sendfile
* sendfile64
* set_mempolicy
* set_thread_area
* set_tid_address
* setdomainname
* sethostname
* setitimer
* setns
* setpgid
* setpriority
* setrlimit
* setsid
* settimeofday
* setxattr
* sigaltstack
* splice
* stat
* stat64
* statfs
* statfs64
* stime
* swapoff
* swapon
* symlink
* symlinkat
* sync
* syncfs
* sysfs
* sysinfo
* tee
* tgkill
* time
* timer_create
* timer_delete
* timer_getoverrun
* timer_gettime
* timer_settime
* timerfd_create
* timerfd_gettime
* timerfd_settime
* times
* tkill
* truncate
* umask
* umount
* umount2
* uname
* unlink
* unlinkat
* ustat
* utime
* utimensat
* utimes
* vhangup
* vmsplice
* wait4
* waitpid
* write
* writev

Syscalls without a diet libc wrapper, with the sys_ prefix:

* sys_readdir: superseded by getdents, libc wrapper typically exits
* sys_signal: libc wrapper typically exists
* sys_socketcall
* sys_oldstat
* sys_oldfstat
* sys_oldlstat
* sys_oldolduname
* sys_olduname
* sys_vm86old: it was renamed in some libcs to vm86old
* sys_vm86: it was renamed in some libcs from vm86old
* sys_ftime: unimplemented, use libc ftime(3) instead
* sys_profil: unimplemented, use libc profil(3) instead
* sys_ulimit: unimplemented, use libc ulimit(3) instead
* sys_afs_syscall: unimplemented
* sys_break: unimplemented
* sys_getpmsg: unimplemented
* sys_putpmsg: unimplemented
* sys_stty: unimplemented
* sys_gtty: unimplemented
* sys_idle: unimplemented
* sys_lock: unimplemented
* sys_mpx: unimplemented
* sys_prof: unimplemented
* sys_vserver: unimplemented

Syscall direct socketcall functions, without a dietlibc wrapper:

* (there is no sys_accept)
* (there is no sys_recv)
* sys_accept4
* sys_bind
* sys_connect
* sys_getpeername
* sys_getsockname
* sys_getsockopt
* sys_listen
* sys_recvfrom
* sys_recvmmsg
* sys_recvmsg
* sys_sendmmsg
* sys_sendmsg
* sys_sendto
* sys_setsockopt
* sys_shutdown
* sys_socket
* sys_socketpair

Syscall direct IPC functions, without a dietlibc wrapper:

* (there is no sys_semop)
* (there is no sys_semtimedop)
* sys_msgctl
* sys_msgget
* sys_msgrcv
* sys_msgsnd
* sys_semctl
* sys_semget
* sys_semop
* sys_semtimedop
* sys_shmat
* sys_shmctl
* sys_shmdt
* sys_shmget

Syscalls without a diet libc wrapper, without the sys_prefix:

* creat
* nice
* acct
* getpgrp
* sgetmask
* ssetmask
* uselib
* sigreturn
* clone
* modify_ldt
* get_kernel_syms
* nfsservctl
* vfork
* set_zone_reclaim
* exit_group
* lookup_dcookie
* kexec_load
* waitid
* ioprio_set
* ioprio_get
* migrate_pages
* pselect6
* ppoll
* unshare
* set_robust_list
* get_robust_list
* sync_file_range
* move_pages
* getcpu
* epoll_pwait
* rt_tgsigqueueinfo
* perf_event_open
* prlimit64
* name_to_handle_at
* open_by_handle_at
* clock_adjtime
* process_vm_readv
* process_vm_writev
* kcmp
* finit_module
* sched_setattr
* sched_getattr
* renameat2
* seccomp
* bpf
* execveat
* userfaultfd
* membarrier
* copy_file_range
* preadv2
* pwritev2
* pkey_mprotect
* pkey_alloc
* pkey_free
* statx
* arch_prctl
* io_pgetevents
* rseq
* clock_gettime64
* clock_settime64
* clock_adjtime64
* clock_getres_time64
* clock_nanosleep_time64
* timer_gettime64
* timer_settime64
* timerfd_gettime64
* timerfd_settime64
* utimensat_time64
* pselect6_time64
* ppoll_time64
* io_pgetevents_time64
* recvmmsg_time64
* mq_timedsend_time64
* mq_timedreceive_time64
* semtimedop_time64
* rt_sigtimedwait_time64
* futex_time64
* sched_rr_get_interval_time64
* pidfd_send_signal
* io_uring_setup
* io_uring_enter
* io_uring_register
* open_tree
* move_mount
* fsopen
* fsconfig
* fsmount
* fspick
* pidfd_open
* clone3
* close_range
* openat2
* pidfd_getfd
* faccessat2
* process_madvise
* epoll_pwait2
* mount_setattr
* quotactl_fd
* landlock_create_ruleset
* landlock_add_rule
* landlock_restrict_self
* memfd_secret
* process_mrelease
* futex_waitv
* set_mempolicy_home_node

__END__

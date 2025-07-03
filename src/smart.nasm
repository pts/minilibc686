;
; written by pts@fazekas.hu at Tue May 30 13:24:01 CEST 2023
; Compile to i386 ELF .o object: nasm -DUNDEFSYMS= -O0 -w+orphan-labels -f elf -o smart.o smart.nasm
;
; This source file implements smart linking. It is compiled by `minicc
; -msmart' as `nasm -O0 -f elf -DUNDEFSYMS=...'. Example:
; ``-DUNDEFSYMS=mini_write,mini_exit'.
;
; This source file should define and export (via `global ...') optimized
; implementations of some of UNDEFSYMS symbols. It's OK if it doesn't define
; all of them: the regular libc.$ARCH.a will be consulted.
;

; --- NASM magic infrastructure.

%ifndef UNDEFSYMS
  %error Expecting UNDEFSYMS from minicc -msmart.
  times 1/0 nop
%endif
%ifidn __OUTPUT_FORMAT__, bin  ; When called by minicc, it's elf.
  %macro __smart_extern 1
  %endmacro
%else
  %macro __smart_extern 1
    extern %1
  %endmacro
%endif

bits 32
;%ifdef CONFIG _I386
  cpu 386
;%else
;  cpu 686
;%endif

%define ALIASES
; Makes %1 an alias of %2.
%macro _alias 2
  %define __ALIAS_%1 %2
  %xdefine ALIASES ALIASES,%1
%endmacro

%macro _define_need_alias 1
  %define __NEED_%1
%endmacro

%macro _define_needs 0-*
  %rep %0
    %define __NEED_%1
    %rotate 1
  %endrep
  %undef __NEED_
%endmacro

%macro _need_aliases 0-*
  %rep %0
    %ifdef __NEED_%1
      _define_need_alias __ALIAS_%1  ; This will expand __ALIAS_%1 first, and define __NEED_mini_unlink instead of __ALIAS_mini_remove.
    %endif
    %rotate 1
  %endrep
%endmacro

%define SYSCALLS

; Usage: _syscall <name>[, <name2>...], <number>
;
; If the syscall has at least 4 arguments, use _syscall_456 instead,
; otherwise the program will crash.
%macro _syscall 2-*
  %rep %0-2
    %ifdef __NEED_mini_%1
      %define __NEED_mini_%2
    %endif
    %rotate 1
  %endrep
  %define LASTSYSNAME mini_%1  ; The last syscall name.
  ;
  %ifdef __NEED_mini_%1  ; Since we've just defined the other __NEED_()s, this will be true if any of them is needed.
    %rotate 2
    %rep %0-2
      %xdefine __ALIAS_mini_%1 LASTSYSNAME
      %xdefine ALIASES ALIASES,mini_%1
      %rotate 1
    %endrep
    ;
    %define __NRM_mini_%1 %2  ; Save syscall number.
    %xdefine SYSCALLS SYSCALLS,mini_%1  ; Remember syscall name for _emit_syscalls.
    %if %2>255
      %define __NEED_mini_syscall3_RP1
    %else
      %define __NEED_mini_syscall3_AL
    %endif
  %else
    %rotate 2
    %define __NRM_mini_%1 %2  ; Save syscall number.
  %endif
%endmacro

; Usage: _syscall_456 <name>[, <name2>...], <number>
;
; If the syscall has less than 4 arguments, _syscall also works, and is more
; space-efficient, so please use that.
%macro _syscall_456 2-*
  %rep %0-2
    %ifdef __NEED_mini_%1
      %define __NEED_mini_%2
    %endif
    %rotate 1
  %endrep
  %define LASTSYSNAME mini_%1  ; The last syscall name.
  ;
  %ifdef __NEED_mini_%1  ; Since we've just defined the other __NEED_()s, this will be true if any of them is needed.
    %rotate 2
    %rep %0-2
      %xdefine __ALIAS_mini_%1 LASTSYSNAME
      %xdefine ALIASES ALIASES,mini_%1
      %rotate 1
    %endrep
    ;
    %define __NRM_mini_%1 %2  ; Save syscall number.
    %xdefine SYSCALLS SYSCALLS,mini_%1  ; Remember syscall name for _emit_syscalls.
    %if %2>255
      %define __NEED_mini_syscall6_RP1
    %else
      %define __NEED_mini_syscall6_AL
    %endif
  %endif
%endmacro

;%define LAST_SC123EAX ...  ; Will be defined by syscall36_EAX.
;%define LAST_SC123AL  ...  ; Will be defined by syscall36_AL.
%macro _emit_syscalls 0-*
  ; TODO(pts): Put some extra syscalls in front of syscall36_EAX, to save 3 bytes on the first `jmp strict near'. This is complicated.
  %rep %0
    %ifnidn %1_, _  ; `%ifnidn $1,' doesn't work, so we append `_'.
      global %1
      %1:
      %if __NRM_%1>255
        mov eax, __NRM_%1
        %if $+2-($$+LAST_SC36EAX)>0x80  ; This check doesn't work in Yasm.
          %assign LAST_SC36EAX $-$$  ; Subsequent jumps can jump here, and be 2 bytes only, rather than 5 bytes.
          jmp strict near syscall36_EAX
        %else
          jmp strict short $$+LAST_SC36EAX
        %endif
      %else
        mov al, __NRM_%1
        %if $+2-($$+LAST_SC36AL)>0x80  ; This check doesn't work in Yasm.
          %assign LAST_SC36AL $-$$  ; Subsequent jumps can jump here, and be 2 bytes only, rather than 5 bytes.
          jmp strict near syscall36_AL
        %else
          jmp strict short $$+LAST_SC36AL  ; `short' to make sure that the jump is 2 bytes. This lets us define about 50 different syscalls in this file.
        %endif
      %endif
    %endif
    %rotate 1
  %endrep
%endmacro

; Makes %2 a dependency of %1 by defining __NEED_%2 if __NEED_%1 is defined.
; If A depends on B, and B depends on C, then `_need A, B' and `_need B, C'
; is the correct call order.
%macro _need 2
  %ifdef __NEED_%1
    %define __NEED_%2
  %endif
%endmacro

%macro _define_alias_syms 0-*
  %rep %0
    %ifdef __NEED_%1
      global %1
      %1: equ __ALIAS_%1
    %endif
    %rotate 1
  %endrep
%endmacro

%macro _call_extern_if_needed 1
  %ifdef __NEED_%1
    __smart_extern %1
    call %1
  %endif
%endmacro

%macro _call_if_needed 1
  %ifdef __NEED_%1
    call %1
  %endif
%endmacro

; ---

_define_needs UNDEFSYMS  ; Must be called before _need and _alias.
;
;_alias mini_remove, mini_unlink  ; `remove' defined below.
; The dependencies below must be complete for each system call defined in
; src/start_stdio_medium_linux.nasm (read(2), write(2), open(2), close(2),
; lseek(2), ioctl(2)), otherwise there will be duplicate symbols.
;
; Definition order: If C needs B and B needs A (transitive), then declar
; `_need C, B' first, then `_need B, A'.
;
; How to resolve dependency errors manually (!! TODO(pts): Better.):
;
; 1. Check that `-mno-smart' is a workaround. If not, then it's not a dependency error.
; 2. Example useless dependency error reported by GNU ld(1):
;    libc/minilibc/libc.i686.a(start_stdio_medium_linux.o): In function `mini_exit':
;    src/start_stdio_medium_linux.nasm:(.text+0x21): multiple definition of `mini_exit'
;    ....smart.o:/home/pts/prg/trusty.i386.dir/tmp/minilibc686/libc/minilibc/smart.nasm:(.text+0x26): first defined here
;    libc/minilibc/libc.i686.a(start_stdio_medium_linux.o): In function `mini__exit':
;    ...
;    libc/minilibc/libc.i686.a(start_stdio_medium_linux.o): In function `mini_ioctl':
;    src/start_stdio_medium_linux.nasm:(.text+0x66): multiple definition of `mini_ioctl'
;    ....smart.o:/home/pts/prg/trusty.i386.dir/tmp/minilibc686/libc/minilibc/smart.nasm:(.text+0x67): first defined here
; 3. Removed start_stdio_medium_linux.o temporarily from build.sh in `LIB_OBJS_SPECIAL_ORDER="stdio_medium_flush_opened.o start_stdio_medium_linux.o"'.
; 4.  Now GNU ld(1) reports the real error:
;    .../libc/minilibc/libc.i686.a(stdio_medium_fseek.o): In function `mini_fseek.4':
;    src/stdio_medium_fseek.nasm:(.text+0x52): undefined reference to `mini_lseek'
; 5.  Fixed by adding `_need mini_rewind, mini_fseek' (mini_rewind was guessed), and
;    then running `./build.sh'.
; 6. Changed `./build.sh' back and rerun `./build.sh'.
;
; TODO(pts): Autogenerate these dependencies.
_need _start, mini__start
_need mini_getchar, mini_stdin
_need mini_getchar, mini_fgetc
_need mini_gets, mini_stdin
_need mini_scanf, mini_stdin
_need mini_vscanf, mini_stdin
_need mini_putchar, mini_stdout
_need mini_putchar, mini_putchar_RP3
_need mini_putchar_RP3, mini_stdout
_need mini_putchar_RP3, mini_fputc_RP3
_need mini_puts, mini_stdout
_need mini_printf, mini_stdout
_need mini_vprintf, mini_stdout
_need mini_vsprintf, mini_sprintf
_need mini_vsnprintf, mini_snprintf
;_need mini_printf, mini_vfprintf  ; Inlined.
_need mini_printf, mini___M_writebuf_relax_RP1
_need mini_printf, mini___M_writebuf_unrelax_RP1
_need mini_printf, mini_fputc_RP3
_need mini_sprintf, mini___M_vfsprintf
_need mini_snprintf, mini___M_vfsprintf
_need mini_vprintf, mini_vfprintf
_need mini_fprintf, mini___M_writebuf_relax_RP1
_need mini_fprintf, mini___M_writebuf_unrelax_RP1
_need mini_fprintf, mini_fputc_RP3
_need mini_vfprintf, mini___M_writebuf_relax_RP1
_need mini_vfprintf, mini___M_writebuf_unrelax_RP1
_need mini_vfprintf, mini_fputc_RP3
_need mini_stdin,  mini___M_start_isatty_stdin
_need mini_stdout, start.mini___M_start_isatty_stdout
_need mini_stdout, start.mini___M_start_flush_stdout
_need mini_fopen, mini___M_start_flush_opened
_need mini_freopen, mini___M_start_flush_opened
_need mini_fdopen, mini___M_start_flush_opened
_need mini___M_start_isatty_stdin, mini_isatty
;_need start.mini___M_start_isatty_stdout, mini_isatty  ; Inlined.
_need start.mini___M_start_isatty_stdout, mini_syscall3_AL
_need mini___M_start_isatty_stdout, mini_isatty
_need mini_isatty, mini_ioctl
_need start.mini___M_start_flush_stdout, mini_fflush
_need mini___M_start_flush_stdout, mini_fflush
_need mini___M_start_flush_opened, mini_fflush
_need mini___M_start_flush_opened, mini___M_global_files
_need mini___M_start_flush_opened, mini___M_global_files_end
_need mini___M_start_flush_opened, mini___M_global_file_bufs
_need mini_rewind, mini_fseek
_need mini_freopen, mini___M_jmp_freopen_low
_need mini_freopen, mini_fclose
_need mini_fclose, mini_close
_need mini_fclose, mini_fflush
_need mini_fwrite, mini_fflush
_need mini_fseek, mini_fflush
_need mini_fseek, mini_lseek
_need mini_puts, mini_fputs
_need mini_fputs, mini_fwrite
_need mini_putc, mini_fputc_RP3
_need mini_fputc, mini_fputc_RP3
_need mini_fputc_RP3, mini_write
_need mini_fputc_RP3, mini_fflush
_need mini_fflush, mini_write
;_need mini_fflush, mini___M_discard_buf_RP3  ; Not needed because CONFIG_FLUSH_INLINE_DISCARD_BUF.
_need mini_getc, mini_fread
_need mini_fgetc, mini_fread
_need mini_fgetc_RP3, mini_fread
_need mini_fgets, mini_fread
_need mini___M_fgetc_fallback_RP3, mini_fread
_need mini_fread, mini_read
_need mini_fread, mini___M_discard_buf_RP3
_need mini_fopen, mini___M_discard_buf_RP3
_need mini_fseek, mini___M_discard_buf_RP3
_need mini_exit, mini__exit
_need mini_fopen, mini_open
_need mini___M_jmp_freopen_low, mini_open
_need mini___M_jmp_freopen_low, mini___M_discard_buf_RP3
_need mini_open_largefile, mini_open
_need mini_fclose, mini_close
_need mini_mq_getattr, mini_syscall3_RP1
_need mini_malloc_simple_unaligned, mini_syscall3_AL
_need mini_munmap, mini_syscall3_AL
_need mini_mmap, mini___M_jmp_pop_ebx_syscall_return
_need mini_lseek64_set_RP3, mini___M_jmp_pop_ebx_syscall_return
_need mini_bsd_signal, mini_syscall3_AL
_need mini_sigaction, mini___M_jmp_pop_ebx_syscall_return
_need mini_wait, mini___M_jmp_pop_ebx_syscall_return
_need mini_wait3, mini___M_jmp_pop_ebx_syscall_return
_need mini_waitid, mini___M_jmp_pop_ebx_syscall_return
_need mini_raise, mini___M_jmp_syscall_pop_ebx_return
_need mini_getenv, mini_environ  ; Without this, the linker failes with duplicate symbols in *.smart.o and src/stdio_medium_linux.o. (It's a misleading error message, it doesn't mention mini_getenv or mini_environ). TODO(pts): Document this.
_need mini_getopt, mini_write
_need mini_execvp, mini_environ
_need mini_execvp, mini_errno
_need mini_execvp, mini_execve
_need mini_mkstemp, mini_open
_need mini_mkstemp, mini_errno
_need mini_mkstemp, mini_rand
_need mini_errno, .bss
_need mini_environ, .bss
_need mini_stdout, .data
_need mini_stdout, .bss
;
%ifdef __NEED_mini___M_vfsprintf
  %ifdef __NEED_mini_vfprintf
    %undef __NEED_mini___M_vfsprintf  ; mini_vfprintf(...) will do it instead.
  %endif
  %ifdef __NEED_mini_printf
    %undef __NEED_mini___M_vfsprintf  ; mini_vfprintf(...) will do it instead.
  %endif
  %ifdef __NEED_mini_fprintf
    %undef __NEED_mini___M_vfsprintf  ; mini_vfprintf(...) will do it instead.
  %endif
%endif
;
%assign ___NEED_strtofld_count 0
%ifdef __NEED_mini_strtof
  %assign ___NEED_strtofld_count ___NEED_strtofld_count+1
%endif
%ifdef __NEED_mini_strtol
  %assign ___NEED_strtofld_count ___NEED_strtofld_count+1
%endif
%ifdef __NEED_mini_strtold_inaccurate
  %assign ___NEED_strtofld_count ___NEED_strtofld_count+1
%endif
%if ___NEED_strtofld_count>1
  %define __NEED_mini_strtold_inaccurate
%endif
;
_need_aliases ALIASES  ; Must be called after _alias.
;
; We have to put _syscall definitions right here, just above `_need
; mini_syscall3_AL, ...', because syscalls need mini_syscall3_AL.
;_syscall _exit, sys_exit, 1  ; We don't define it here, because we emit `mini__exit:' below manually. TODO(pts): Keep exit_linux.nasm as a fallback.
; The order of the first few syscalls matches the order in src/start_stdio_medium_linux_nasm, used by demo_hello_linux_printf.nasm.
_syscall fork, 2
_syscall read, 3
_syscall write, 4
_syscall open, open2, open3, __M_fopen_open, 5
_syscall close, 6
_syscall creat, 8
_syscall remove, unlink, 10
_syscall lseek, 19
_syscall getpid, 20
_syscall getppid, 64
_syscall ioctl, 54
_syscall ftruncate, 93
_syscall llseek, _llseek, sys_llseek, 140  ; Use mini_lseek64(...) instead, it's more convenient from C code.
_syscall_456 sys_mmap2, 192
_syscall_456 mremap, 163
_syscall munmap, 91
_syscall sys_brk, 45
_syscall time, 13
_syscall gettimeofday, 78
_syscall chmod, 15
_syscall fchmod, 94
_syscall mkdir, 39
_syscall stat64, 195
_syscall lstat64, 196
_syscall fstat64, 197
_syscall symlink, 83
_syscall umask, 60
_syscall execve, 11
_syscall readlink, 85
_syscall utimes, 271
_syscall mq_setattr, sys_mq_getsetattr, 282
_syscall getrlimit, sys_ugetrlimit, 191  ; SuS-compliant getrlimit; sys_getrlimit isn't SuS-compliant.
_syscall chown, sys_chown32, 212  ; For 32-bit UIDs.
_syscall fchown, sys_fchown32, 207
_syscall getegid, sys_getegid32, 202
_syscall geteuid, sys_geteuid32, 201
_syscall getgid, sys_getgid32, 200
_syscall getgroups, sys_getgroups32, 205
_syscall getresgid, sys_getresgid32, 211
_syscall getuid, sys_getuid32, 199
_syscall lchown, sys_lchown32, 198
_syscall setfsgid, sys_setfsgid32, 216
_syscall setfsuid, sys_setfsuid32, 215
_syscall setgid, sys_setgid32, 214
_syscall setgroups, sys_setgroups32, 206
_syscall setregid, sys_setregid32, 204
_syscall setresgid, sys_setresgid32, 210
_syscall setreuid, sys_setreuid32, 203
_syscall setresuid, sys_setresuid32, 208
_syscall getresuid, sys_getresuid32, 209
_syscall posix_fadvise, fadvise64_64, 272
_syscall klogctl, sys_syslog, 103
_syscall select, sys_newselect, 142  ; Available since Linux 2.0.
_syscall sys_mmap, 90
_syscall_456 query_module, 167
_syscall_456 sys_ipc, 117
_syscall_456 sys_select, 82
_syscall sys_exit, 1
_syscall sys_eventfd, 323
_syscall sys_fcntl64, 221
_syscall_456 sys_reboot, 88
_syscall sys_signalfd, 321
_syscall sys_getcwd, 183
_syscall sys_getpriority, 96
_syscall sys_sigaction, 67
_syscall sys_sigpending, 73
_syscall sys_sigprocmask, 126
_syscall sys_sigsuspend, 72
_syscall_456 sys_ptrace, 26
_syscall sys_sched_getaffinity, 242
_syscall sys_getrlimit, 76
_syscall sys_sysctl, 149
_syscall sys_chown, 182
_syscall sys_fchown, 95
_syscall sys_getegid, 50
_syscall sys_geteuid, 49
_syscall sys_getgid, 47
_syscall sys_getgroups, 80
_syscall sys_getresgid, 171
_syscall sys_getresuid, 165
_syscall sys_getuid, 24
_syscall sys_lchown, 16
_syscall sys_setfsgid, 139
_syscall sys_setfsuid, 138
_syscall sys_setgid, 46
_syscall sys_setgroups, 81
_syscall sys_setregid, 71
_syscall sys_setresgid, 170
_syscall sys_setresuid, 164
_syscall sys_setreuid, 70
_syscall sys_setuid, 23
_syscall sys_setuid32, 213
_syscall truncate64, 193
_syscall ftruncate64, 194
_syscall eventfd2, 328
_syscall pread64, 180
_syscall pwrite64, 181
_syscall signalfd4, 327
_syscall access, 33
_syscall add_key, 286
_syscall adjtimex, 124
_syscall alarm, 27
_syscall bdflush, 134
_syscall capget, 184
_syscall capset, 185
_syscall chdir, 12
_syscall chroot, 61
_syscall clock_getres, (259+7)
_syscall clock_gettime, (259+6)
_syscall clock_nanosleep, (259+8)
_syscall clock_settime, (259+5)
_syscall create_module, 127
_syscall delete_module, 129
_syscall dup, 41
_syscall dup2, 63
_syscall dup3, 330
_syscall epoll_create, 254
_syscall epoll_create1, 329
_syscall epoll_ctl, 255
_syscall epoll_wait, 256
_syscall faccessat, 307
_syscall fadvise64, 250
_syscall fallocate, 324
_syscall fanotify_init, 338
_syscall fanotify_mark, 339
_syscall fchdir, 133
_syscall fchmodat, 306
_syscall fchownat, 298
_syscall fcntl, 55
_syscall fdatasync, 148
_syscall fgetxattr, 231
_syscall flistxattr, 234
_syscall flock, 143
_syscall fremovexattr, 237
_syscall fsetxattr, 228
_syscall fstat, 108
_syscall fstatat64, 300
_syscall fstatfs, 100
_syscall fstatfs64, 269
_syscall fsync, 118
_syscall futex, 240
_syscall futimesat, 299
_syscall get_mempolicy, 275
_syscall get_thread_area, 244
_syscall getdents, 141
_syscall getdents64, 220
_syscall getitimer, 105
_syscall getpgid, 132
_syscall getrandom, 355
_syscall getrusage, 77
_syscall getsid, 147
_syscall gettid, 224
_syscall getxattr, 229
_syscall init_module, 128
_syscall inotify_add_watch, 292
_syscall inotify_init, 291
_syscall inotify_init1, 332
_syscall inotify_rm_watch, 293
_syscall io_cancel, 249
_syscall io_destroy, 246
_syscall io_getevents, 247
_syscall io_setup, 245
_syscall io_submit, 248
_syscall ioperm, 101
_syscall iopl, 110
_syscall keyctl, 288
_syscall kill, 37
_syscall lgetxattr, 230
_syscall link, 9
_syscall linkat, 303
_syscall listxattr, 232
_syscall llistxattr, 233
_syscall lremovexattr, 236
_syscall lsetxattr, 227
_syscall lstat, 107
_syscall madvise, 219
_syscall mbind, 274
_syscall memfd_create, 356
_syscall mincore, 218
_syscall mkdirat, 296
_syscall mknod, 14
_syscall mknodat, 297
_syscall mlock, 150
_syscall mlock2, 376
_syscall mlockall, 152
_syscall mount, 21
_syscall mprotect, 125
_syscall mq_getsetattr, (277+5)
_syscall mq_notify, (277+4)
_syscall mq_open, 277
_syscall mq_timedreceive, (277+3)
_syscall mq_timedsend, (277+2)
_syscall mq_unlink, (277+1)
_syscall msync, 144
_syscall munlock, 151
_syscall munlockall, 153
_syscall nanosleep, 162
_syscall openat, 295
_syscall pause, 29
_syscall personality, 136
_syscall pipe, 42
_syscall pipe2, 331
_syscall pivot_root, 217
_syscall poll, 168
_syscall prctl, 172
_syscall preadv, 333
_syscall pwritev, 334
_syscall quotactl, 131
_syscall readahead, 225
_syscall readlinkat, 305
_syscall readv, 145
_syscall remap_file_pages, 257
_syscall removexattr, 235
_syscall rename, 38
_syscall renameat, 302
_syscall request_key, 287
_syscall rmdir, 40
_syscall rt_sigaction, 174
_syscall rt_sigpending, 176
_syscall rt_sigprocmask, 175
_syscall rt_sigqueueinfo, 178
_syscall rt_sigreturn, 173
_syscall rt_sigsuspend, 179
_syscall rt_sigtimedwait, 177
_syscall sched_get_priority_max, 159
_syscall sched_get_priority_min, 160
_syscall sched_getparam, 155
_syscall sched_getscheduler, 157
_syscall sched_rr_get_interval, 161
_syscall sched_setaffinity, 241
_syscall sched_setparam, 154
_syscall sched_setscheduler, 156
_syscall sched_yield, 158
_syscall sendfile, 187
_syscall sendfile64, 239
_syscall set_mempolicy, 276
_syscall set_thread_area, 243
_syscall set_tid_address, 258
_syscall setdomainname, 121
_syscall sethostname, 74
_syscall setitimer, 104
_syscall setns, 346
_syscall setpgid, 57
_syscall setpriority, 97
_syscall setrlimit, 75
_syscall setsid, 66
_syscall settimeofday, 79
_syscall setxattr, 226
_syscall sigaltstack, 186
_syscall splice, 313
_syscall stat, 106
_syscall statfs, 99
_syscall statfs64, 268
_syscall stime, 25
_syscall swapoff, 115
_syscall swapon, 87
_syscall symlinkat, 304
_syscall sync, 36
_syscall syncfs, 344
_syscall sysfs, 135
_syscall sysinfo, 116
_syscall tee, 315
_syscall tgkill, 270
_syscall timer_create, 259
_syscall timer_delete, (259+4)
_syscall timer_getoverrun, (259+3)
_syscall timer_gettime, (259+2)
_syscall timer_settime, (259+1)
_syscall timerfd_create, 322
_syscall timerfd_gettime, 326
_syscall timerfd_settime, 325
_syscall times, 43
_syscall tkill, 238
_syscall truncate, 92
_syscall umount, 22
_syscall umount2, 52
_syscall uname, 122
_syscall unlinkat, 301
_syscall ustat, 62
_syscall utime, 30
_syscall utimensat, 320
_syscall vhangup, 111
_syscall vmsplice, 316
_syscall wait4, 114
_syscall waitpid, 7
_syscall writev, 146
_syscall sys_readdir, 89
_syscall sysv_signal, sys_signal, 48
_syscall sys_socketcall, 102
_syscall sys_oldstat, 18
_syscall sys_oldfstat, 28
_syscall sys_oldlstat, 84
_syscall sys_oldolduname, 59
_syscall sys_olduname, 109
_syscall sys_vm86old, 113
_syscall sys_vm86, 166
_syscall sys_ftime, 35
_syscall sys_profil, 98
_syscall sys_ulimit, 58
_syscall sys_afs_syscall, 137
_syscall sys_break, 17
_syscall sys_getpmsg, 188
_syscall sys_putpmsg, 189
_syscall sys_stty, 31
_syscall sys_gtty, 32
_syscall sys_idle, 112
_syscall sys_lock, 53
_syscall sys_mpx, 56
_syscall sys_prof, 44
_syscall sys_vserver, 273
_syscall_456 sys_accept4, 364
_syscall sys_bind, 361
_syscall sys_connect, 362
_syscall sys_getpeername, 368
_syscall sys_getsockname, 367
_syscall_456 sys_getsockopt, 365
_syscall sys_listen, 363
_syscall_456 sys_recvfrom, 371
_syscall_456 sys_recvmmsg, 337
_syscall sys_recvmsg, 372
_syscall_456 sys_sendmmsg, 345
_syscall sys_sendmsg, 370
_syscall_456 sys_sendto, 369
_syscall_456 sys_setsockopt, 366
_syscall sys_shutdown, 373
_syscall sys_socket, 359
_syscall_456 sys_socketpair, 360
_syscall sys_msgctl, 402
_syscall sys_msgget, 399
_syscall_456 sys_msgrcv, 401
_syscall_456 sys_msgsnd, 400
_syscall_456 sys_semctl, 394
_syscall sys_semget, 393
_syscall sys_shmat, 397
_syscall sys_shmctl, 396
_syscall sys_shmdt, 398
_syscall sys_shmget, 395
_syscall nice, 34
_syscall acct, 51
_syscall getpgrp, 65
_syscall sgetmask, 68
_syscall ssetmask, 69
_syscall uselib, 86
_syscall sigreturn, 119
_syscall clone, 120
_syscall modify_ldt, 123
_syscall get_kernel_syms, 130
_syscall nfsservctl, 169
_syscall vfork, 190
_syscall sys_set_zone_reclaim, 251
_syscall exit_group, 252
_syscall lookup_dcookie, 253
_syscall kexec_load, 283
_syscall sys_waitid, 284
_syscall ioprio_set, 289
_syscall ioprio_get, 290
_syscall migrate_pages, 294
_syscall pselect6, 308
_syscall ppoll, 309
_syscall unshare, 310
_syscall set_robust_list, 311
_syscall get_robust_list, 312
_syscall sync_file_range, 314
_syscall move_pages, 317
_syscall getcpu, 318
_syscall epoll_pwait, 319
_syscall rt_tgsigqueueinfo, 335
_syscall perf_event_open, 336
_syscall prlimit64, 340
_syscall name_to_handle_at, 341
_syscall open_by_handle_at, 342
_syscall clock_adjtime, 343
_syscall process_vm_readv, 347
_syscall process_vm_writev, 348
_syscall kcmp, 349
_syscall finit_module, 350
_syscall sched_setattr, 351
_syscall sched_getattr, 352
_syscall renameat2, 353
_syscall seccomp, 354
_syscall bpf, 357
_syscall execveat, 358
_syscall userfaultfd, 374
_syscall membarrier, 375
_syscall copy_file_range, 377
_syscall preadv2, 378
_syscall pwritev2, 379
_syscall pkey_mprotect, 380
_syscall pkey_alloc, 381
_syscall pkey_free, 382
_syscall statx, 383
_syscall arch_prctl, 384
_syscall io_pgetevents, 385
_syscall rseq, 386
_syscall clock_gettime64, 403
_syscall clock_settime64, 404
_syscall clock_adjtime64, 405
_syscall clock_getres_time64, 406
_syscall clock_nanosleep_time64, 407
_syscall timer_gettime64, 408
_syscall timer_settime64, 409
_syscall timerfd_gettime64, 410
_syscall timerfd_settime64, 411
_syscall utimensat_time64, 412
_syscall pselect6_time64, 413
_syscall ppoll_time64, 414
_syscall io_pgetevents_time64, 416
_syscall recvmmsg_time64, 417
_syscall mq_timedsend_time64, 418
_syscall mq_timedreceive_time64, 419
_syscall semtimedop_time64, 420
_syscall rt_sigtimedwait_time64, 421
_syscall futex_time64, 422
_syscall sched_rr_get_interval_time64, 423
_syscall pidfd_send_signal, 424
_syscall io_uring_setup, 425
_syscall io_uring_enter, 426
_syscall io_uring_register, 427
_syscall open_tree, 428
_syscall move_mount, 429
_syscall fsopen, 430
_syscall fsconfig, 431
_syscall fsmount, 432
_syscall fspick, 433
_syscall pidfd_open, 434
_syscall clone3, 435
_syscall close_range, 436
_syscall openat2, 437
_syscall pidfd_getfd, 438
_syscall faccessat2, 439
_syscall process_madvise, 440
_syscall epoll_pwait2, 441
_syscall mount_setattr, 442
_syscall quotactl_fd, 443
_syscall landlock_create_ruleset, 444
_syscall landlock_add_rule, 445
_syscall landlock_restrict_self, 446
_syscall memfd_secret, 447
_syscall process_mrelease, 448
_syscall futex_waitv, 449
_syscall set_mempolicy_home_node, 450
;
_need mini___M_jmp_syscall_pop_ebx_return, mini_syscall3_RP1
_need mini_syscall, mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
_need mini_syscall3_AL, mini_syscall3_RP1
_need mini_syscall6_AL, mini_syscall6_RP1
_need mini_syscall6_RP1, mini_syscall3_RP1
_need mini_syscall6_RP1, mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
_need mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return, mini___M_jmp_pop_ebx_syscall_return
_need mini_syscall3_RP1, mini___M_jmp_pop_ebx_syscall_return
_need mini___M_jmp_pop_ebx_syscall_return, mini___M_jmp_syscall_return
_need mini_syscall3_RP1, mini___LM_push_exit_args
_need mini__exit, mini_sys_exit
_need mini_sys_exit, mini___LM_push_exit_args

%define CLEANUP_IS_EMPTY 1
%ifdef __NEED_start.mini___M_start_flush_stdout
  %define CLEANUP_IS_EMPTY 0
%endif
%ifdef __NEED_mini___M_start_flush_opened
  %define CLEANUP_IS_EMPTY 0
%endif
%ifdef __NEED_mini_syscall3_RP1
  %define CLEANUP_IS_EMPTY 0
%endif

%if CLEANUP_IS_EMPTY==0
  %ifdef __NEED_mini__start
    %define NEED_cleanup
  %endif
  %ifdef __NEED_mini_exit
    %define NEED_cleanup
  %endif
%endif

%ifdef __NEED_mini_syscall
  %ifdef __NEED_mini_syscall3_RP1
    %define __NEED_mini_syscall6_RP1
  %endif
  %ifdef __NEED_mini_syscall6_RP1
    %define NEED_syscall6_both
    %define NEED_syscall6_any
  %else
    %define NEED_syscall6_syscall_only
    %define NEED_syscall6_any
  %endif
%else
  %ifdef __NEED_mini_syscall6_RP1
    %define NEED_syscall6_RP1_only
    %define NEED_syscall6_any
  %elifdef __NEED_mini___M_jmp_syscall_pop_ebp_edi_esi_ebx_return
    %define NEED_syscall6_int80_only
    %define NEED_syscall6_any
  %endif
%endif

%define CONFIG_SECTIONS_DEFINED  ; Used by %include files below.
section .text align=1
%ifdef __NEED_mini__start
__smart_extern main
global mini__start
global _start
_start:
%ifdef CONFIG_MAIN_NO_ARGC_ARGV_ENVP
  %define MAIN_ARG_MODE 0
%elifdef CONFIG_MAIN_NO_ARGV_ENVP
  %define MAIN_ARG_MODE 1
%elifdef CONFIG_MAIN_NO_ENVP
  %define MAIN_ARG_MODE 2
%else
  %define MAIN_ARG_MODE 4  ; 0: no argc--argv--envp; 1: has argc, no argv---envp; 2: has argc--argv, no envp (and no mini_environ); 3: has argc--argv--environ, no envp (but has mini_environ); 4: has argc--argv--envp.
%endif
%ifdef __NEED_mini_environ
  %if MAIN_ARG_MODE<3
    %define MAIN_ARG_MODE 3
  %endif
%endif
mini__start:  ; Entry point (_start) of the Linux i386 executable.
		; Now the stack looks like (from top to bottom):
		;   dword [esp]: argc
		;   dword [esp+4]: argv[0] pointer
		;   esp+8...: argv[1..] pointers
		;   NULL that ends argv[]
		;   environment pointers
		;   NULL that ends envp[]
		;   ELF Auxiliary Table
		;   argv strings
		;   environment strings
		;   program name
		;   NULL		
%if MAIN_ARG_MODE<1
%elif MAIN_ARG_MODE==1  ; argc only.
		;pop eax  ; Needed only if main is __watcall or __regparm__(1..3).
%elif MAIN_ARG_MODE==2  ; This works for __cdecl, __watcall and __regparm__(2..3).
		pop eax  ; argc.
		mov edx, esp  ; argv.
		push edx  ; Argument argv for main. Only needed for __cdecl.
		push eax  ; Argument argc for main. Only needed for __cdecl.
%elif MAIN_ARG_MODE>=3  ; Tested only with __cdecl.
		pop eax  ; argc.
		mov edx, esp  ; argv.
		lea ecx, [edx+eax*4+4]  ; envp.
  %if MAIN_ARG_MODE==4
		push ecx  ; Argument envp for main.
  %endif
  %ifdef __NEED_mini_environ
		mov [mini_environ], ecx
  %endif
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
%endif
		_call_extern_if_needed mini___M_start_isatty_stdin
%ifdef __NEED_start.mini___M_start_isatty_stdout
start.mini___M_start_isatty_stdout:
  %ifdef __NEED_mini_isatty
  __smart_extern mini_isatty
		push byte 1  ; STDOUT_FILENO.
		call mini_isatty
		pop edx  ; Clean up the argument of mini_isatty from the stack.
		add eax, eax
		add [mini_stdout_struct.dire], al  ; filep->dire = FD_WRITE_LINEBUF, changed from FD_WRITE.
  %else
		sub esp, strict byte 0x24
		push esp  ; 3rd argument of ioctl TCGETS.
		push strict dword 0x5401  ; TCGETS.
		push byte 1  ; fd argument of ioctl: STDOUT_FILENO == 1.
    %ifdef __NEED_mini_ioctl
		call mini_ioctl
    %else
      %if __NRM_mini_ioctl>255
        %error ioctl syscall number too large.
        times 1/0 nop
      %endif
		mov al, __NRM_mini_ioctl
		call mini_syscall3_AL
    %endif
		add esp, strict byte 0x24+3*4  ; Clean up everything pushed.
		test eax, eax
		jnz .stdout_notty
		mov byte [mini_stdout_struct.dire], 6  ; FD_WRITE_LINEBUF.
    .stdout_notty:
  %endif
%endif
		call main  ; Return value (exit code) in EAX (AL).
%ifdef __NEED_mini___LM_push_exit_args
		push eax  ; Save exit code, for mini_sys_exit(...).
		push eax  ; Push fake return address, for mini_sys_exit(...).
%elifdef NEED_cleanup
		push eax  ; Save exit code, for mini_sys_exit(...).
%endif
		; Fall through.
%endif  ; __NEED_mini_start
%ifdef __NEED_mini_exit
global mini_exit
mini_exit:  ; void mini_exit(int exit_code);
%endif
%ifdef NEED_cleanup
%ifdef __NEED_start.mini___M_start_flush_stdout
start.mini___M_start_flush_stdout:
		push dword [mini_stdout]
		call mini_fflush
		pop edx  ; Clean up the argument of mini_fflush from the stack.
%endif
		_call_if_needed mini___M_start_flush_opened
		; Fall through.
%endif  ; NEED_cleanup
%ifdef __NEED_mini_sys_exit
  global mini_sys_exit
  mini_sys_exit:  ; void mini_sys_exit(int exit_code);
  global mini__exit
  mini__exit:  ; void mini__exit(int exit_code);
  %ifdef __NEED_mini_syscall3_AL
		mov al, 1  ; __NR_exit.
		; Fall through to mini_syscall3_AL or mini_syscall6_AL.
  %elifdef __NEED_mini_syscall3_RP1
		xor eax, eax
		inc eax  ; EAX := 1 (__NR_exit).
		; Fall through to mini_syscall3_RP1 or mini_syscall6_RP1.
  %else
		pop ebx  ; Fake or real return address of mini_sys_exit.
		pop ebx  ; Exit code.
		xor eax, eax
		inc eax  ; EAX := 1 (__NR__exit).
		int 0x80  ; Linux i386 syscall. _exit(2) doesn't return.
  %endif
%elifdef __NEED_mini_syscall3_AL
		mov al, 1  ; __NR_exit.
		; Fall through to mini_syscall3_AL or mini_syscall6_AL.
%elifdef __NEED_mini_syscall3_RP1
		xor eax, eax
		inc eax  ; EAX := 1 (__NR_exit).
		; Fall through to mini_syscall3_RP1 or mini_syscall6_RP1.
%elifdef __NEED_mini__start
  %ifdef mini___LM_push_exit_args
		pop ebx  ; Fake or real return address of mini_sys_exit.
		pop ebx  ; Exit code.
  %elifdef NEED_cleanup
		pop ebx  ; Exit code.
  %else
		xchg eax, ebx  ; EBX := exit code; EAX := junk.
  %endif
		xor eax, eax
		inc eax  ; EAX := 1 (__NR__exit).
		int 0x80  ; Linux i386 syscall. _exit(2) doesn't return.
%endif
%ifdef __NEED_mini_syscall6_AL
  global mini_syscall6_AL
  mini_syscall6_AL:  ; Useful from assembly language.
                  ; Fall through to mini_syscall3_AL.
  ; Calls syscall(number, arg1, arg2, arg3, arg4, arg5, arg6).
  ;
  ; It takes the syscall number from AL (8 bits only!), arg1 (optional) from
  ; [esp+4], arg2 (optional) from [esp+8], arg3 (optional) from [esp+0xc],
  ; arg4 (optional) from [esp+0x10], arg5 (optional) from [esp+0x14], arg6
  ; (optional) from [esp+0x18]. It keeps these args on the stack. It can use
  ; EAX, EDX and ECX as scratch. It returns result (or -1 as error) in EAX.
  %ifndef __NEED_mini_syscall3_AL
    %assign LAST_SC36AL $-$$
		movzx eax, al  ; Syscall number.
		; Fall through to mini_syscall3_RP1 or mini_syscall6_RP1.
  %endif
%endif
%ifdef __NEED_mini_syscall3_AL
  global mini_syscall3_AL
  mini_syscall3_AL:  ; Useful from assembly language.
  syscall36_AL:
  ; Calls syscall(number, arg1, arg2, arg3).
  ;
  ; It takes the syscall number from AL (8 bits only!), arg1 (optional) from
  ; [esp+4], arg2 (optional) from [esp+8], arg3 (optional) from [esp+0xc]. It
  ; keeps these args on the stack. It can use EAX, EDX and ECX as scratch. It
  ; returns result (or -1 as error) in EAX.
  %assign LAST_SC36AL $-$$
		movzx eax, al  ; Syscall number.
		; Fall through to mini_syscall3_RP1 or mini_syscall6_RP1.
%endif
%ifdef __NEED_mini_syscall6_RP1
  global mini_syscall6_RP1
  mini_syscall6_RP1:  ; void *mini_syscall6(long number, int arg1, int arg2, int arg3, int arg4, int arg5, int arg6);
  %ifndef __NEED_mini_syscall3_RP1
    %assign LAST_SC36EAX $-$$
  %endif
%endif
%ifdef __NEED_mini_syscall3_RP1
  global mini_syscall3_RP1
  mini_syscall3_RP1:
  syscall36_EAX:
  %assign LAST_SC36EAX $-$$
%endif
%ifdef NEED_syscall6_both
		clc
		db 0xb1  ; `mov cl, ...', effectively skip the next instruction (stc).
global mini_syscall
mini_syscall:  ; long mini_syscall(long nr, ...);  /* Supports up to 6 arguments after nr, that's the maximum on Linux. */
		stc
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		jnc .after_eax  ; EAX already contains the syscall number for mini_syscall6_RP1 and mini_syscall6_AL.
		lodsd  ; EAX := syscall number (nr).
.after_eax:
%elifdef NEED_syscall6_RP1_only
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		; lodsd ; EAX already contains the syscall number for mini_syscall6_RP1 and mini_syscall6_AL.
%elifdef NEED_syscall6_syscall_only
; This is quite rare, but it can happen: main(...) just calls mini_syscall(...) and returns.
; Another way: main(...) just calls mini_syscall(...) and then calls mini_sys_exit(...).
; TODO(pts): Test both.
global mini_syscall
mini_syscall:  ; long mini_syscall(long nr, ...);  /* Supports up to 6 arguments after nr, that's the maximum on Linux. */
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		lodsd  ; EAX := syscall number (nr).
%elifdef NEED_syscall6_int80_only
%elifdef __NEED_mini_syscall3_RP1
		push ebx  ; Save it, it's not a scratch register.
%endif
%ifdef NEED_syscall6_any  ; Load 6 syscall arguments from the stack (starting at ESI) to EBX, ECX, EDX, ESI, EDI, EBP.
		xchg eax, edx  ; EDX := EAX; EAX := junk.
		lodsd
		xchg eax, ebx  ; EBX := EAX; EAX := junk.
		lodsd
		xchg eax, ecx  ; ECX := EAX; EAX := junk.
		lodsd
		xchg eax, edx  ; Useeful swap.
		mov edi, [esi+1*4]
		mov ebp, [esi+2*4]
		mov esi, [esi]  ; This is the last one, it ruins the index in ESI.
  global mini___M_jmp_syscall_pop_ebp_edi_esi_ebx_return
  mini___M_jmp_syscall_pop_ebp_edi_esi_ebx_return:
		int 0x80  ; Linux i386 syscall.
		; Fall through to mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return.
%elifdef __NEED_mini_syscall3_RP1  ; Load 3 syscall arguments from the stack (starting at ESP+8) to EBX, ECX, EDX.
		mov ebx, [esp+2*4]  ; arg1.
		mov ecx, [esp+3*4]  ; arg2.
		mov edx, [esp+4*4]  ; arg3.
  global mini___M_jmp_syscall_pop_ebx_return
  mini___M_jmp_syscall_pop_ebx_return:
		int 0x80  ; Linux i386 syscall.
  %ifdef __NEED_mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return  ; Rarely happens here.
		jmp strict short mini___M_jmp_pop_ebx_syscall_return
  %endif
		; Fall through to mini___M_jmp_pop_ebx_syscall_return.
%endif
%ifdef __NEED_mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
  global mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
  mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return:
		pop ebp
		pop edi
		pop esi
		; Fall through to mini___M_jmp_pop_ebx_syscall_return.
%endif
%ifdef __NEED_mini___M_jmp_pop_ebx_syscall_return
  global mini___M_jmp_pop_ebx_syscall_return
  mini___M_jmp_pop_ebx_syscall_return:
		pop ebx
		; Fall through to mini___M_jmp_syscall_return.
%endif  ; __NEED_mini___M_jmp_pop_ebx_syscall_return
%ifdef __NEED_mini___M_jmp_syscall_return
  global mini___M_jmp_syscall_return
  mini___M_jmp_syscall_return:
		; test eax, eax
		; jns .final_result
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
  %ifdef __NEED_mini_errno  ; TODO(pts): More syscalls should set errno.
		neg eax
		mov dword [mini_errno], eax
  %endif
		or eax, byte -1  ; EAX := -1 (error).
  .final_result: ret
%endif  ; __NEED_mini___M_jmp_syscall_return
%ifdef __NEED_syscall6_any
  %ifdef __NEED_mini___M_jmp_syscall_pop_ebx_return
    global mini___M_jmp_syscall_pop_ebx_return
    mini___M_jmp_syscall_pop_ebx_return:
                  int 0x80  ; Linux i386 syscall.
                  jmp strict short mini___M_jmp_pop_ebx_syscall_return
  %endif
%endif

_emit_syscalls SYSCALLS
_define_alias_syms ALIASES  ; Must be called after alias targets have been defined.

%ifdef __NEED_.bss
  section .bss align=4
  section .text
  %ifdef CONFIG_PIC
    %error Not PIC because it uses .bss.
    times 1/0 nop
  %endif
%endif
%ifdef __NEED_.data
  section .data align=4
  section .text
  %ifdef CONFIG_PIC
    %error Not PIC because it uses .data.
    times 1/0 nop
  %endif
%endif

%ifdef __NEED_mini_errno  ; !! TODO(pts): Make strtok and strtod populate errno, but -fno-math-errno.
section .bss
global mini_errno
mini_errno:	resd 1  ; int mini_errno;
section .text
%ifdef CONFIG_PIC
%error Not PIC because it defines mini_errno.
times 1/0 nop
%endif
%endif

%ifdef __NEED_mini_environ
section .bss
global mini_environ
mini_environ:	resd 1  ; char **mini_environ;
section .text
%ifdef CONFIG_PIC
%error Not PIC because it defines mini_environ.
times 1/0 nop
%endif
%endif

%ifdef __NEED_mini_fputc_RP3
__smart_extern mini_fputc_RP3
%endif

%ifdef __NEED_mini_putchar
global mini_putchar
mini_putchar:  ; int mini_putchar(int c);
		mov eax, [esp+4]  ; TODO(pts): Get rid of this with smart linking if unused.
		; Fall through to mini_putchar_RP3.
%endif
%ifdef __NEED_mini_putchar_RP3
global mini_putchar_RP3
mini_putchar_RP3:  ; int REGPARM3 mini_putchar_RP3(int c);
		mov edx, [mini_stdout]
		call mini_fputc_RP3
		ret
%endif

%ifdef __NEED_mini_stdout
  %include "src/stdio_medium_stdout_in_data.nasm"
  section .text
%endif

%ifdef __NEED_mini_fflush
  %ifdef __NEED_mini___M_discard_buf_RP3
    __smart_extern mini___M_discard_buf_RP3
  %else
    %define CONFIG_FLUSH_INLINE_DISCARD_BUF
  %endif
  %include "src/stdio_medium_fflush.nasm"
%endif

%define NEED_include_vfprintf 0
%ifdef __NEED_mini_printf
  %ifndef __NEED_mini_vfprintf
    %define NEED_include_vfprintf 1
  %endif
%endif
%ifdef CONFIG_VFPRINTF_NO_PLUS
  %define NEED_include_vfprintf 1
%endif
%ifdef CONFIG_VFPRINTF_NO_OCTAL
  %define NEED_include_vfprintf 1
%endif
%ifdef CONFIG_VFPRINTF_NO_LONG
  %define NEED_include_vfprintf 1
%endif
%ifdef CONFIG_VFPRINTF_NO_LONGLONG
  %define NEED_include_vfprintf 1
%endif

%ifdef __NEED_mini___M_vfsprintf
  %define mini_vfprintf mini___M_vfsprintf
  %ifndef NEED_include_vfprintf
    __smart_extern mini_vfprintf
  %endif
  ; %include these files, so that the `call mini_vfprintf_for_s_printf' they
  ; contain can be replaced with `call mini___M_vfsprintf'.
  ; TODO(pts): Unify mini_sprintf(...) and mini_snprintf(...) if both are needed.
  %ifdef __NEED_mini_sprintf
    %include "src/stdio_medium_sprintf.nasm"
  %endif  ; __NEED_mini_sprintf
  %ifdef __NEED_mini_snprintf
    %include "src/stdio_medium_snprintf.nasm"
  %endif  ; __NEED_mini_snprintf
  %undef mini_vfprintf
  %ifdef __NEED_mini_vfprintf
    %error conflicting labels: mini___M_vfsprintf and mini_vfprintf
    times 1/0 nop
  %endif
%endif  ; __NEED_mini___M_vfsprintf

%ifdef __NEED_mini_printf
  global mini_printf
  mini_printf:  ; int mini_printf(const char *fmt, ...) { return mini_vfprintf(mini_stdout, fmt, ap); }
  %ifndef __NEED_mini_vfprintf
		mov eax, esp
  %endif
  ;esp:retaddr fmt val
		push esp  ; 1 byte.
  ;esp:&retaddr retaddr fmt val
		add dword [esp], strict byte 2*4  ; 4 bytes.
  ;esp:ap=&val retaddr fmt val
		push dword [esp+2*4]  ; 4 bytes.
  ;esp:fmt ap=&val retaddr fmt val
		push dword [mini_stdout]  ; 6 bytes.
  ;esp:filep fmt ap=&val retaddr fmt val
  %ifdef __NEED_mini_vfprintf
    __smart_extern mini_vfprintf
		call mini_vfprintf  ; 5 bytes.
    ;esp:filep fmt ap=&val retaddr fmt val
		add esp, strict byte 3*4  ; 3 bytes, same as `times 3 pop edx'.
    ;esp:retaddr fmt val
		ret  ; 1 byte.
  %else
		push eax  ; Prepared return ESP instead of return address, for CONFIG_VFPRINTF_POP_ESP_BEFORE_RET.
		; Fall through to mini_vfprintf.
    %define CONFIG_VFPRINTF_POP_ESP_BEFORE_RET
  %endif
%endif  ; __NEED_mini_printf
%if NEED_include_vfprintf
  section .rodata align=1  ; TODO(pts): Why is this line needed?
  section .text
  %include "src/stdio_medium_vfprintf.nasm"
  %undef __NEED_mini_vfprintf  ; Don't %include it again.
  %undef __NEED_mini___M_vfsprintf  ; Don't %include it again.
%endif

%ifdef __NEED_mini___M_start_flush_opened
  %include "src/stdio_medium_flush_opened.nasm"
%endif
%ifdef __NEED_mini___M_global_files
  %include "src/stdio_medium_global_files.nasm"
%elifdef __NEED_mini___M_global_files_end
  %include "src/stdio_medium_global_files.nasm"
%elifdef __NEED_mini___M_global_file_bufs
  %include "src/stdio_medium_global_files.nasm"
%endif

%if ___NEED_strtofld_count>1
  __smart_extern mini_strtold_inaccurate
  %ifdef __NEED_mini_strtof
    global mini_strtof
    mini_strtof:  ; float mini_strtof(const char *str, char **endptr);
		push dword [esp+2*4]  ; Argument endptr.
		push dword [esp+2*4]  ; Argument str.
		call mini_strtold_inaccurate
		fstp dword [esp]
		fld dword [esp]  ; By doing this fstp+fld combo, we round the result to f32.
    mini_strtof.done:
		times 2 pop edx  ; Clean up arguments of mini_strtold_inaccurate from the stack.
		ret
  %endif
  %ifdef __NEED_mini_strtod
    global mini_strtod
    mini_strtod:  ; double mini_strtod(const char *str, char **endptr);
		push dword [esp+2*4]  ; Argument endptr.
		push dword [esp+2*4]  ; Argument str.
		call mini_strtold_inaccurate
		fstp qword [esp]
		fld qword [esp]  ; By doing this fstp+fld combo, we round the result to f64.
    %ifdef __NEED_mini_strtof
		jmp strict short mini_strtof.done
    %else
		times 2 pop edx  ; Clean up arguments of mini_strtold_inaccurate from the stack.
		ret
    %endif
  %endif
%endif

%ifdef __NEED_mini_ffsll
  %ifdef __NEED___ffsdi2
    %define CONFIG_FFSLL_ALSO_FFSDI2  ; Define both mini_ffsll(...) and __ffsdi2(...).
    %include "src/ffsll.nasm"
  %endif
%endif

%ifdef __NEED___mulxc3
  %ifndef __NEED___muldc3
    %ifndef __NEED___mulsc3
      %define CONFIG_MULXC3_INLINE  ; Use the shorter, inline implementation of __mulxc3 if __mulc3 and __mulsc3 are not used.
      %include "src/float_mulxc3.nasm"
    %endif
  %endif
%endif

%ifdef __NEED_getopt
  %ifndef __NEED_opterr
    %define CONFIG_GETOPT_ASSUME_OPTERR_TRUE  ; Makes the implementation shorter by omitting a `dd 1' and a `cmp'.
    %include "src/getopt.nasm"
  %endif
%endif

%ifdef __NEED_mini_strcasecmp
  %ifdef __NEED_mini_strncasecmp
    %define CONFIG_STRNCASECMP_BOTH  ; Define both mini_strcasecmp(...) and mini_strncasecmp(...), the former calling the latter.
    %include "src/strncasecmp_both.nasm"
  %endif
%endif

; Helpfully %include some needed minilibc686 source files.
; demo_hello_linux_printf.nasm relies on this.
%ifidn __OUTPUT_FORMAT__, bin
  ; Usage: _include_if_needed <name>[, <name2>...], "<include-file.nasm>"
  ;
  ; Includes "<influcde-file.nasm>" if at least one of the specified names
  ; are needed.
  %macro _include_if_needed 1-*
    %undef INCLUDE_NEEDED
    %rep %0-1
      %ifdef __NEED_%1
        %define INCLUDE_NEEDED
      %endif
      %rotate 1
    %endrep
    %ifdef INCLUDE_NEEDED
      %include %1
    %endif
  %endmacro
  _include_if_needed mini_isatty, "src/isatty_linux.nasm"
  _include_if_needed mini___M_discard_buf_RP3, "src/stdio_medium_discard_buf.nasm"
  _include_if_needed mini_fputc_RP3, "src/stdio_medium_fputc_rp3.nasm"
  _include_if_needed mini___M_vfsprintf, "src/stdio_medium_vfsprintf.nasm"
  _include_if_needed mini_vfprintf, "src/stdio_medium_vfprintf.nasm"
  _include_if_needed mini___M_writebuf_relax_RP1, mini___M_writebuf_unrelax_RP1, "src/stdio_medium_writebuf_relax.nasm"
%endif

; __END__

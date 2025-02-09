;
; sys_freebsd.nasm; an example Linux implementation of _start and syscalls for `minicc -bfreebsd' and `minilibc -bfreebsdx'
; by pts@fazekas.hu at Tue Dec 10 01:55:16 CET 2024
;
; Please note that mini_errno may still be OS-specific.
;
; TODO(pts): Move this file to src/, compile it (to some extent) in build.sh.
;
; Info: https://alfonsosiciliano.gitlab.io/posts/2021-01-02-freebsd-system-calls-table.html
;

%ifnidn (__OUTPUT_FORMAT__), (elf)
  %error '`nasm -f elf` required.'
  times 1/0 nop
%endif

%ifndef UNDEFSYMS
  %error 'Expecting UNDEFSYMS from minicc.'
  times 1/0 nop
%endif
%macro _define_needs 0-*
  %rep %0
    %define __NEED_%1
    %rotate 1
  %endrep
%endmacro
_define_needs UNDEFSYMS

bits 32
%ifdef CONFIG_I386
  cpu 386  ; We could use __CPU__ defined by minicc.sh.
%else
  cpu 686
%endif
extern main
%ifdef __NEED_mini_errno
  %ifndef __MULTIOS__  ; Defined by minicc.sh.
    extern mini_errno  ; Not implemented.
  %endif
%endif
%macro define_weak 1
  extern %1
%endmacro
define_weak mini___M_start_isatty_stdin
define_weak mini___M_start_isatty_stdout
define_weak mini___M_start_flush_stdout
define_weak mini___M_start_flush_opened
define_weak _start

section .text align=1

%ifdef __NEED__start
;global _start
;_start:
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
WEAK.._start:
;mini__start:  ; Entry point (_start) of the Linux i386 executable. Same for SVR3 i386, SVR4 i386, FreeBSD i386 and macOS i386 up to the end of envp.
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
		push byte 4  ; SYS_write for both Linux i386 and FreeBSD.
		pop eax
		xor edx, edx  ; Argument count of Linux i386 SYS_write.
		push edx  ; Argument count of FreeBSD SYS_write.
		xor ecx, ecx  ; Argument buf of Linux i386 SYS_write.
		push ecx  ; Argument buf of FreeBSD SYS_write.
		or ebx, byte -1  ; Argument fd of Linux i386 SYS_write.
		push ebx  ; Argument fd of FreeBSD SYS_write.
		push eax  ; Fake return address of FreeBSD syscall.
		int 0x80  ; Linux i386 and FreeBSD i386 syscall. It fails because of the negative fd.
		add esp, byte 4*4  ; Clean up syscall arguments above.
%ifdef __MULTIOS__  ; Set by minicc.sh if Linux support is needed in addition to FreeBSD.
		not eax
		shr eax, 31  ; EAX := sign(EAX). Linux becomes 0 (because SYS_write has returned a negative errno value: -EBADF), FreeBSD becomes 1.
		mov [mini___M_is_freebsd], al
		; The previous detection used SYS_getpid and checked CF
		; after `int 0x80'. This worked on modern Linux kernels (who
		; don't change CF, but FreeBSD i386 sets CF=0 upon success),
		; but `int 0x80' Linux 1.0.4 sets CF=0, so it didn't work.
		; Checking the sign of the errno return value is more
		; robust.
%else  ; Exit gracefully (without segmentation fault) if this FreeBSD i386 program is run on Linux i386.
		test eax, eax
		jns freebsd
		xor eax, eax
		inc eax  ; EAX := SYS_exit for Linux i386.
		;or ebx, byte -1  ; exit(255);  ; No need to set it it still has this value from above.
		int 0x80  ; Linux i386 sysall.
  freebsd:
%endif
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
		call mini___M_start_isatty_stdin
		call mini___M_start_isatty_stdout
		call main
		push eax  ; Push return value of main, it will be the exit code of the process.
		push eax  ; Push fake return address.
		; Fall through to mini_exit.
%endif  ; %ifdef __NEED_start
global mini_exit
mini_exit:  ; __attribute__((noreturn)) void mini_exit(int status);
		call mini___M_start_flush_stdout
		call mini___M_start_flush_opened
		; Fall through to mini__exit.
global mini__exit
mini__exit:  ; __attribute__((noreturn)) void mini__exit(int exit_code);
%ifdef __MULTIOS__
		mov ebx, [esp+4]  ; Linux i386 syscall needs the 1st argument in EBX. FreeBSD needs it in [esp+4].
%endif
		xor eax, eax
		inc eax  ; EAX := FreeBSD i386 and Linux i386 SYS_exit (1).
		int 0x80  ; FreeBSD i386 and Linux i386 syscall.
		; Not reached.

%ifdef __NEED_mini_remove
  %define __NEED_mini_unlink
%endif
%ifdef __NEED_mini_isatty
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_write
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_read
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_open_largefile
  %define __NEED_mini_open
%endif
%ifdef __NEED_mini_open
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_close
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_unlink
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini___M_fopen_open
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_time
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_lseek
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_ftruncate
  %define __NEED_simple_syscall3_AL
%endif
%ifdef __NEED_mini_ftruncate64
  %define __NEED_simple_syscall3_AL
  %ifdef __MULTIOS__
    %define __NEED_mini___M_lseek64_linux
  %endif
%endif
%ifdef __NEED_mini_malloc_simple_unaligned
  %define __NEED_simple_syscall3_AL
%endif
; TODO(pts): Add more if needed.

%ifdef __NEED_mini_lseek
global mini_lseek
mini_lseek:  ; off_t mini_lseek(int fd, off_t offset, int whence);
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		mov al, 19  ; Linux i386 SYS_lseek.
		jmp short simple_syscall3_AL
    .freebsd:
  %endif
		push dword [esp+3*4]  ; Argument whence of lseek and sys_freebsd6_lseek.
		mov eax, [esp+3*4]  ; Argument offset of lseek.
		cdq  ; Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
		push edx  ; High dword of argument offset of sys_freebsd6_lseek.
		push eax  ; Low dword of argument offset of sys_freebsd6_lseek.
		push eax ; Dummy argument pad of sys_freebsd6_lseek.
		push dword [esp+5*4]  ; Argument fd of lseek and sys_freebsd6_lseek.
		mov al, 199  ; FreeBSD SYS_freebsd6_lseek (also available in FreeBSD 3.0, released on 1998-10-16), with 64-bit offset.
		call simple_syscall3_AL
		test eax, eax
		js short .bad
		test edx, edx
		jz short .done
  .bad:		or eax, byte -1  ; Report error unless result fits to 31 bits, unsigned.
		cdq  ; EDX := -1. Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
  .done:	add esp, byte 5*4  ; Clean up arguments of sys_freebsd6_lseek(...) above from the stack.
		ret
%endif

%ifdef __NEED_mini_time
global mini_time
mini_time:  ; time_t mini_time(time_t *tloc);
  %ifdef __MULTIOS__  ; Already done.
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		mov al, 13  ; Linux i386 SYS_time.
		jmp short simple_syscall3_AL
		; Alternatively, Linux i386 SYS_gettimeofday would also work, but SYS_time may be faster.
    .freebsd:
  %endif
		push eax  ; tv_usec output.
		push eax  ; tv_sec output.
		mov eax, esp
		push byte 0  ; Argument tz of gettimeofday (NULL).
		push eax  ; Argument tv of gettimeofday.
		mov al, 116  ; FreeBSD i386 SYS_gettimeofday.
  ;%ifdef __MULTIOS__  ; Already done.
  ;		cmp byte [mini___M_is_freebsd], 0
  ;		jne short .freebsd
  ;		mov al, 78  ; Linux i386 SYS_gettimeofday.
  ;  .freebsd:
  ;%endif
		call simple_syscall3_AL
		pop eax  ; Argument tv of gettimeofday.
		pop eax  ; Argument tz of gettimeofday.
		pop eax  ; tv_sec.
		pop edx  ; tv_usec (ignored).
		mov edx, [esp+4]  ; tloc.
		test edx, edx
		jz .ret
		mov [edx], eax
.ret:		ret
%endif

%ifdef __NEED_mini_open
  %ifndef __MULTIOS__
    %define __NEED_mini___M_fopen_open
    %undef __NEED_mini_open
    global mini_open
    mini_open:  ; int mini_open(const char *pathname, int flags, mode_t mode);
  %endif
%endif
%ifdef __NEED_mini_open_largefile
  %ifndef __MULTIOS__
    %define __NEED_mini___M_fopen_open
    %undef __NEED_mini_open_largefile
    global mini_open_largefile
    mini_open_largefile:  ; int mini_open(const char *pathname, int flags, mode_t mode);
  %endif
%endif
%ifdef __NEED_mini___M_fopen_open
  %ifndef __NEED_mini_open
    global mini___M_fopen_open
    mini___M_fopen_open:  ; int mini___M_fopen_open(const char *pathname, int flags, mode_t mode);
		mov al, 5  ; FreeBSD i386 and Linux i386 SYS_open.
    %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		je .flags_done
		lea edx, [esp+2*4]  ; Address of flags argument.
		; This only fixes the flags with which mini_fopen(...) calls mini_open(...). The other flags value is O_RDONLY, which doesn't have to be changed.
		cmp word [edx], 1101o  ; flags: Linux   (O_WRONLY | O_CREAT | O_TRUNC) == (1 | 100o | 1000o).
		jne .flags_done
		mov word [edx], 0x601  ; flags: FreeBSD (O_WRONLY | O_CREAT | O_TRUNC) == (1 | 0x200 | 0x400) == 0x601. In the SYSV i386 calling convention, it's OK to modify an argument on the stack.
      .flags_done:
    %endif
		jmp short simple_syscall3_AL
  %endif
%endif

%ifdef __NEED_mini_ftruncate
global mini_ftruncate
mini_ftruncate:  ; int mini_ftruncate(int fd, off_t length);
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		mov al, 93  ; Linux i386 SYS_ftruncate. Supported on Linux >=1.0.
		jmp short simple_syscall3_AL
    .freebsd:
  %endif
		mov eax, [esp+2*4]  ; Argument length.
		cdq  ; EDX:EAX = sign_extend(EAX).
		push edx
		push eax
		push eax  ; Arbitrary pad value.
		push dword [esp+4*4]  ; Argument fd.
		;mov eax, 130  ; FreeBSD old ftruncate(2) wit 32-bit offset. int ftruncate(int fd, long length); }.
		mov al, 201  ; FreeBSD ftruncate(2) with 64-bit offset. FreeBSD 3.0 already had it. int ftruncate(int fd, int pad, off_t length); }
		call simple_syscall3_AL
		add esp, byte 4*4  ; Clean up arguments above.
		ret
%endif

; TODO(pts): Make at least one function fall through to simple_syscall3_AL.

%ifdef __NEED_simple_syscall3_AL
; Input: syscall number in AL, up to 3 arguments on the stack (__cdecl).
; It assumes same syscall number and behavior for FreeBSD i386 and Linux i386.
simple_syscall3_AL:
		movzx eax, al
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		push ebx  ; Save.
		mov ebx, [esp+2*4]  ; Argument fd.
		mov ecx, [esp+3*4]  ; Argument buf.
		mov edx, [esp+4*4]  ; Argument count.
		int 0x80  ; Linux i386 syscall.
		pop ebx  ; Restore.
		test eax, eax
		; Sign check is good for most syscalls, but not time(2) or mmap2(2).
		; For mmap2(2), do: cmp eax, -0x100 ++ jna .final_result
		jns .ok_linux
    %ifdef __NEED_mini_errno
		neg eax
		mov [mini_errno], eax
    %endif
		or eax, byte -1  ; EAX := -1 (ignore -errnum value).
.ok_linux:	ret
.freebsd:
  %endif
		int 0x80  ; FreeBSD i386 syscall.
		jnc .ok
  %ifdef __NEED_mini_errno
		mov [mini_errno], eax
  %endif
		sbb eax, eax  ; EAX := -1, indicating error.
.ok:
%endif
WEAK..mini___M_start_isatty_stdin:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_isatty_stdout:  ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_stdout:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_opened:   ; Fallback, tools/elfofix will convert it to a weak symbol.
		ret

%ifdef __NEED_mini_write
global mini_write
mini_write:  ; ssize_t mini_write(int fd, const void *buf, size_t count);
		mov al, 4  ; FreeBSD i386 and Linux i386 SYS_write.
		jmp short simple_syscall3_AL
%endif

%ifdef __NEED_mini_read
global mini_read
mini_read:  ; ssize_t mini_read(int fd, void *buf, size_t count);
		mov al, 3  ; FreeBSD i386 and Linux i386 SYS_read.
		jmp short simple_syscall3_AL
%endif

%ifdef __NEED_mini_close
global mini_close
mini_close:  ; int mini_close(int fd);;
		mov al, 6  ; FreeBSD i386 and Linux i386 SYS_close.
		jmp short simple_syscall3_AL
%endif

%ifdef __NEED_mini_remove
  global mini_remove
  mini_remove:  ; int mini_remove(const char *pathname);
  %define __DO_mini_unlink
%endif
%ifdef __NEED_mini_unlink  ; Also true if: ifdef __NEED_mini_remove.
  global mini_unlink
  mini_unlink:  ; int mini_unlink(const char *pathname);
  %define __DO_mini_unlink
%endif
%ifdef __DO_mini_unlink
		mov al, 10  ; FreeBSD i386 and Linux i386 SYS_unlink.
		jmp short simple_syscall3_AL
%endif

; --- No more instances of `jmp short simple_syscall3_AL', so we don't have to enforce `short'.

%ifdef __NEED_mini_open
  global mini_open
  mini_open:  ; int mini_open(const char *pathname, int flags, mode_t mode);
  %ifdef __NEED_mini___M_fopen_open
    global mini___M_fopen_open
    mini___M_fopen_open:  ; int mini___M_fopen_open(const char *pathname, int flags, mode_t mode);
  %endif
  %ifndef __MULTIOS__
    %error MULTIOS_NEEDED_FOR_MINI_OPEN
    db 1/0
  %endif
  ; Symbol       Linux   FreeBSD
  ; ----------------------------
  ; O_CREAT        0x40   0x0200
  ; O_TRUNC       0x200   0x0400
  ; O_EXCL         0x80   0x0800
  ; O_NOCTTY      0x100   0x8000
  ; O_APPEND      0x400        8
  ; O_LARGEFILE  0x8000        0
  %macro open_test_or 4
    test %1, %2
    jz short %%unset
    and %1, ~(%2)
    or %3, %4
    %%unset:
  %endm
		mov eax, [esp+2*4]  ; Get argument flags.
		mov edx, eax
		cmp byte [mini___M_is_freebsd], 0
		je .flags_done
		and edx, byte 3  ; O_ACCMODE.
		and eax, strict dword ~(0x8003)  ; ~(O_ACCMODE|O_LARGEFILE).
		open_test_or al, 0x40, dh, 2  ; O_CREAT.
		open_test_or al, 0x80, dh, 8  ; O_EXCL.
		xchg al, ah  ; Save a few bytes below: operations on al are shorter than on ah.
		open_test_or al, 1, dh, 0x80  ; O_NOCTTY.
		open_test_or al, 2, dh, 4  ; O_TRUNC.
		open_test_or al, 4, dl, 8  ; O_APPEND.
		test eax, eax
		jz short .flags_done  ; Jump if all flags converted correctly.
  %ifdef __NEED_mini_errno
		push byte 22  ; Linux EINVAL.
		pop dword [mini_errno]
  %endif
		or eax, byte -1
		ret
    .flags_done:
		push dword [esp+3*4]  ; Copy argument mode.
		push edx  ; Modified argument flags.
		push dword [esp+3*4]  ; Copy argument pathname.
		mov al, 5
		call simple_syscall3_AL
		add esp, byte 3*4  ; Clean up stack of simple_syscall3_AL.
		ret
%endif

%ifdef __NEED_mini_open_largefile
global mini_open_largefile
mini_open_largefile:  ; char *mini_open_largefile(const char *pathname, int flags, mode_t mode);  /* Argument mode is optional. */
		push dword [esp+3*4]  ; Argument mode.
		mov eax, [esp+3*4]  ; Argument flags.
		or ah, 0x80  ; Add O_LARGEFILE (Linux i386).
		push eax
		push dword [esp+3*4]  ; Argument pathname.
		call mini_open
		add esp, byte 3*4  ; Clean up arguments of open above.
		ret
%endif

%ifdef __NEED_mini_isatty
global mini_isatty
mini_isatty:  ; int mini_isatty(int fd);
		sub esp, strict byte 0x2c  ; 0x2c is the maximum sizeof(struct termios) for Linux (0x24) and FreeBSD (0x2c).
		push esp  ; 3rd argument of ioctl TCGETS.
		push strict dword 0x402c7413  ; Change assumed Linux TCGETS (0x5401) to FreeBSD TIOCGETA (0x402c7413).
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		pop eax  ; Clean up previous push.
		push strict dword 0x5401  ; TCGETS. The syscall will change it to TIOCGETA for FreeBSD.
    .freebsd:
  %endif
		push dword [esp+0x2c+4+2*4]  ; fd argument of ioctl.
		mov al, 54  ; FreeBSD i386 and Linux i386 SYS_ioctl.
		call simple_syscall3_AL
		add esp, strict byte 0x2c+3*4  ; Clean up everything pushed.
		; Now convert result EAX: -1 to 0, everything else to 1. TODO(pts): Can we assume that FreeBSD TIOCGETA returns 0 here?
		inc eax
		jz .have_retval
		xor eax, eax
		inc eax
.have_retval:
%endif

%ifdef __NEED_mini_lseek64
global mini_lseek64
mini_lseek64:  ; off64_t mini_lseek64(int fd, off64_t offset, int whence);
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne short .freebsd
		push ebx
		push esi
		push edi
		push ebx  ; High dword of result.
		push ebx  ; Low dword of result.
		xor eax, eax
		mov al, 140  ; Linux i386 SYS__llseek. Needs Linux >=1.2. We do a fallback later.
		mov ebx, [esp+0x14+4]  ; Argument fd.
		mov edx, [esp+0x14+8]  ; Argument offset (low dword).
		mov ecx, [esp+0x14+0xc]  ; Argument offset (high dword).
		mov esi, esp  ; &result.
		mov edi, [esi+0x14+0x10]  ; Argument whence.
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		jns short .ok  ; It's OK to check the sign bit, SYS__llseek won't return negative values as success.
		cmp eax, byte -38  ; Linux -ENOSYS. We get it if the kernel doesn't support SYS__llseek. Typically this happens for Linux <1.2.
		jne short .bad_linux
		; Try SYS_lseek. It works on Linux 1.0. Only Linux >=1.2 provides SYS__llseek.
		mov eax, [esp+0x14+8]  ; Argument offset (low word).
		cdq  ; EDX:EAX = sign_extend(EAX).
		cmp edx, [esp+0x14+0xc]  ; Argument offset (high word).
		xchg ecx, eax  ; ECX := argument offset (low word); EAX := junk.
		push byte -22  ; Linux i386 -EINVAL.
		pop eax
		jne .bad_linux  ; Jump iff computed offset high word differs from the actual one.
		;mov ebx, [esp+0x14+4]  ; Argument fd. Not needed, it already has that value.
		mov edx, [esp+0x14+0x10]  ; Argument whence.
		push byte 19  ; Linux i386 SYS_lseek.
		pop eax
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		jns short .done  ; It's OK to check the sign bit, SYS_llseek won't return negative values as success, because it doesn't support files >=2 GiB.
    .bad_linux:
  %ifdef __NEED_mini_errno
		neg eax
		mov [mini_errno], eax  ; Linux errno.
  %endif
		or eax, byte -1  ; EAX := -1 (error).
		cdq  ; EDX := -1. Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
		jmp short .bad_ret
    .ok:	lodsd  ; High dword of result.
		mov edx, [esi]  ; Low dword of result.
    .done:	pop ebx  ; Discard low word of SYS__llseek result.
		pop ebx  ; Discard high word of SYS__llseek result.
		pop edi
		pop esi
		pop ebx
		ret
    .freebsd:
  %endif
		push dword [esp+4*4]  ; Argument whence of lseek and sys_freebsd6_lseek.
		push dword [esp+4*4]  ; High dword of argument offset of lseek.
		push dword [esp+4*4]  ; Low dword of argument offset of lseek.
		push eax ; Dummy argument pad of sys_freebsd6_lseek.
		push dword [esp+5*4]  ; Argument fd of lseek and sys_freebsd6_lseek.
		xor eax, eax
		mov al, 199  ; FreeBSD SYS_freebsd6_lseek (also available in FreeBSD 3.0, released on 1998-10-16), with 64-bit offset.
		push eax  ; Dummy return address needed by FreeBSD i386 syscall.
		int 0x80  ; FreeBSD i386 syscall.
		lea esp, [esp+6*4]  ; Clean up arguments above from stack, without affecting the flags.
		jnc short .ret
  .bad:
  %ifdef __NEED_mini_errno
		mov [mini_errno], eax  ; FreeBSD errno.
  %endif
  .bad_ret:	or eax, byte -1  ; EAX := -1. Report error unless result fits to 31 bits, unsigned.
		cdq  ; EDX := -1. Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
  .ret:		ret
%endif

%ifdef __NEED_mini___M_lseek64_linux
  global mini___M_lseek64_linux
  %ifdef __NEED_mini_lseek64
    mini___M_lseek64_linux: equ mini_lseek64
  %else
    mini___M_lseek64_linux:
		push ebx
		push esi
		push edi
		push ebx  ; High dword of SYS__llseek result.
		push ebx  ; Low  dword of SYS__llseek result.
		xor eax, eax
		mov al, 140  ; SYS__llseek.
		mov ebx, [esp+0x14+4]  ; Argument fd.
		mov edx, [esp+0x14+8]  ; Argument offset (low dword).
		mov ecx, [esp+0x14+0xc]  ; Argument offset (high dword).
		mov esi, esp  ; &result.
		mov edi, [esi+0x14+0x10]  ; Argument whence.
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		js short .bad  ; It's OK to check the sign bit, SYS__llseek won't return negative values as success.
    .ok:	lodsd  ; High dword of result.
		mov edx, [esi]  ; Low dword of result.
		jmp short .done
    .bad:
  %ifdef __NEED_mini_errno
		neg eax
		mov [mini_errno], eax  ; Linux errno.
  %endif
		or eax, byte -1  ; EAX := -1 (error).
		cdq  ; EDX := -1. Sign-extend EAX (32-bit offset) to EDX:EAX (64-bit offset).
    .done:	pop ebx  ; Discard low  word of SYS__llseek result.
		pop ebx  ; Discard high word of SYS__llseek result.
		pop edi
		pop esi
		pop ebx
		ret
  %endif
%endif

%ifdef __NEED_mini_ftruncate64
  ;%define DEBUG_SKIP_SYS_FTRUNCATE64
  ;%define DEBUG_SKIP_SYS_FTRUNCATE
  global mini_ftruncate64
  mini_ftruncate64:  ; int mini_ftruncate64(int fd, off64_t length);
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		je short .linux
    .freebsd:
  %endif
		mov al, 201  ; FreeBSD ftruncate(2) with 64-bit offset. FreeBSD 3.0 already had it. int ftruncate(int fd, int pad, off_t length); }
		;mov eax, 130  ; FreeBSD old ftruncate(2) wit 32-bit offset. int ftruncate(int fd, long length); }.
		push dword [esp+3*4]  ; High word of argument length.
		push dword [esp+3*4]  ; Low word of argument length.
		push eax  ; Arbitrary pad value.
		push dword [esp+4*4]  ; Argument fd.
		call simple_syscall3_AL
		add esp, byte 4*4  ; Clean up arguments above.
		ret
  %ifdef __MULTIOS__
    .linux:	push ebx  ; Save.
		push esi  ; Save.
		push edi  ; Save.
		xor eax, eax
		mov al, 194  ; Linux i386 ftruncate64(2). Needs Linux >=2.4.
		mov ebx, [esp+4*4]  ; Argument fd.
		mov ecx, [esp+5*4]  ; Low  word of argument length.
		mov edx, [esp+6*4]  ; High word of argument length.
    %ifndef DEBUG_SKIP_SYS_FTRUNCATE64
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		jns short .done_linux  ; It's OK to check the sign bit, SYS__llseek won't return negative values as success.
		cmp eax, byte -38  ; Linux -ENOSYS. We get it if the kernel doesn't support SYS__llseek. Typically this happens for Linux <1.2.
		jne short .bad_linux
    %endif
		; Try SYS_ftruncate. It works on Linux 1.0. Only Linux >=2.4 provides SYS_ftruncate(2).
		xchg ecx, eax  ; EAX := argument offset (low word); ECX := junk.
		cdq  ; EDX:EAX = sign_extend(EAX).
		cmp edx, [esp+6*4]  ; Argument offset (high word).
		xchg ecx, eax  ; ECX := argument offset (low word); EAX := junk.
		push byte -22  ; Linux i386 -EINVAL.
		pop eax
    %ifndef DEBUG_SKIP_SYS_FTRUNCATE
		je short .ftruncate_linux  ; Jump iff computed offset high word is the same as the actual one.
    %endif
    .fallback_linux:  ; Now we fall back to greowing the file using mini_lseek64(...) + SYS_write of 1 byte.
		push byte 1  ; Argument whence: SEEK_CUR.
		push byte 0  ; High word of argument length.
		push byte 0  ; Low  word of argument length.
		push ebx  ; Argument fd.
		call mini___M_lseek64_linux
		add esp, byte 4*4  ; Clean up arguments of mini___M_lseek64_linux above.
		test edx, edx
		js short .done_linux
		mov esi, edx
		xchg edi, eax  ; ESI:EDI := previous file position; EAX := junk.
		push byte 2  ; Argument whence: SEEK_END.
		push byte 0  ; High word of argument length.
		push byte 0  ; Low  word of argument length.
		push ebx  ; Argument fd.
		call mini___M_lseek64_linux
		add esp, byte 4*4  ; Clean up arguments of mini___M_lseek64_linux above.
		jmp short .fallback_linux2
    .ftruncate_linux:
		;mov ebx, [esp+2*4]  ; Argument fd. Not needed, it already has that value.
		;mov ecx, [esp+3*4]  ; Low word of argument length. Not needed, it already has that value.
		push byte 93  ; Linux i386 SYS_ftruncate.
		pop eax
		int 0x80  ; Linux i386 syscall.
		test eax, eax
		jns short .done_linux  ; It's OK to check the sign bit, SYS_llseek won't return negative values as success, because it doesn't support files >=2 GiB.
    .bad_linux:
    %ifdef __NEED_mini_errno
		neg eax
		mov [mini_errno], eax  ; Linux errno.
    %endif
		or eax, byte -1  ; EAX := -1 (error).
    .done_linux:
		pop edi  ; Restore.
		pop esi  ; Restore.
		pop ebx  ; Restore.
		ret
    .fallback_linux2:
		test edx, edx
		js short .done_linux
		cmp edx, [esp+6*4]  ; High word of argument length.
		ja short .enosys_linux  ; The caller wants use to shrink the file, this fallback implementation can't do that.
		jne .grow_linux
		cmp eax, [esp+5*4]  ; Low word of argument length.
		ja short .enosys_linux  ; The caller wants use to shrink the file, this fallback implementation can't do that.
		je short .seek_back_linux
    .grow_linux:
		mov edx, [esp+6*4]  ; High word of argument length.
		mov eax, [esp+5*4]  ; Low word of argument length.
		dec eax
		jnz .cont1_linux
		dec edx
    .cont1_linux:
		push byte 0  ; Argument whence: SEEK_SET.
		push edx  ; High word of argument length.
		push eax  ; Low  word of argument length.
		push ebx  ; Argument fd.
		call mini___M_lseek64_linux
		add esp, byte 4*4  ; Clean up arguments of mini___M_lseek64_linux above.
		test edx, edx
		js short .done_linux
    .write1_linux:  ; Now write a NUL byte.
		push byte 0  ; Buffer containing a single NUL byte.
		mov ecx, esp
		push byte 1  ; Argument count of SYS_write.
		push ecx  ; Argument buf of SYS_write.
		push ebx  ; Argument fd of SYS_write.
		mov al, 4  ; Linux i386 SYS_write.
		call simple_syscall3_AL
		add esp, byte 3*4+4  ; Clean up arguments of simple_syscall3_AL above and also the buffer.
		test eax, eax
		js short .done_linux
    .seek_back_linux:
		push byte 0  ; Argument whence: SEEK_SET.
		push esi  ; High word of argument length.
		push edi  ; Low  word of argument length.
		push ebx  ; Argument fd.
		call mini___M_lseek64_linux
		add esp, byte 4*4  ; Clean up arguments of mini___M_lseek64_linux above.
		test edx, edx
		js short .done_linux
		xor eax, eax  ; Indicate success by returning 0 in EDX:EAX.
		jmp short .done_linux
    %ifdef __NEED_mini_errno
      .enosys_linux:
		push byte -38  ; Linux i386 -ENOSYS.  ; !!! Omit this if no __NEED_mini_errno.
		pop eax
		jmp short .bad_linux
    %else
      .enosys_linux: equ .bad_linux
    %endif
  %endif
%endif

%ifdef __NEED_mini_malloc_simple_unaligned
extern _end  ; Set to end of .bss by GNU ld(1).
PROT:  ; Symbolic constants for Linux and FreeBSD mmap(2).
.READ: equ 1
.WRITE: equ 2
;
MAP:  ; Symbolic constants for Linux and FreeBSD mmap(2).
.PRIVATE: equ 2
.FIXED: equ 0x10
.ANONYMOUS_LINUX: equ 0x20
.ANONYMOUS_FREEBSD: equ 0x1000
global mini_malloc_simple_unaligned
mini_malloc_simple_unaligned:  ; void *mini_malloc_simple_unaligned(size_t size);
; Implemented using sys_brk(2). Equivalent to the following C code, but was
; size-optimized.
;
; A simplistic allocator which creates a heap of 64 KiB first, and then
; doubles it when necessary. It is implemented using Linux system call
; brk(2), exported by the libc as sys_brk(...). free(...)ing is not
; supported. Returns an unaligned address (which is OK on x86).
;
; void *mini_malloc_simple_unaligned(size_t size) {
;     static char *base, *free, *end;
;     ssize_t new_heap_size;
;     if ((ssize_t)size <= 0) return NULL;  /* Fail if size is too large (or 0). */
;     if (!base) {
;         if (!(base = free = (char*)sys_brk(NULL))) return NULL;  /* Error getting the initial data segment size for the very first time. */
;         new_heap_size = 64 << 10;  /* 64 KiB. */
;         goto grow_heap;  /* TODO(pts): Reset base to NULL if we overflow below. */
;     }
;     while (size > (size_t)(end - free)) {  /* Double the heap size until there is `size' bytes free. */
;         new_heap_size = (end - base) >= (1 << 20) ? (end - base) + (1 << 20) : (end - base) << 1;  /* Double it until 1 MiB. */
;       grow_heap:
;         if ((ssize_t)new_heap_size <= 0 || (size_t)base + new_heap_size < (size_t)base) return NULL;  /* Heap would be too large. */
;         if ((char*)sys_brk(base + new_heap_size) != base + new_heap_size) return NULL;  /* Out of memory. */
;         end = base + new_heap_size;
;     }
;     free += size;
;     return free - size;
; }
  %define _BASE edi
  %define _FREE edi+4
  %define _END edi+8
  %define _IS_FREEBSD esi
		mov eax, [esp+4]  ; Argument named size.
		push ebx
		push edi  ; Save.
		mov edi, _malloc_simple_base
  %ifdef __MULTIOS__
		push esi  ; Save.
		mov esi, mini___M_is_freebsd
  %endif
		test eax, eax
		jle near .18
		mov ebx, eax
		cmp dword [_BASE], byte 0
		jne .7
		mov eax, _end  ; Address after .bss.
		add eax, 0xfff
		and eax, ~0xfff
		times 3 stosd  ; mov [_FREE], eax ++ mov [_BASE], eax ++ mov [_END], eax  ; Setting [_END] is needed by FreeBSD.
		sub edi, byte 3*4  ; Set it back to _BASE.
		mov eax, 0x10000  ; 64 KiB minimum allocation.
  .9:		add eax, [_BASE]
		jc .18
		push eax  ; Save new dword [_END] value.
		mov edx, [_END]
		push edx  ; Save old dword [_END] value.
		sub eax, edx
		xor ecx, ecx
  %ifdef __MULTIOS__
		cmp byte [_IS_FREEBSD], 0
		jne short .freebsd2
		push ecx  ; offset == 0.
		push strict byte -1 ; fd.
		push strict byte MAP.PRIVATE|MAP.ANONYMOUS_LINUX|MAP.FIXED  ; flags.
		push strict byte PROT.READ|PROT.WRITE  ; prot.
		push eax  ; length. Rounded to page boundary.
		push edx  ; addr. Rounded to page boundary.
		push esp  ; buffer, to be passed to sys_mmap(...).
		mov al, 90  ; Linux i386 SYS_mmap.
		call simple_syscall3_AL	; It destroys ECX and EDX.
		add esp, byte 7*4  ; Clean up arguments  of SYS_mmap above.
		jmp short .done2
  %endif
    .freebsd2:  ; caddr_t freebsd6_mmap(caddr_t addr, size_t length, int prot, int flags, int fd, int pad, off_t offset);  /* 197 for FreeBSD. */
		push ecx  ; High dword of argument offset of freebsd6_mmap == 0.
		push ecx  ; Low dword of argument offset of freebsd6_mmap == 0.
		push ecx  ; Argument pad of freebsd6_mmap == 0.
		push strict byte -1  ; Argument fd of freebsd6_mmap == -1.
		push strict dword MAP.PRIVATE|MAP.ANONYMOUS_FREEBSD|MAP.FIXED  ; Argument flags of freebsd6_mmap.
		push strict byte PROT.READ|PROT.WRITE  ; Argument prot of freebsd6_mmap.
		push eax  ; Argument length of freebsd6_mmap. No need to manually round up to page boundary for FreeBSD. But it's rounded anyway.
		push edx  ; Argument addr of freebsd6_mmap. Rounded to page boundary.
		mov al, 197  ; FreeBSD i386 SYS_freebsd6_mmap (also available in FreeBSD 3.0, released on 1998-10-16), with 64-bit offset.
		call simple_syscall3_AL	; It destroys ECX and EDX.
		add esp, byte 8*4  ; Clean up arguments  of SYS_mmap above.
  %ifdef __MULTIOS__
    .done2:
  %endif
		pop edx  ; Restore old dword [_END] value.
		cmp eax, edx  ; Compare actual return value (EAX) to expected old dword [_END] value.
		pop eax  ; Restore new dword [_END].
		jne .18
		mov [_END], eax
  .7:		mov edx, [_END]
		mov eax, [_FREE]
		mov ecx, edx
		sub ecx, eax
		cmp ecx, ebx
		jb .21
		add ebx, eax
		mov [_FREE], ebx
		jmp short .done
  .21:		sub edx, [_BASE]
		mov eax, 1<<20  ; 1 MiB.
		cmp edx, eax
  %ifdef CONFIG_I386
		jnbe .22
		mov eax, edx
    .22:
  %else
		cmovbe eax, edx
  %endif  ; else CONFIG_I386
		add eax, edx
		test eax, eax  ; ZF=..., SF=..., OF=0.
		jg .9  ; Jump iff ZF=0 and SF=OF=0. Why is this correct?
  .18:		xor eax, eax
  .done:
  %ifdef __MULTIOS__
		pop esi  ; Restore.
  %endif
		pop edi
		pop ebx
		ret
%endif

section .bss align=4
%ifdef __NEED_mini_environ
global mini_environ
mini_environ:	resd 1  ; char **mini_environ;
%endif
%ifdef __NEED_mini_malloc_simple_unaligned
_malloc_simple_base: resd 1  ; char *base;
_malloc_simple_free: resd 1  ; char *free; Must come after _malloc_simple_base.
_malloc_simple_end:  resd 1  ; char *end;  Must come after _malloc_simple_end.
%endif
%ifdef __MULTIOS__
global mini___M_is_freebsd
mini___M_is_freebsd: resb 1  ; Are we actually running under FreeBSD (rathar than Linux)?
%endif

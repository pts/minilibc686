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
;mini__start:  ; Entry point (_start) of the Linux i386 executable.
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
%ifdef __MULTIOS__  ; Set by minicc.sh if Linux support is needed in addition to FreeBSD.
		xor eax, eax
		mov al, 20		; EAX := __NR_getpid for both Linux and FreeBSD.
		stc			; CF := 1.
		int 0x80		; Linux and FreeBSD i386 syscall.
		sbb eax, eax		; FreeBSD set s CF := 0 on success, Linux keeps it intact (== 1). EAX := 0 in FreeBSD, -1 on Linux.
		inc eax			; EAX := 1 in FreeBSD, 0 on Linux.
		mov [mini___M_is_freebsd], al
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
%ifdef __NEED_mini_malloc_simple_unaligned
  %define __NEED_simple_syscall3_AL
%endif
; TODO(pts): Add more if needed.

%ifdef __NEED_mini_lseek
global mini_lseek
mini_lseek:  ; off_t mini_lseek(int fd, off_t offset, int whence);
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne .freebsd
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
		js .bad
		test edx, edx
		jz .done
  .bad:		or eax, -1  ; Report error unless result fits to 31 bits, unsigned.
  		mov edx, eax
  .done:	add esp, byte 5*4  ; Clean up arguments of sys_freebsd6_lseek(...) above from the stack.
		ret
%endif

%ifdef __NEED_mini_time
global mini_time
mini_time:  ; time_t mini_time(time_t *tloc);
  %ifdef __MULTIOS__  ; Already done.
  		cmp byte [mini___M_is_freebsd], 0
  		jne .freebsd
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
  ;		jne .freebsd
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

%ifdef __NEED_simple_syscall3_AL
; Input: syscall number in AL, up to 3 arguments on the stack (__cdecl).
; It assumes same syscall number and behavior for FreeBSD i386 and Linux i386.
simple_syscall3_AL:
		movzx eax, al
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne .freebsd
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
		mov [mini_errno], eax
    %endif
		or eax, -1  ; EAX := -1 (ignore -errnum value).
.ok_linux:	ret
.freebsd:
  %endif
		int 0x80  ; FreeBSD i386 syscall.
		jnc .ok
  %ifdef __NEED_mini_errno
		mov [mini_errno], eax
  %endif
		sbb eax, eax  ; EAX := -1, indicating error.
.ok:		ret
%endif

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

%ifdef __NEED_mini___M_fopen_open
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

%ifdef __NEED_mini_close
global mini_close
mini_close:  ; int mini_close(int fd);;
		mov al, 6  ; FreeBSD i386 and Linux i386 SYS_close.
		jmp short simple_syscall3_AL
%endif

%ifdef __NEED_mini_remove
global mini_remove
mini_remove:  ; int mini_remove(const char *pathname);
%endif
%ifdef __NEED_mini_unlink  ; Also true if: ifdef __NEED_mini_remove.
global mini_unlink
mini_unlink:  ; int mini_unlink(const char *pathname);
%endif
		mov al, 10  ; FreeBSD i386 and Linux i386 SYS_unlink.
		jmp short simple_syscall3_AL

%ifdef __NEED_mini_isatty
global mini_isatty
mini_isatty:  ; int mini_isatty(int fd);
		sub esp, strict byte 0x2c  ; 0x2c is the maximum sizeof(struct termios) for Linux (0x24) and FreeBSD (0x2c).
		push esp  ; 3rd argument of ioctl TCGETS.
		push strict dword 0x402c7413  ; Change assumed Linux TCGETS (0x5401) to FreeBSD TIOCGETA (0x402c7413).
  %ifdef __MULTIOS__
		cmp byte [mini___M_is_freebsd], 0
		jne .freebsd
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
WEAK..mini___M_start_isatty_stdin:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_isatty_stdout:  ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_stdout:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_opened:   ; Fallback, tools/elfofix will convert it to a weak symbol.
		ret

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
		jne .freebsd2
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

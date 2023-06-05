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
; !! TODO(pts): Make strtod and strtol set errno if errno is used by the program.
;

; --- NASM magic infrastructure.

%ifndef UNDEFSYMS
  %error Expecting UNDEFSYMS from minicc -msmart.
  times 1/0 nop
%endif
;%ifnidn __OUTPUT_FORMAT__, elf
;  %error Expecting -f elf for minicc -msmart.
;  times 1/0 nop
;%endif

bits 32
%ifdef CONFIG_I386
  cpu 386
%else
  cpu 686
%endif

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
%macro _syscall 2
  %ifdef __NEED_mini_%1
    %define __NRM_mini_%1 %2  ; Save syscall number.
    %xdefine SYSCALLS SYSCALLS,mini_%1  ; Remember syscall name for _emit_syscalls.
    %if %2>255
      %define __NEED_mini_syscall3_RP1
    %else
      %define __NEED_mini_syscall3_AL
    %endif
  %endif
%endmacro

%macro _emit_syscalls 0-*
  %rep %0
    %ifnidn %1_, _  ; `%ifnidn $1,' doesn't work, so we append `_'.
      global %1
      %1:
      %if __NRM_%1>255
        mov eax, __NRM_%1
        %if 1  ; !!! $+2-syscall3_EAX>128
        jmp strict short syscall3_EAX  ; `short' to make sure that the jump is 2 bytes. This lets us define about 50 different syscalls in this file.
        %endif
      %else
        mov al, __NRM_%1
        %if 1  ; !!! $+2-syscall3_AL>128
        jmp strict short syscall3_AL  ; `short' to make sure that the jump is 2 bytes. This lets us define about 50 different syscalls in this file.
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
    extern %1
    call %1
  %endif
%endmacro

; ---

_define_needs UNDEFSYMS  ; Must be called before _need and _alias.
;
_alias mini_remove, mini_unlink
%define __NEED_mini_exit
; The dependencies below must be complete for each system call defined in
; src/start_stdio_medium_linux.nasm (read(2), write(2), open(2), close(2),
; lseek(2), ioctl(2)), otherwise there will be duplicate symbols.
;
; TODO(pts): Autogenerate these dependencies.
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
_need mini_stdin,  mini___M_start_isatty_stdin
_need mini_stdout, mini___M_start_isatty_stdout
_need mini_stdout, mini___M_start_flush_stdout
_need mini_fopen, mini___M_start_flush_opened
_need mini_freopen, mini___M_start_flush_opened
_need mini_fdopen, mini___M_start_flush_opened
_need mini___M_start_isatty_stdin, mini_isatty
_need mini___M_start_isatty_stdout, mini_isatty
_need mini_isatty, mini_ioctl
_need mini___M_start_flush_stdout, mini_fflush
_need mini___M_start_flush_opened, mini_fflush
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
_need mini_getc, mini_fread
_need mini_fgetc, mini_fread
_need mini___M_fgetc_fallback_RP3, mini_fread
_need mini_fread, mini_read
_need mini_exit, mini__exit
_need mini_fopen, mini_open
_need mini_fclose, mini_close
_need mini_errno, .bss
_need mini_environ, .bss
;
_need_aliases ALIASES  ; Must be called after _alias.
;
; We have to put _syscall definitions right here, just above `_need
; mini_syscall3_AL, ...', because syscalls need mini_syscall3_AL.
;_syscall _exit, 1  ; Defined explicitly above.
; !! TODO(pts): What if it will not fit to `jmp strict short'? Automate via %assign.
_syscall fork, 2
_syscall read, 3
_syscall write, 4
_syscall open, 5
_syscall close, 6
_syscall creat, 8
_syscall unlink, 10
_syscall lseek, 19
_syscall getpid, 20
_syscall geteuid, 49
_syscall ioctl, 54
_syscall ftruncate, 93
_syscall sys__llseek, 140  ; Use mini_lseek64(...) instead, it's more convenient from C code.
;_syscall sys_mmap2, 192  ; Cannot define here, it has more than 3 arguments.
;_syscall mremap, 163  ; Cannot define here, it has more than 3 arguments.
_syscall munmap, 91
;_syscall brk, 45  ; Conflicts with brk(3).
_syscall sys_brk, 45
_syscall time, 13
_syscall gettimeofday, 78
_syscall chmod, 15
_syscall fchmod, 94
_syscall mkdir, 39
_syscall lstat64, 196
_syscall symlink, 83
_syscall umask, 60
_syscall utimes, 271
;
_need mini_syscall3_AL, mini_syscall3_RP1
_need mini_syscall3_RP1, mini___M_jmp_pop_ebx_syscall_return
_need mini___M_jmp_pop_ebx_syscall_return, mini___M_jmp_syscall_return

section .text align=1
%ifidn __OUTPUT_FORMAT__, bin  ; FAllback for size measurements.
main equ +0x12345678
%else
extern main
%endif
global mini__start
global _start
_start:
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
		pop eax  ; argc.
		mov edx, esp  ; argv.
%define CONFIG_USE_MAIN_ENVP  ; TODO(pts): Make it configurable (`minicc -mno-main-envp') that the program doesn't use envp, and omit it here.
%ifdef CONFIG_USE_MAIN_ENVP
		lea ecx, [edx+eax*4+4]  ; envp.
		push ecx  ; Argument envp for main.
  %ifdef __NEED_mini_environ
		mov [mini_environ], ecx
  %endif
%else
  %ifdef __NEED_mini_environ
		lea ecx, [edx+eax*4+4]  ; envp.
		mov [mini_environ], ecx
  %endif
%endif
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
		_call_extern_if_needed mini___M_start_isatty_stdin
		_call_extern_if_needed mini___M_start_isatty_stdout
		call main  ; Return value (exit code) in EAX (AL).
%define EXIT_IS_EMPTY 1
%ifdef __NEED_mini___M_start_flush_stdout
  %define EXIT_IS_EMPTY 0
%endif
%ifdef __NEED_mini___M_start_flush_opened
  %define EXIT_IS_EMPTY 0
%endif
%ifdef __NEED_mini_syscall3_RP1
  %define EXIT_IS_EMPTY 0
%endif
%if EXIT_IS_EMPTY==0
		push eax  ; Save exit code, for exit_AL(...).
%endif
%ifdef __NEED_mini_syscall3_RP1
		push eax  ; Fake return address, for mini__exit(...).
%endif
		; Fall through to mini_exit(...).
%ifdef __NEED_mini_exit  ; Always true.
global mini_exit
mini_exit:  ; void mini_exit(int exit_code);
		_call_extern_if_needed mini___M_start_flush_stdout
		_call_extern_if_needed mini___M_start_flush_opened
		; Fall through to mini__exit(...).
%endif
%ifdef __NEED_mini__exit  ; Always true.
global mini__exit
mini__exit:  ; void mini__exit(int exit_code);
		; Fall through to exit_AL(...) or syscall__exit(...).
%endif
%ifdef __NEED_mini_syscall3_RP1
exit_AL:	mov al, 1  ; __NR_exit.
		; Fall through to syscall3(...).
syscall3_AL:
global mini_syscall3_AL
mini_syscall3_AL:  ; Useful from assembly language.
; Calls syscall(number, arg1, arg2, arg3).
;
; It takes the syscall number from AL (8 bits only!), arg1 (optional) from
; [esp+4], arg2 (optional) from [esp+8], arg3 (optional) from [esp+0xc]. It
; keeps these args on the stack.
;
; It can EAX, EDX and ECX as scratch.
;
; It returns result (or -1 as error) in EAX.
		movzx eax, al  ; Syscall number.
global mini_syscall3_RP1
mini_syscall3_RP1:  ; long mini_syscall3_RP1(long nr, long arg1, long arg2, long arg3) __attribute__((__regparm__(1)));
syscall3_EAX:
		push ebx  ; Save it, it's not a scratch register.
		mov ebx, [esp+8]  ; arg1.
		mov ecx, [esp+0xc]  ; arg2.
		mov edx, [esp+0x10]  ; arg3.
		int 0x80  ; Linux i386 syscall.
		; Fall through to mini___M_jmp_pop_ebx_syscall_return.
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
		mov dword [mini_errno], eax  ; TODO(pts): Add this to -mno-smart.
%endif
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	ret
%endif  ; __NEED_mini___M_jmp_syscall_return
%else  ; __NEED_mini_syscall3_RP1
%if EXIT_IS_EMPTY
		xchg eax, ebx  ; EBX := exit code; EAX := junk.
%else
		pop ebx  ; Exit code.
%endif
		xor eax, eax
		inc eax  ; EAX := 1 (__NR__exit).
		int 0x80  ; Linux i386 syscall. _exit(2) doesn't return.
%endif  ; __NEED_mini_syscall3_RP1

_emit_syscalls SYSCALLS
_define_alias_syms ALIASES  ; Must be called after alias targets have been defined.

%ifdef __NEED_.bss
section .bss align=4
%endif
%ifdef __NEED_mini_errno
global mini_errno  ; TODO(pts): Add this (including populating it in syscalls) to -mno-smart.
mini_errno:	resd 1  ; int mini_errno;
%endif
%ifdef __NEED_mini_environ
section .bss
global mini_environ
mini_environ:	resd 1  ; char **mini_environ;
%endif

%ifdef __NEED_mini_stdout
%ifidn __OUTPUT_FORMAT__, bin  ; Fallback for size measurements.
mini_stdout equ +0x12345679
%else
extern mini_stdout
%endif
%endif

%ifdef __NEED_mini_fputc_RP3
%ifidn __OUTPUT_FORMAT__, bin  ; Fallback for size measurements.
mini_fputc_RP3 equ +0x1234567a
%else
extern mini_fputc_RP3
%endif
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

section .

; __END__

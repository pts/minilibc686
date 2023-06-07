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

;%define LAST_SC123EAX ...  ; Will be defined by syscall3_EAX.
;%define LAST_SC123AL  ...  ; Will be defined by syscall3_AL.
%macro _emit_syscalls 0-*
  ; TODO(pts): Put some extra syscalls in front of syscall3_EAX, to save 3 bytes on the first `jmp strict near'. This is complicated.
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

; ---

_define_needs UNDEFSYMS  ; Must be called before _need and _alias.
;
;_alias mini_remove, mini_unlink  ; `remove' defined below.
; The dependencies below must be complete for each system call defined in
; src/start_stdio_medium_linux.nasm (read(2), write(2), open(2), close(2),
; lseek(2), ioctl(2)), otherwise there will be duplicate symbols.
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
_need mini_printf, mini_vfprintf
_need mini_vprintf, mini_vfprintf
_need mini_vfprintf, mini___M_writebuf_relax_RP1
_need mini_vfprintf, mini___M_writebuf_unrelax_RP1
_need mini_vfprintf, mini_fputc_RP3
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
_need mini_fflush, mini___M_discard_buf
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
;_syscall _exit, 1  ; We don't define it here, because we emit `mini__exit:' below manually. TODO(pts): Keep exit_linux.nasm as a fallback.
; The order of the first few syscalls matches the order in src/start_stdio_medium_linux_nasm, used by demo_hello_linux_printf.nasm.
_syscall fork, 2
_syscall read, 3
_syscall write, 4
_syscall open, open2, open3, 5
_syscall close, 6
_syscall creat, 8
_syscall remove, unlink, 10
_syscall lseek, 19
_syscall getuid,  199  ; Actually, it's __NR_getuid32, for 32-bit UIDs.
_syscall geteuid, 201  ; Actually, it's __NR_geteuid32, for 32-bit UIDs.
_syscall getgid,  200  ; Actually, it's __NR_getgid32, for 32-bit GIDs.
_syscall getegid, 202  ; Actually, it's __NR_getegid32, for 32-bit GIDs.
_syscall getpid, 20
_syscall getppid, 64
_syscall ioctl, 54
_syscall ftruncate, 93
_syscall sys__llseek, 140  ; Use mini_lseek64(...) instead, it's more convenient from C code.
;_syscall sys_mmap2, 192  ; Cannot define here, it has more than 3 arguments.
;_syscall mremap, 163  ; Cannot define here, it has more than 3 arguments.
_syscall munmap, 91
_syscall_456 mremap, 163
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
_need mini_syscall, mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
_need mini_syscall3_AL, mini_syscall3_RP1
_need mini_syscall6_AL, mini_syscall6_RP1
_need mini_syscall6_RP1, mini_syscall3_RP1
_need mini_syscall6_RP1, mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return
_need mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return, mini___M_jmp_pop_ebx_syscall_return
_need mini_syscall3_RP1, mini___M_jmp_pop_ebx_syscall_return
_need mini___M_jmp_pop_ebx_syscall_return, mini___M_jmp_syscall_return
_need mini_syscall3_RP1, mini___LM_push_exit_args
_need mini__exit, mini___LM_push_exit_args

%define CLEANUP_IS_EMPTY 1
%ifdef __NEED_mini___M_start_flush_stdout
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
  %endif
%endif

section .text align=1
%ifdef __NEED_mini__start
__smart_extern main
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
%ifdef __NEED_mini___LM_push_exit_args
		push eax  ; Save exit code, for mini__exit(...).
		push eax  ; Push fake return address, for mini__exit(...).
%elifdef NEED_cleanup
		push eax  ; Save exit code, for mini__exit(...).
%endif
		; Fall through.
%endif  ; __NEED_mini_start
%ifdef __NEED_mini_exit
global mini_exit
mini_exit:  ; void mini_exit(int exit_code);
%endif
%ifdef NEED_cleanup
		_call_extern_if_needed mini___M_start_flush_stdout
		_call_extern_if_needed mini___M_start_flush_opened
		; Fall through.
%endif  ; NEED_cleanup
%ifdef __NEED_mini__exit  ; Always true.
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
		pop ebx  ; Fake or real return address of mini__exit.
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
		pop ebx  ; Fake or real return address of mini__exit.
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
; Another way: main(...) just calls mini_syscall(...) and then calls mini__exit(...).
; TODO(pts): Test both.
global mini_syscall
mini_syscall:  ; long mini_syscall(long nr, ...);  /* Supports up to 6 arguments after nr, that's the maximum on Linux. */
		push ebx
		push esi
		push edi
		push ebp
		lea esi, [esp+5*4]
		lodsd  ; EAX := syscall number (nr).
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
		int 0x80  ; Linux i386 syscall.
		; Fall through to mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return.
%elifdef __NEED_mini_syscall3_RP1  ; Load 3 syscall arguments from the stack (starting at ESP+8) to EBX, ECX, EDX.
		mov ebx, [esp+2*4]  ; arg1.
		mov ecx, [esp+3*4]  ; arg2.
		mov edx, [esp+4*4]  ; arg3.
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
		mov dword [mini_errno], eax  ; TODO(pts): Add this to -mno-smart.
  %endif
		or eax, byte -1  ; EAX := -1 (error).
  .final_result: ret
%endif  ; __NEED_mini___M_jmp_syscall_return

_emit_syscalls SYSCALLS
_define_alias_syms ALIASES  ; Must be called after alias targets have been defined.

%ifdef __NEED_.bss
section .bss align=4
%endif
%ifdef __NEED_mini_errno
global mini_errno  ; TODO(pts): Add this (including populating it in syscalls) to -mno-smart.
mini_errno:	resd 1  ; int mini_errno;
%ifdef CONFIG_PIC
%error Not PIC because it defines mini_errno.
times 1/0 nop
%endif
%endif
%ifdef __NEED_mini_environ
section .bss
global mini_environ
mini_environ:	resd 1  ; char **mini_environ;
%ifdef CONFIG_PIC
%error Not PIC because it defines mini_environ.
times 1/0 nop
%endif
%endif

%ifdef __NEED_mini_stdout
__smart_extern mini_stdout
%ifdef CONFIG_PIC
%error Not PIC because it uses mini_stdout.
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
  _include_if_needed mini_printf, "src/printf_callvf.nasm"
  _include_if_needed mini_fputc_RP3, "src/stdio_medium_fputc_rp3.nasm"
  _include_if_needed mini_stdout, "src/stdio_medium_stdout.nasm"  ; Also defines: global mini___M_start_isatty_stdout, mini___M_start_flush_stdout.
  _include_if_needed mini_vfprintf, "src/stdio_medium_vfprintf.nasm"
  _include_if_needed mini___M_writebuf_relax_RP1, mini___M_writebuf_unrelax_RP1, "src/stdio_medium_writebuf_relax.nasm"
  _include_if_needed mini_isatty, "src/isatty_linux.nasm"
  _include_if_needed mini_fflush, "src/stdio_medium_fflush.nasm"
  _include_if_needed mini___M_discard_buf, "src/stdio_medium_discard_buf.nasm"
%endif

; __END__

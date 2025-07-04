;
; written by pts@fazekas.hu at Fri May 19 17:25:38 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o start_stdio_file_linux.o start_stdio_file_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%ifdef mini__start
  global $mini__start  ; Without expanding the macro.
%endif
global mini__exit
global mini_environ
global mini_syscall3_AL
global mini_syscall3_RP1
global mini___M_jmp_pop_ebx_syscall_return
global mini___M_jmp_syscall_return
global mini_exit
global mini___M_fopen_open
global mini_open
global mini_close
global mini_read
global mini_write
global mini_lseek
global mini_ioctl

%macro define_weak 1
  %ifidn __OUTPUT_FORMAT__, bin  ; E.g. when using elf0.inc.nasm.
    %ifidn %1, mini__start
    %elifndef %1
      %define %1 WEAK..%1
    %endif
  %else
    extern %1
  %endif
%endmacro
define_weak mini___M_start_isatty_stdin
define_weak mini___M_start_isatty_stdout
define_weak mini___M_start_flush_stdout
define_weak mini___M_start_flush_opened
define_weak mini__start
define_weak $mini__start

%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
main equ +0x12345678
%ifndef CONFIG_START_STDOUT_ONLY
mini_errno equ +0x12345679
%endif
%else
extern main
; These will be converted to weak symbols by tools/elfofix.
section .text align=1
section .rodata align=1
section .data align=1
%ifndef CONFIG_START_STDOUT_ONLY
section .bss align=4
extern mini_errno
%else
section .bss align=1
%endif
%endif

section .text
%ifdef mini__start
;  $mini__start:  ; Without expanding the macro.
%else
  %ifidn __OUTPUT_FORMAT__, bin
    _start:
  %endif
%endif
WEAK.._start:
WEAK..mini__start:
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
		pop eax  ; argc.
		mov edx, esp  ; argv.
		lea ecx, [edx+eax*4+4]  ; envp.
%ifndef CONFIG_START_STDOUT_ONLY
		mov [mini_environ], ecx
%endif
		push ecx  ; Argument envp for main.
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
%ifndef CONFIG_START_STDOUT_ONLY
		call mini___M_start_isatty_stdin  ; Smart linking (smart.nasm) may omits this call.
%endif
		call mini___M_start_isatty_stdout  ; Smart linking (smart.nasm) may omits this call.
		call main  ; Return value (exit code) in EAX (AL).
		push eax  ; Save exit code, for mini__exit.
		push eax  ; Fake return address, for mini__exit.
		; Fall through to mini_exit(...).
mini_exit:  ; void mini_exit(int exit_code);
		call mini___M_start_flush_stdout  ; Smart linking (smart.nasm) may omit this call.
%ifndef CONFIG_START_STDOUT_ONLY
		call mini___M_start_flush_opened  ; Ruins EBX. Smart linking (smart.nasm) may omit this call.
%endif
		; Fall through to mini__exit(...).
mini__exit:  ; void mini__exit(int exit_code);
_exit:
		mov al, 1  ; __NR_exit.
		; Fall through to syscall3.
syscall3:
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
		movzx eax, al  ; number.
mini_syscall3_RP1:  ; long mini_syscall3_RP1(long nr, long arg1, long arg2, long arg3) __attribute__((__regparm__(1)));
		push ebx  ; Save it, it's not a scratch register.
		mov ebx, [esp+8]  ; arg1.
		mov ecx, [esp+0xc]  ; arg2.
		mov edx, [esp+0x10]  ; arg3.
		int 0x80  ; Linux i386 syscall.
mini___M_jmp_pop_ebx_syscall_return:
		pop ebx
mini___M_jmp_syscall_return:
		; test eax, eax
		; jns .final_result
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
%ifndef CONFIG_START_STDOUT_ONLY
		neg eax
		mov dword [mini_errno], eax
%endif
		or eax, byte -1  ; EAX := -1 (error).
.final_result:
WEAK..mini___M_start_isatty_stdin:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_isatty_stdout:  ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_stdout:   ; Fallback, tools/elfofix will convert it to a weak symbol.
WEAK..mini___M_start_flush_opened:   ; Fallback, tools/elfofix will convert it to a weak symbol.
		ret

; TODO(pts): Use smart linking to get rid of the unnecessary syscalls. Move everything from here, keep them in smart.nasm only.
%ifndef CONFIG_START_STDOUT_ONLY
mini_read:	mov al, 3  ; __NR_read.
		jmp strict short syscall3
%endif
mini_write:	mov al, 4  ; __NR_write.
		jmp strict short syscall3
%ifndef CONFIG_START_STDOUT_ONLY
mini___M_fopen_open:
mini_open:	mov al, 5  ; __NR_open.
		jmp strict short syscall3
mini_close:	mov al, 6  ; __NR_close.
		jmp strict short syscall3
mini_lseek:	mov al, 19  ; __NR_lseek.
		jmp strict short syscall3
%endif
mini_ioctl:	mov al, 54  ; __NR_ioctl.
		jmp strict short syscall3

%ifndef CONFIG_START_STDOUT_ONLY
section .bss
mini_environ:	resd 1  ; char **mini_environ;
%endif

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini_environ.
times 1/0 nop
%endif

; __END__

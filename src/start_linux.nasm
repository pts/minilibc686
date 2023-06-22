;
; written by pts@fazekas.hu at Tue May 16 13:56:57 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o start_linux.o start_linux.nasm
;
; This startup code doesn't flush stdio streams (filehandles) upon exit. To
; get that, use start_stdio_linux.nasm instead.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%ifdef mini__start
  global $mini__start  ; Without expanding the macro.
%endif
global mini__start
global mini__exit
global mini_exit
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
main equ +0x12345678
%else
extern main
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
%ifdef mini__start
  $mini__start:  ; Without expanding the macro.
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
		pop eax  ; argc.
		mov edx, esp  ; argv.
		lea ecx, [edx+eax*4+4]  ; envp.
		mov [mini_environ], ecx
		push ecx  ; Argument envp for main.
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
		call main  ; Return value (exit code) in EAX (AL).
		; times 3 pop edx  ; No need to clean up arguments of main on the stack.
		xor ebx, eax  ; EBX := Exit code; EAX := junk.
		jmp strict short mini_exit.ebx
mini__exit:  ; void mini__exit(int exit_code);
mini_exit:  ; void mini_exit(int exit_code);
		mov ebx, [esp+4]  ; EBX := Exit code.
.ebx:		xor eax, eax
		inc eax  ; EAX := 1 == __NR_exit.
		int 0x80  ; Linux i386 syscall, exit(2) doesn't return.
		; Not reached, the syscall above doesn't return.

section .bss
global mini_environ
mini_environ:	resd 1  ; char **mini_environ;

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini_environ.
times 1/0 nop
%endif

; __END__

;
; written by pts@fazekas.hu at Tue May 16 13:56:57 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o start_stdio_linux.o start_stdio_linux.nasm
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
mini___M_flushall equ +0x12345679
%else
extern main
extern mini___M_flushall
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
		push ecx  ; Argument envp for main.
		push edx  ; Argument argv for main.
		push eax  ; Argument argc for main.
		call main  ; Return value (exit code) in EAX (AL).
		push eax  ; Save exit code, for mini_exit.
		push eax
		; Fall through to mini_exit(...).
mini_exit:  ; void mini_exit(int exit_code);
		call mini___M_flushall  ; Flush all stdio streams.
		; Fall through to mini__exit(...).
mini__exit:  ; void mini__exit(int exit_code);
		pop ebx  ; Return address or junk.
		pop ebx  ; EBX := Exit code.
.ebx:		xor eax, eax
		inc eax  ; EAX := 1 == __NR_exit.
		int 0x80  ; Linux i386 syscall, exit(2) doesn't return.
		; Not reached, the syscall above doesn't return.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

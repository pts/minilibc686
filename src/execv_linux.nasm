;
; written by pts@fazekas.hu at Sun Jan 25 14:44:04 CET 2026
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o execv.o execv.nasm
;
; Code size: 0x28 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_execv
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_environ equ +0x12345678
mini_execve equ +0x12345679
%else
extern mini_environ
extern mini_execve
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_execv:  ; char *mini_execv(const char *path, char *const argv[]);
		push dword [mini_environ]
		push dword [esp+3*4]  ; Argument argv.
		push dword [esp+3*4]  ; Argument path.
		call mini_execve
		add esp, byte 3*4  ; Clean up arguments of mini_execv from the stack.
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini_environ.
times 1/0 nop
%endif

; __END__

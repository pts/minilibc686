;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_getchar.o stdio_medium_getchar.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_getchar
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_stdin equ +0x12345678
mini_fgetc equ +0x12345679
%else
extern mini_stdin
extern mini_fgetc
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_getchar:
		push dword [mini_stdin]
		call mini_fgetc
		pop edx  ; Clean up mini_stdin from the stack.
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__

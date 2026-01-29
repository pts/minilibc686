;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_putchar_rp3.o stdio_medium_putchar_rp3.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_putchar_RP3
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_stdout equ +0x12345678
mini_fputc_RP3 equ +0x12345679
%else
extern mini_stdout
extern mini_fputc_RP3
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_putchar_RP3:  ; int REGPARM3 mini_putchar_RP3(int c);
; src/smart.nasm is used instead of this if smart linking is active.
		mov edx, [mini_stdout]
		call mini_fputc_RP3
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__

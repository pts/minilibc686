;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_putchar.o stdio_medium_putchar.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_putchar
global mini_putchar_RP1
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_stdout equ +0x12345678
mini___M_fputc_RP2 equ +0x12345679
%else
extern mini_stdout
extern mini___M_fputc_RP2
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini_putchar:
		mov eax, [esp+4]  ; TODO(pts): Get rid of this with smart linking if unused.
mini_putchar_RP1:
		mov edx, [mini_stdout]
		call mini___M_fputc_RP2
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__

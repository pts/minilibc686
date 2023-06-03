;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_fputc.o c_stdio_medium_fputc.nasm
;

bits 32
cpu 386

global mini_putc
global mini_fputc
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fputc_RP3 equ +0x12345678
%else
extern mini_fputc_RP3
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

mini_putc:
mini_fputc:
		mov eax, [esp+4]
		mov edx, [esp+8]
		call mini_fputc_RP3
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

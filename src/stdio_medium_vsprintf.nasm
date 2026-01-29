;
; written by pts@fazkeas.hu at Tue May 23 13:37:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_vsprintf.o stdio_medium_vsprintf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_vsprintf
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_sprintf.do equ +0x12345678
%else
extern mini_sprintf.do
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_vsprintf:  ; int mini_vsprintf(char *str, const char *format, va_list ap);
		lea edx, [esp+0xc]  ; Address of ap.
		mov eax, [edx]  ; Value of ap.
		jmp strict near mini_sprintf.do

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

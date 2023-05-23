;
; written by pts@fazkeas.hu at Tue May 23 13:37:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_vsnprintf.o stdio_medium_vsnprintf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_vsnprintf
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_snprintf.do equ +0x12345678
%else
extern mini_snprintf.do
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini_vsnprintf:  ; int mini_vsnprintf(char *str, size_t size, const char *format, va_list ap);
		lea edx, [esp+4]  ; Address of argument str.
		mov eax, [edx+0xc]  ; Value of ap.
		jmp strict near mini_snprintf.do

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

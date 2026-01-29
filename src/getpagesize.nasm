;
; written by pts@fazekas.hu at Tue Jun 13 11:46:47 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o getpagesize.o getpagesize.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_getpagesize
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_getpagesize:  ; int mini_getpagesize(void);
		mov eax, 0x1000
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

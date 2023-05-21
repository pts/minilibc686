;
; written by pts@fazekas.hu at Sun May 21 16:39:01 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isspace_rp1.o isspace_rp1.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isspace_RP1
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_isspace_RP1:  ; int mini_isspace_RP1(int c) __attribute__((__regparm__(1)));
		sub al, 9  ; '\t'
		cmp al, 5  ; '\r'-'\t'+1
		jb .1
		sub al, ' '-9
		cmp al, 1
.1:		sbb eax, eax
		neg eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

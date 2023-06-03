;
; written by pts@fazekas.hu at Sun May 21 16:39:01 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tolower_rp1.o tolower_rp1.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_tolower_RP3
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
mini_tolower_RP3:  ; int mini_tolower_RP3(int c) __attribute__((__regparm__(1)));
		sub al, 'A'
		cmp al, 'Z'-'A'
		ja .done
		add al, 'a'-'A'
.done:		add al, 'A'
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

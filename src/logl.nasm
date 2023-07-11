;
; written by pts@fazekas.hu at Tue Jul 11 12:27:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o logl.o logl.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_logl
%ifidn __OUTPUT_FORMAT__, bin
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
mini_logl:  ; long double mini_logl(long double x);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fyl2x, so we are good.
		lea eax, [esp+4]
		fldln2
		fld qword [eax]
		fyl2x  ; db 0xd9, 0xf1
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

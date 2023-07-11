;
; written by pts@fazekas.hu at Tue Jul 11 12:17:25 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sqrtl.o sqrtl.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sqrtl
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
mini_sqrtl:  ; long double mini_sqrtl(long double x);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fsqrtl, so we are good.
		fld tword [esp+4]
		fsqrt
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

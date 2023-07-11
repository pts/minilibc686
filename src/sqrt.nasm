;
; written by pts@fazekas.hu at Tue Jul 11 12:17:25 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sqrt.o sqrt.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sqrt
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
mini_sqrt:  ; double mini_sqrt(double x);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fsqrt, so we are good.
		lea eax, [esp+4]
		fld qword [eax]
		fsqrt
		fstp qword [eax]
		fld qword [eax]  ; Round result to double.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

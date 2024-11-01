;
; written by pts@fazekas.hu at Fri Nov  1 04:00:47 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ldexp.o ldexp.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ldexp
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

mini_ldexp:  ; double mini_ldexp(double x, int exp);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fldexp, so we are good.
		lea eax, [esp+4]
		fild dword [eax+8]
		fld qword [eax]
		fscale
		fstp qword [eax]
		fld qword [eax]  ; Round result to double.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

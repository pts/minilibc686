;
; written by pts@fazekas.hu at Fri May 26 21:50:42 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isnan.o isnan.nasm
;
; Code size: 0xf bytes for i386, 0xc bytes for i686.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686  ; fucomip needs >= i686.
%endif

global mini_isnan
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

mini_isnan:  ; int mini_isnan(double x);
		fld qword [esp+0x4]
%ifdef CONFIG_I386
		fucomp st0
		fnstsw ax
		shr eax, 10  ; Move PF to the lowest bit.
		and eax, byte 1
%else
		xor eax, eax
		fucomip st0
		setp al
%endif
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

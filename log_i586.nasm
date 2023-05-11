;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o log_i586.o log_i586.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 586  ; nasm-0.98.39 `cpu 386' incorrectly accepts `fyl2x', GNU `as -march=i386' doesn't.
B.code equ 0

global mini_log
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text

mini_log: ; This needs an >=586 CPU, or a 386+387, or a 486+387. Linux, if the kernel is built with CONFIG_MATH_EMULATION, will emulate a 387.
		fldln2
		fld qword [esp+4]
		fyl2x  ; db 0xd9, 0xf1  ; fyl2x needs an >=586 CPU, or a 386+387, or a 486+387. Linux, if the kernel is built with CONFIG_MATH_EMULATION, will emulate a 387.
		fstp qword [esp+4]
		fld qword [esp+4]
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

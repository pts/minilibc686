;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o log.o log.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_log
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
mini_log:  ; double mini_log(double x);
		; As indicated in README.md, we can assume that an FPU is present. Even a 80387 provides fyl2x, so we are good.
		lea eax, [esp+4]
		fldln2
		fld qword [eax]
		fyl2x  ; db 0xd9, 0xf1
		fstp qword [eax]
		fld qword [eax]
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

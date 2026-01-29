;
; written by pts@fazekas.hu at Thu Oct 24 23:48:55 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o abs.o abs.nasm
;
; Code size: 0xa bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_abs
global mini_labs
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
mini_abs:  ;  int mini_abs(int x);
mini_labs:  ; long mini_labs(long x);
		mov eax, [esp+4]
		cdq
		xor eax, edx
		sub eax, edx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

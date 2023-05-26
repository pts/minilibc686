;
; written by pts@fazekas.hu at Wed May 17 16:31:18 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o m_flushall_dummy.o m_flushall_dummy.nasm
;
; Code size: 1 byte.
;
; This is just a helper function doing nothing. It is usually not even
; linked.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_flushall
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
mini___M_flushall:  ; void mini___M_flushall(void);
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

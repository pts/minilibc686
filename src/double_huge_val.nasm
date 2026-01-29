;
; written by pts@fazekas.hu at Mon Jun  5 21:37:45 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o double_huge_val.o double_huge_val.nasm
;
; Data size: 8 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __double_huge_val
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

section .rodata
; For OpenWatcom.
__double_huge_val:  ; extern double __double_huge_val;
		dd 0, 0x7ff00000

%ifdef CONFIG_PIC
%error Not PIC because of global variables.
times 1/0 nop
%endif

; __END__

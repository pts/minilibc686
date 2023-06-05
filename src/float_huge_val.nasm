;
; written by pts@fazekas.hu at Mon Jun  5 21:37:45 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o huge_val.o huge_val.nasm
;
; Data size: 4 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __float_huge_val
global __float_infinity
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=4
section .data align=1
section .bss align=1
%endif

section .rodata
; For OpenWatcom.
__float_huge_val:  ; extern float __float_huge_val;
__float_infinity:  ; extern float __float_infinity;  /* Same as __float_huge_val, on purpose. */
		dd 0x7f800000

%ifdef CONFIG_PIC
%error Not PIC because of global variables.
times 1/0 nop
%endif

; __END__

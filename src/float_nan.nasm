;
; written by pts@fazekas.hu at Mon Jun  5 21:37:45 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_nan.o float_nan.nasm
;
; Data size: 4 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __float_nan
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
__float_nan:  ; extern float __float_nan;
		dd 0x7fc00000

%ifdef CONFIG_PIC
%error Not PIC because of global variables.
times 1/0 nop
%endif

; __END__

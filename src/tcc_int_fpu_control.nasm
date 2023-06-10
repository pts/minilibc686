;
; written by pts@fazekas.hu at Sat Jun 10 23:50:06 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_int_fpu_control.o tcc_int_fpu_control.nasm
;

bits 32
cpu 386

global __tcc_int_fpu_control
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=2
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .rodata
; FPU control word for round to zero mode for int conversion.
__tcc_int_fpu_control dw 0x137f | 0x0c00

%ifdef CONFIG_PIC
%error Not PIC because of __tcc_int_fpu_control.
times 1/0 nop
%endif

; __END__

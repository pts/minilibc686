;
; written by pts@fazekas.hu at Fri Jun 30 01:26:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ctime_buf.o ctime_buf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_ctime_buf
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

section .bss
mini___M_ctime_buf: resb 26

%ifdef CONFIG_PIC
%error Not PIC because it defines global variable mini___M_ctime_buf.
times 1/0 nop
%endif

; __END__

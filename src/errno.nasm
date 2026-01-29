;
; written by pts@fazekas.hu at Mon May 20 04:42:55 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o errno.o errno.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

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

%ifndef CONFIG_START_STDOUT_ONLY
global mini_errno
mini_errno:	resd 1  ; int mini_errno;
%endif

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable mini_errno.
times 1/0 nop
%endif

; __END__

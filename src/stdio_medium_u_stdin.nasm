;
; written by pts@fazkeas.hu at Sat Jul  5 11:37:40 CEST 2025
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_u_stdin.o stdio_medium_u_stdin.nasm
;
; Uses: %ifdef CONFIG_PIC
;
; This .o file is used only if smart linking is disabled (i.e. smart.nasm is
; not used). smart.nasm inlines this.
;

bits 32
cpu 386

global mini___M_U_stdin
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
mini___M_call_start_isatty_stdin equ +0x12345679
%else
extern mini___M_call_start_isatty_stdin
%endif

section .rodata
mini___M_U_stdin:
; Adding actual relocations to make sure that GNU ld(1) reports the symbols
; below as undefined for sys_*.nasm. They won't be part of the final
; executable program file, because this .o file is not linked in the 2nd
; phase.
dd mini___M_call_start_isatty_stdin

%ifdef CONFIG_PIC
%error Not PIC because it defines and uses global variables.
times 1/0 nop
%endif

; __END__

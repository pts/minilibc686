;
; written by pts@fazekas.hu at Wed Jun  7 13:36:45 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcccstart_.o tcccstart_.nasm
;

bits 32
cpu 386

global cstart_
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
; Needed by the TCC (__TINYC__) compiler 0.9.26 when OpenWatcom (wcc386
; without `-zls') has compiled a C program with the main(...) function. GNU
; ld(1) doesn't complain, because the symbol cstart_ isn't used in any
; relocation.
cstart_:

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

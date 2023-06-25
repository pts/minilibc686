;
; written by pts@fazekas.hu at Sun May 21 19:43:56 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_clear_cache.o tcc_clear_cache.nasm
;

bits 32
cpu 386

global __clear_cache
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
; Needed by the TCC (__TINYC__) compiler 0.9.26 https://github.com/anael-seghezzi/tcc-0.9.26
; GCC 4.1+ doesn't generate the call, and it's empty in libgcc.a.
__clear_cache:
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Wed May 24 23:04:46 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strchr_faster.o strchr_faster.nasm
;
; Code size: 0x42 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%define STRSTR_IS_FASTER
%include "src/strstr.nasm"
%undef  STRSTR_IS_FASTER

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

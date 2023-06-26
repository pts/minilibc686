;
; written by pts@fazekas.hu at Mon Jun 26 01:12:34 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtoull.o strtoull.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%define CONFIG_THIS_STRTOULL
%include "src/strtol.nasm"
%undef  CONFIG_THIS_STRTOULL

%ifdef CONFIG_PIC  ; Already taken care of.
%endif

; __END__

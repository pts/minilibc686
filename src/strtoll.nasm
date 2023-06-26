;
; written by pts@fazekas.hu at Mon Jun 26 01:12:34 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtoll.o strtoll.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%define CONFIG_THIS_STRTOLL
%include "src/strtol.nasm"
%undef  CONFIG_THIS_STRTOLL

%ifdef CONFIG_PIC  ; Already taken care of.
%endif

; __END__

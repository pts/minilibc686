;
; written by pts@fazekas.hu at Mon Jun 26 00:30:33 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtold_inaccurate.o strtold_inaccurate.nasm

; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

%define CONFIG_THIS_STRTOLD_INACCURATE
%include "src/strtod.nasm"
%undef  CONFIG_THIS_STRTOLD_INACCURATE

%ifdef CONFIG_PIC  ; Already taken care of.
%endif

; __END__

;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o lldiv_rp0w.o lldiv_rp0w.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%define RET_STRUCT  ; __WATCOMC__
%define mini_lldiv mini_lldiv_RP0W
%include "src/lldiv.nasm"

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ldiv_rp0w.o ldiv_rp0w.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%define RET_STRUCT  ; __WATCOMC__
%define mini_div mini_div_RP0W
%define mini_ldiv mini_ldiv_RP0W
%include "src/ldiv.nasm"

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

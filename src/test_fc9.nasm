;
; written by pts@fazekas.hu at Wed Jun 28 10:43:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o test_fc9.o test_fc9.nasm
;
; This functions is only useful for testing.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_test_fc9
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
mini___M_test_fc9:  ; c9 mini___M_test_fc9(void);
; typedef struct c9 { char a[9]; } c9;
; c9 mini___M_test_fc9(void) { c9 c; c.a[1] = 11; c.a[8] = 88; return c; }
		mov eax, [esp+4]
		mov byte [eax+1], 11
		mov byte [eax+8], 88
		ret  ; This was correct for pts-tcc before 0.9.26-2. It's also correct for OpenWatcom.
		;ret 4  ; Correct for GCC, PCC and pts-tcc (TinyCC) >=0.9.26-2.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

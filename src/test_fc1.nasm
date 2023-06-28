;
; written by pts@fazekas.hu at Wed Jun 28 10:43:41 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o test_fc1.o test_fc1.nasm
;
; This functions is only useful for testing.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_test_fc1
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
mini___M_test_fc1:  ; c1 mini___M_test_fc1(void);
; typedef struct c1 { char a[1]; } c1;
; c1 mini___M_test_fc1(void) { c1 c; c.a[0] = 42 return c; }
		mov eax, [esp+4]
		mov byte [eax], 42
		;ret  ; This was correct for pts-tcc before 0.9.26-2. It's also correct for OpenWatcom.
		ret 4  ; Correct for GCC, PCC and pts-tcc (TinyCC) >=0.9.26-2.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

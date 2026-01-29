;
; written by pts@fazekas.hu at Sat Oct 26 22:32:49 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o isupper.o isupper.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_isupper
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
mini_isupper:  ; int mini_isupper(int c);
		; No need for `movzx eax, ...', the C standard requires c to be -1..255.
		mov al, [esp+4]
		;mini_isupper_RP3:  ; TODO(pts): Enable this with smart.nasm if both mini_isupper and mini_isupper_RP3.
		sub al, 'A'
		cmp al, 'Z'-'A'+1
		sbb eax, eax
		neg eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

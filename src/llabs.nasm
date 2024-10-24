;
; written by pts@fazekas.hu at Thu Oct 24 23:48:55 CEST 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o llabs.o llabs.nasm
;
; Code size: 0x16 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_llabs
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
mini_llabs:  ; long long mini_llabs(long long x);
		mov edx, [esp+8]
		mov ecx, edx
		sar ecx, 0x1f
		mov eax, [esp+4]
		add eax, ecx
		adc edx, ecx
		xor edx, ecx
		xor eax, ecx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

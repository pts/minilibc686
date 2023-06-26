;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_ffsdi2.o i64_ffsdi2.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __ffsdi2
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
__U8D equ +0x12345678
%else
extern __U8D
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
__ffsdi2:  ; int __ffsdi2(long long i);
; Same code as mini_ffsll.
		bsf eax, [esp+4]  ; Low dword of argument i.
		jz .low_is_0
		inc eax
		ret
.low_is_0:	bsf eax, [esp+8]  ; High dword of argument i.
		jz .zero
		add eax, byte 0x21
		ret
.zero:		xor eax, eax
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

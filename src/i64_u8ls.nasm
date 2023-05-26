;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_u8ls.o i64_u8ls.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __I8LS
global __U8LS
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
; For OpenWatcom.
__I8LS:
__U8LS:
		mov ecx, ebx
		and cl, 0x3f
		test cl, 0x20
		jne .3
		shld edx, eax, cl
		shl eax, cl
		ret
.3:		mov edx, eax
		sub cl, 0x20
		xor eax, eax
		shl edx, cl
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

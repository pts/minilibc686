;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_u8rs.o i64_u8rs.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __U8RS
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
__U8RS:
		mov ecx, ebx
		and cl, 0x3f
		test cl, 0x20
		jne .1
		shrd eax, edx, cl
		shr edx, cl
		ret
.1:		mov eax, edx
		sub ecx, byte 0x20
		xor edx, edx
		shr eax, cl
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

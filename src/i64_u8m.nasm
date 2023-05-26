;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o i64_u8m.o i64_u8m.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __U8M
global __I8M
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
__U8M:
__I8M:
		test edx, edx
		jne .1
		test ecx, ecx
		jne .1
		mul ebx
		ret
.1:		push eax
		push edx
		mul ecx
		mov ecx, eax
		pop eax
		mul ebx
		add ecx, eax
		pop eax
		mul ebx
		add edx, ecx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_bound_alloca.o tcc_bound_alloca.nasm
;

bits 32
cpu 386

global __bound_alloca
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
__bound_new_region equ $+0x12345678
%else
extern __bound_new_region
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

__bound_alloca:
; Needed by the TCC (__TINYC__) compiler 0.9.26 when bounds checking is enabled (`tcc -b').
		pop edx
		pop eax
		mov ecx, eax
		add eax, byte 3
		and eax, byte -4
		jz .1
		sub esp, eax
		mov eax, esp
		push edx
		push eax
		push ecx
		push eax
		call __bound_new_region
		add esp, byte 8
		pop eax
		pop edx
.1:		push edx
		push edx
		ret

%ifdef CONFIG_PIC ; Already position-independent code.
%endif

; __END__

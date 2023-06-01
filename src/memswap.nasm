;
; written by pts@fazekas.hu at Thu Jun  1 04:25:50 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memswap.o memswap.nasm
;
; Code size: 0x1b bytes.
;
; This is the fast implementation (using `repne scasb'), but the slow
; implementation isn't shorter either.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memswap
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
mini_memswap:  ; void mini_memswap(void *a, void *b, size_t size);
		push ebx
		mov ebx, [esp+8]  ; Argument a.
		mov edx, [esp+0xc]  ; Argument b.
		mov ecx, [esp+0x10]  ; Argument size.
		jecxz .done
.again:		mov al, [ebx]
		xchg al, [edx]
		mov [ebx], al
		inc ebx
		inc edx
		loop .again
.done:		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Wed May 24 18:16:17 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memset.o memset.nasm
;
; Code size: 0x1d bytes.
;
; This is the fast implementation (using `repne scasb'), but the slow
; implementation isn't shorter either.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memset
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
mini_memset:  ; void *mini_memset(void *s, int c, size_t n);
		push edi
		mov edi, [esp+8]  ; Argument s.
		mov al, [esp+0xc]  ; Argument c.
		mov ecx, [esp+0x10]  ; Argument n.
		push edi
		jecxz .done
		rep stosb
.done:		pop eax  ; Result is argument s.
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

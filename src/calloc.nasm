;
; written by pts@fazekas.hu at Sun Jun 25 23:29:13 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o calloc.o calloc.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_calloc
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_realloc  equ +0x12345678
%else
extern mini_realloc
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_calloc:  ; void *mini_calloc(size_t nmemb, size_t size);
		mov eax, [esp+4]
		mul dword [esp+8]
		test edx, edx
		jz .size_done
		xor eax, eax  ; TODO(pts): Set errno := ENOMEM.
		ret
.size_done:	push eax  ; Argument size of mini_realloc.
		push byte 0  ; Argument ptr of mini_realloc.
		call mini_realloc
		pop edx  ; Clean up argument ptr of mini_realloc from the stack.
		; memset(result_ptr, '\0', nmemb * size).
		pop ecx  ; Argument size of mini_realloc.
		push edi
		push eax
		xor edi, edi
		xchg edi, eax
		rep stosb
		pop eax
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Sun Jun 25 23:29:13 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o calloc_mmap_linux.o calloc_mmap_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_calloc_mmap
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_malloc_mmap  equ +0x12345678
%else
extern mini_malloc_mmap
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_calloc_mmap:  ; void *mini_calloc_mmap(size_t nmemb, size_t size);
		mov eax, [esp+4]
		mul dword [esp+8]
		test edx, edx
		jz .size_done
		xor eax, eax  ; TODO(pts): Set errno := ENOMEM.
		ret
.size_done:	push eax
		call mini_malloc_mmap
		pop edx  ; Clean up arguments of mini_realloc from the stack.
		; No need to memset(result_ptr, '\0', nmemb * size), mini_malloc_mmap(...) does it.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

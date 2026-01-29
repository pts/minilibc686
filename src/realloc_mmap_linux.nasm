;
; realloc_mmap_linux.nasm: a simple malloc(3) implementation using mmap(2) on Linux i386
; by pts@fazekas.hu at Sat May 20 17:42:38 CEST 2023
;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o realloc_mmap_linux.o realloc_mmap_linux.nasm
;
; See malloc_mmap_linux for more details.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_realloc_mmap
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_malloc_mmap equ +0x12345678
mini_free_mmap equ +0x12345679
%else
extern mini_malloc_mmap
extern mini_free_mmap
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

MREMAP:  ; Symbolic constants.
.MAYMOVE: equ 1

; TODO(pts): Split to separate .o file, to avoid unnecessary linking.
mini_realloc_mmap:  ; void *mini_realloc_mmap(void *ptr, size_t size);
		mov eax, [esp+4]
		test eax, eax
		jnz .existing
		push dword [esp+8]  ; size.
		call mini_malloc_mmap  ; mini_realloc_mmap(NULL, size) is equivalent to It's a no-op to mini_free(NULL).
		pop edx  ; Value doesn't matter.
		ret
.existing:	push ebx
		push esi
		lea ebx, [eax-0x10]  ; old_address argument of mremap(2).
		mov ecx, [ebx]  ; old_size argument of mremap(2).
		mov edx, [esp+8+8]  ; new_size argument of mremap(2).
		test edx, edx
		jz .do_free
		add edx, byte 0x10
		push byte MREMAP.MAYMOVE  ; flags argument of mremap(2).
		pop esi
		xor eax, eax
		mov al, 163  ; __NR_mremap.
		int 0x80  ; Linux i386 syscall.
		cmp eax, -0x100  ; Error? uClibc has -0x1000 here.
		ja .error
		mov [eax], edx  ; Save the new size of the mapping.
		add eax, byte 0x10
.done:		pop esi
		pop ebx
		ret
.do_free:	push eax
		call mini_free_mmap
		pop eax  ; Clean up arguments of mini_free from the stack.
.error:		xor eax, eax  ; EAX := 0 (== NULL, error).
		jmp short .done
		
%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; free_mmap_linux.nasm: a simple malloc(3) implementation using mmap(2) on Linux i386
; by pts@fazekas.hu at Sat May 20 17:42:38 CEST 2023
;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o free_mmap_linux.o free_mmap_linux.nasm
;
; See malloc_mmap_linux for more details.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_free
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text

mini_free:  ; void mini_free(void *ptr);
		mov eax, [esp+4]
		test eax, eax
		jz .done  ; It's a no-op to mini_free(NULL).
		push ebx
		lea ebx, [eax-0x10]  ; addr argument of munmap(2).
		xor eax, eax
		push byte 91  ; __NR_munmap.
		pop eax
		mov ecx, [ebx]  ; length argument of munmap(2).
		int 0x80  ; TODO(pts): abort() on failure.
		pop ebx
.done:		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

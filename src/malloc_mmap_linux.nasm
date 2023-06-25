;
; malloc_mmap_linux.nasm: a simple malloc(3) implementation using mmap(2) on Linux i386
; by pts@fazekas.hu at Sat May 20 17:42:38 CEST 2023
;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o malloc_mmap_linux.o malloc_mmap_linux.nasm
;
; Limitations:
;
; * Each memory allocation has system call overhead and extra overhead
;   because the page table is updated.
; * Each memory allocation uses at last 0x1000 bytes (4 KiB) of memory, all
;   of them are rounded up to the page size.
; * There is 0x10 bytes of overhead per allocation, so if you call
;   mini_malloc_mmap(0x1000), it will use 8 KiB instead of 4 KiB.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_malloc_mmap
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

PROT:  ; Symbolic constants.
.READ: equ 1
.WRITE: equ 2

MAP:  ; Symbolic constants.
.PRIVATE: equ 2
.ANONYMOUS: equ 0x20

; TODO(pts): If just malloc is needed, provide alternative.
mini_malloc_mmap:  ; void *mini_malloc_mmap(size_t size);
		; We return a valid (non-NULL) pointer even if size == 0. uClibc malloc(3) does the same.
		push ebx
		push esi
		push edi
		push ebp
		xor eax, eax
		mov al, 192  ; __NR_mmap2.
		xor ebx, ebx  ; addr argument to mmap2(2).
		mov ecx, [esp+4+0x10]
		add ecx, byte 0x10  ; length argument of mmap2(2). The kernel will round it up to page boundary. We add 0x10 to have room (4 bytes) for the size of the mapping, plus alignment.
		push byte PROT.READ|PROT.WRITE  ; prot argument of mmap2(2).
		pop edx
		push byte MAP.PRIVATE|MAP.ANONYMOUS  ; flags argument of mmap2(2).
		pop esi
		or edi, byte -1  ; fd argument of mmap2(2).
		xor ebp, ebp  ; offset argument of mmap2(2). The file offset is arg << 12, but we don't care, because this is an anonymous mapping.
		int 0x80  ; Linux i386 syscall.
		cmp eax, -0x100  ; Error? uClibc has -0x1000 here.
		ja .error
		mov [eax], ecx  ; Save the size of the mapping.
		add eax, byte 0x10
.done:		pop ebp
		pop edi
		pop esi
		pop ebx
		ret
.error:		xor eax, eax  ; EAX := 0 (== NULL, error).
		jmp short .done

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

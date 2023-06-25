;
; written by pts@fazekas.hu at Tue May 16 18:44:34 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o malloc_simple_unaligned_linux.o malloc_simple_unaligned_linux.nasm
;
; Code size: 0x7c bytes.
;
; Uses: %ifdef CONFIG_PIC
;
; !! TODO(pts): This code is currently untested.
;

bits 32
cpu 386

global mini_malloc_simple_unaligned
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_syscall3_AL equ +0x12345678
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_malloc_simple_unaligned:  ; void *mini_malloc_simple_unaligned(size_t size);
; Implemented using sys_brk(2). Equivalent to the following C code, but was
; size-optimized.
;
; A simplistic allocator which creates a heap of 64 KiB first, and then
; doubles it when necessary. It is implemented using Linux system call
; brk(2), exported by the libc as sys_brk(...). free(...)ing is not
; supported. Returns an unaligned address (which is OK on x86).
;
; void *mini_malloc_simple_unaligned(size_t size) {
;     static char *base, *free, *end;
;     ssize_t new_heap_size;
;     if ((ssize_t)size <= 0) return NULL;  /* Fail if size is too large (or 0). */
;     if (!base) {
;         if (!(base = free = (char*)sys_brk(NULL))) return NULL;  /* Error getting the initial data segment size for the very first time. */
;         new_heap_size = 64 << 10;  /* 64 KiB. */
;         goto grow_heap;  /* TODO(pts): Reset base to NULL if we overflow below. */
;     }
;     while (size > (size_t)(end - free)) {  /* Double the heap size until there is `size' bytes free. */
;         new_heap_size = (end - base) << 1;  /* !! TODO(pts): Don't allocate more than 1 MiB if not needed. */
;       grow_heap:
;         if ((ssize_t)new_heap_size <= 0 || (size_t)base + new_heap_size < (size_t)base) return NULL;  /* Heap would be too large. */
;         if ((char*)sys_brk(base + new_heap_size) != base + new_heap_size) return NULL;  /* Out of memory. */
;         end = base + new_heap_size;
;     }
;     free += size;
;     return free - size;
; }
		push ebx
		mov eax, [esp+8]  ; Argument named size.
		test eax, eax
		jle .18
		mov ebx, eax
		cmp dword [_malloc_simple_base], byte 0
		jne .7
		xor eax, eax
		push eax ; Argument of sys_brk(2).
		mov al, 45  ; __NR_brk.
		; TODO(pts): Add sys_brk symbol with smart linking.
		call mini_syscall3_AL  ; It destroys ECX and EDX.
		pop ecx  ; Clean up argument of sys_brk2(0).
		mov [_malloc_simple_free], eax
		mov [_malloc_simple_base], eax
		test eax, eax
		jz short .18
		mov eax, 0x10000	; 64 KiB minimum allocation.
.9:		add eax, [_malloc_simple_base]
		jc .18
		push eax
		push eax ; Argument of sys_brk(2).
		mov al, 45  ; __NR_brk.
		; TODO(pts): Add sys_brk symbol with smart linking.
		call mini_syscall3_AL	; It destroys ECX and EDX.
		pop ecx  ; Clean up argument of sys_brk(2).
		pop edx			; This (and the next line) could be ECX instead.
		cmp eax, edx
		jne .18
		mov [_malloc_simple_end], eax
.7:		mov edx, [_malloc_simple_end]
		mov eax, [_malloc_simple_free]
		mov ecx, edx
		sub ecx, eax
		cmp ecx, ebx
		jb .21
		add ebx, eax
		mov [_malloc_simple_free], ebx
		jmp short .17
.21:		sub edx, [_malloc_simple_base]
		xchg eax, edx  ; EAX := EDX; EDX := junk.
		add eax, eax
		test eax, eax
		jg .9
.18:		xor eax, eax
.17:		pop ebx
		ret

section .bss
_malloc_simple_base	resd 1  ; char *base;
_malloc_simple_free	resd 1  ; char *free;
_malloc_simple_end	resd 1  ; char *end;

%ifdef CONFIG_PIC
%error Not PIC because of read-write variables.
%endif

; __END__

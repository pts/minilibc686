;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o mremap_linux.o mremap_linux.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_mremap
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini___M_jmp_pop_ebx_syscall_return equ +0x12345678
%else
extern mini___M_jmp_pop_ebx_syscall_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_mremap:  ; void *mini_mremap(void *old_address, size_t old_size, size_t new_size, int flags, ... /* void *new_address */);
		mov ecx, esp
		xor eax, eax
		push ebx
		push esi
		push edi
		mov ebx, [ecx+1*4]  ; Argument old_address.
		mov edx, [ecx+3*4]  ; Argument new_size.
		mov esi, [ecx+4*4]  ; Argument flags.
		mov edi, [ecx+5*4]  ; Argument new_address.
		mov ecx, [ecx+2*4]  ; Argument old_size.
		mov al, 163  ; __NR_mremap.
		int 0x80  ; Linux i386 syscall.
		pop edi
		pop esi
		;pop ebx
		jmp strict near mini___M_jmp_pop_ebx_syscall_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

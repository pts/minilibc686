;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o mmap_linux.o mmap_linux.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_mmap
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_pop_ebx_syscall_return equ +0x12345678
%else
extern mini___M_jmp_pop_ebx_syscall_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_mmap:  ; void *mini_mmap(void *addr, size_t length, int prot, int flags, int fd, off_t offset);
		mov ecx, esp
		xor eax, eax
		push ebx
		push esi
		push edi
		push ebp
		mov ebx, [ecx+1*4]  ; Argument addr.
		mov edx, [ecx+3*4]  ; Argument prot.
		mov esi, [ecx+4*4]  ; Argument flags.
		mov edi, [ecx+5*4]  ; Argument fd.
		mov ebp, [ecx+6*4]  ; Argument offset.
		shr ebp, 12  ; Page size shift for __NR_mmap2.
		mov ecx, [ecx+2*4]  ; Argument length.
		mov al, 192  ; __NR_mmap2.
		int 0x80  ; Linux i386 syscall.
		; TODO(pts): Use mini___M_jmp_pop_ebp_edi_esi_ebx_syscall_return if available.
		pop ebp
		pop edi
		pop esi
		;pop ebx
		jmp strict near mini___M_jmp_pop_ebx_syscall_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

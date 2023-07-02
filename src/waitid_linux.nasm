;
; written by pts@fazekas.hu at Sun Jul  2 16:26:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o waitid_linux.o waitid_linux.nasm
;
; Code size: 0x20 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_waitid
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_pop_ebx_syscall_return equ $+0x12345678
%else
extern mini___M_jmp_pop_ebx_syscall_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_waitid:  ; int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options);
; int waitid(idtype_t idtype, id_t id, siginfo_t *infop, int options) { return sys_waitid(idtype, id, infop, options, NULL); }
		xor eax, eax
		mov al, 284  ; __NR_waitid.
%if 0  ; TODO(pts): Enable this with smart linking if mini_syscall6_EAX is in use (or weak use by many).
		mov ecx, esp
		push dword [ecx+1*4]  ; Argument idtype.
		push dword [ecx+2*4]  ; Argument id.
		push dword [ecx+3*4]  ; Argument infop.
		push dword [ecx+4*4]  ; Argument options.
		push byte 0  ; Argument rusage.
		jmp mini_syscall6_EAX
		add esp, byte 5*4  ; Clean up arguments of mini_syscall6_EAX from the stack.
%else
		push ebx
		push esi
		push edi
		mov esi, esp
		mov ebx, [esi+4*4]  ; Argument idtype.
		mov ecx, [esi+5*4]  ; Argument id.
		mov edx, [esi+6*4]  ; Argument infop.
		mov esi, [esi+7*4]  ; Argument options.
		xor edi, edi  ; Argument rusage.
		int 0x80  ; Linux i386 syscall.
		pop edi
		pop esi
		jmp mini___M_jmp_pop_ebx_syscall_return
%endif		

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

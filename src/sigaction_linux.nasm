;
; written by pts@fazekas.hu at Mon Jul  3 17:02:53 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sigaction_linux.o sigaction_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sigaction
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
mini_sigaction:  ; int mini_sigaction(int signum, const struct sigaction *act, struct sigaction *oldact);
%if 0  ; TODO(pts): Enable this with smart linking if mini_syscall6_AL is in use (or weak use by many).
		mov ecx, esp
		mov al, 174  ; __NR_rt_sigaction.
		push dword [ecx+3*4]  ; Argument oldact.
		push dword [ecx+2*4]  ; Argument act.
		push dword [ecx+1*4]  ; Argument signum.
		push byte 8  ; 8 bytes of sigset_t. Linux fails with EINVAL if 9 is hesed here.
		jmp mini_syscall6_AL
		add esp, byte 4*4  ; Clean up arguments of mini_syscall6_AL from the stack.
%else
		push ebx
		push esi
		mov esi, esp
		mov ebx, [esi+3*4]  ; Argument signum.
		mov ecx, [esi+4*4]  ; Argument act.
		mov edx, [esi+5*4]  ; Argument oldact.
		xor eax, eax
		mov al, 8
		mov esi, eax  ; 8 bytes of sigset_t. Linux fails with EINVAL if 9 is hesed here.
		mov al, 174  ; __NR_rt_sigaction.
		int 0x80  ; Linux i386 syscall.
		pop esi
		jmp mini___M_jmp_pop_ebx_syscall_return
%endif

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

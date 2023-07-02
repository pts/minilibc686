;
; written by pts@fazekas.hu at Sun Jul  2 16:26:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o wait3_linux.o wait3_linux.nasm
;
; Code size: 0x1c bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_wait3
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
mini_wait3:  ; pid_t wait3(int* status, int opts, struct rusage* rusage);
; pid_t wait3(int* status, int opts, struct rusage* rusage) { return wait4(-1, status, opts, rusage); }
%if 0  ; TODO(pts): Enable this with smart linking if mini_syscall6_AL is in use (or weak use by many).
		mov ecx, esp
		mov al, 114  ; __NR_wait4.
		push dword [ecx+3*4]  ; Argument rusage.
		push dword [ecx+2*4]  ; Argument opts.
		push dword [ecx+1*4]  ; Argument status.
		push byte -1
		jmp mini_syscall6_AL
		add esp, byte 4*4  ; Clean up arguments of mini_syscall6_AL from the stack.
%else
		push ebx
		push esi
		xor eax, eax
		mov al, 114  ; __NR_wait4.
		or ebx, byte -1  ; EBX := -1.
		mov esi, esp
		mov ecx, [esi+3*4]  ; Argument status.
		mov edx, [esi+4*4]  ; Argument opts.
		mov esi, [esi+5*4]  ; Argument rusage.
		int 0x80  ; Linux i386 syscall.
		pop esi
		jmp mini___M_jmp_pop_ebx_syscall_return
%endif		

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

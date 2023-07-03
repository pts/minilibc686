;
; written by pts@fazekas.hu at Sun Jul  2 16:26:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o raise_linux.o raise_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_raise
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_jmp_syscall_pop_ebx_return equ $+0x12345678
%else
extern mini___M_jmp_syscall_pop_ebx_return
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_raise:  ; int raise(int sig);
; int raise(int sig) { return kill(getpid(), sig); }
		; TODO(pts): With smart_linking, do a mini_getpid(...) call if mini_getpid is used elsewhere.
		push ebx
		xor eax, eax
		mov al, 20  ; __NR_getpid.
		int 0x80  ; Linux i386 syscall.
		xchg eax, ebx  ; EBX := PID, EAX := junk.
		xor eax, eax
		mov al, 37  ; __NR_kill.
		mov ecx, [esp+2*4]  ; Argument sig.
		jmp strict near mini___M_jmp_syscall_pop_ebx_return

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

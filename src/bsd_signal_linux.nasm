;
; written by pts@fazekas.hu at Mon Jul  3 17:02:53 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o bsd_signal_linux.o bsd_signal_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_bsd_signal
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_syscall3_AL equ $+0x12345678
%else
extern mini_syscall3_AL
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_bsd_signal:  ; sighandler_t bsd_signal(int signum, sighandler_t handler);
		enter 0x20, 0  ; 0x20 == 2 * 0x10: first act at &[ebp-0x20], then oldact at &[ebp-0x10].
		mov eax, [ebp+0xc]
		mov [ebp-0x20+0*4], eax  ; handler.
		mov dword [ebp-0x20+2*4], 0x10000000  ; sa_flags := SA_RESTART.
		xor eax, eax
		mov [ebp-0x20+1*4], eax  ; act.sa_mask.sig[0] := 0. sizeof(sa_mask) is always 4 for Linux i386 SYS_sigaction.
		lea eax, [ebp-0x10]  ; Argument oldact of SYS_sigaction.
		push eax
		lea eax, [ebp-0x20]
		push eax  ; Argument act of sys_sigaction(2).
		push dword [ebp+0x8]  ; Argument sig of SYS_sigaction.
		mov al, 67  ; SYS_sigaction for sigaction(2). Shorter code (because fewer arguments) than SYS_rt_sigaction. It also uses a different struct sigaction (both size and layout).
		call mini_syscall3_AL
		test eax, eax
		jnz .done  ; EAX == SIG_ERR == -1.
		mov eax, [ebp-0x10]  ; Old handler.
.done:		leave
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

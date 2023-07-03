;
; written by pts@fazekas.hu at Thu Jun 22 11:20:33 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o abort_linux.o abort_linux.nasm
;
; Code size: 0x24 bytes.
;
; Limitation: the signal hadler for SIGABRT won't be called.
;
; It doesn't flush stdio streams, that's OK. glibc >=2.27 also does that.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_abort
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_abort:  ; void mini_abort(void) __attribute__((__noreturn__));
		xor eax, eax
		mov al, 48  ; __NR_signal
		xor ebx, ebx
		mov bl, 6  ; SIGABRT.
		xor ecx, ecx  ; SIG_DFL.
		int 0x80  ; Linux i386 syscall.
		; TODO(pts): With smart_linking, do a mini_getpid(...) call if mini_getpid is used elsewhere.
		xor eax, eax
		mov al, 20  ; __NR_getpid.
		int 0x80  ; Linux i386 syscall.
		xchg eax, ebx  ; EBX := PID, EAX := junk.
		xor eax, eax
		mov al, 37  ; __NR_kill.
		; xor ecx, ecx  ; Not needed, above we've already set the high 24 bits of ECX to 0.
		mov cl, 6  ; SIGABRT.
		int 0x80  ; Linux i386 syscall. Usually this doesn't return, the process is killed.
		xor eax, eax
		inc eax  ; EAX := __NR_exit.
		xor ebx, ebx
		mov bl, 127  ; _exit(127) as a fallback if kill(2) above did return.
		int 0x80  ; Linux i386 syscall. It never returns for __NR_exit.
		; Not reached.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

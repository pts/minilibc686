;
; written by pts@fazekas.hu at Mon Jun  5 23:50:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o syscall3_linux.o syscall3_linux.nasm
;
; With smart linking, the code in src/smart.nasm is used instead of this
; file.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_syscall3_AL
global mini_syscall3_RP1
global mini___M_jmp_syscall_pop_ebx_return
global mini___M_jmp_pop_ebx_syscall_return
global mini___M_jmp_syscall_return
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_syscall3_AL:  ; Useful from assembly language.
; Calls syscall(number, arg1, arg2, arg3).
;
; It takes the syscall number from AL (8 bits only!), arg1 (optional) from
; [esp+4], arg2 (optional) from [esp+8], arg3 (optional) from [esp+0xc]. It
; keeps these args on the stack.
;
; It can EAX, EDX and ECX as scratch.
;
; It returns result (or -1 as error) in EAX.
		movzx eax, al  ; number.
mini_syscall3_RP1:  ; long mini_syscall3_RP1(long nr, long arg1, long arg2, long arg3) __attribute__((__regparm__(1)));
		push ebx  ; Save it, it's not a scratch register.
		mov ebx, [esp+8]  ; arg1.
		mov ecx, [esp+0xc]  ; arg2.
		mov edx, [esp+0x10]  ; arg3.
mini___M_jmp_syscall_pop_ebx_return:
		int 0x80  ; Linux i386 syscall.
mini___M_jmp_pop_ebx_syscall_return:
		pop ebx
mini___M_jmp_syscall_return:
		; test eax, eax
		; jns .final_result
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .final_result
		or eax, byte -1  ; EAX := -1 (error).
.final_result:	ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

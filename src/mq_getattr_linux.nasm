;
; written by pts@fazekas.hu at Tue Jun 13 15:34:24 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o sys_mq_getattr_linux.o sys_mq_getattr_linux.nasm

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sys_mq_getattr
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_syscall3_RP1 equ +0x12345678
%else
extern mini_syscall3_RP1
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_sys_mq_getattr:  ; int mini_mq_getattr(mqd_t mqdes, struct mq_attr *mqstat);
		mov eax, 282  ; __NR_mq_getsetattr, for mini_syscall3_RP1.
		push dword [esp+3*4]  ; Argument mqstat.
		push byte 0  ; NULL.
		push dword [esp+3*4]  ; Argument mqdes.
		call mini_syscall3_RP1
		add esp, byte 3*4  ; Clean up arguments of mini_syscall3_RP1 from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

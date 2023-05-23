;
; written by pts@fazkeas.hu at Tue May 23 01:22:33 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_init_isatty.o stdio_medium_init_isatty.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_init_isatty
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_isatty equ +0x12345678
mini___M_stdin_for_init_isatty equ  +0x1234567a
mini___M_stdout_for_flushall equ +0x12345679
%else
common mini___M_stdout_for_flushall 4:4
common mini___M_stdin_for_init_isatty 4:4
extern mini_isatty
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini___M_init_isatty:
		push byte -1  ; Terminator.
		push dword [mini___M_stdin_for_init_isatty]
		push dword [mini___M_stdout_for_flushall]
.next_filep:	pop edx  ; EDX := next_filep.
		cmp edx, byte -1
		je .done
		test edx, edx
		jz .after_bufset
		push edx
		push dword [edx+0x10]  ; fd argument of mini_isatty.
		call mini_isatty
		pop edx  ; Clean up the arguments of mini_isatty from the stack.
		pop edx  ; Restore EDX := filep.
		test eax, eax
		jz .after_bufset
		add byte [edx+0x14], 2  ; filep->dire = FD_WRITE_LINEBUF, changed from FD_WRITE. 
.after_bufset:	jmp near .next_filep
.done:		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__

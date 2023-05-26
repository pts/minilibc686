;
; written by pts@fazkeas.hu at Tue May 23 13:37:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o vprintf_callvf.o vprintf_callvf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_vprintf
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_vfprintf equ $+0x12345678
mini_stdout equ $+0x12345600
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
extern mini_stdout
extern mini_vfprintf
%endif

section .text
mini_vprintf:  ; int mini_vprintf(const char *fmt, va_arg ap) { return mini_vfprintf(mini_stdout, fmt, ap); }
		push dword [esp+8]  ; Argument ap of mini_vfprintf.
		push dword [esp+8]  ; Argument fmt of mini_vfprintf.
		push dword [mini_stdout]  ; Argument filep of mini_vfprintf.
		call mini_vfprintf
		add esp, byte 3*4  ; Clean up arguments of mini_vfprintf from the stack.
		ret

%ifdef CONFIG_PIC
%error Not PIC because of mini_stdout.
times 1/0 nop
%endif
		
; __END__

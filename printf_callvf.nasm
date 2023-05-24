;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386
B.code equ 0

global mini_printf
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_vfprintf equ $+0x12345678
mini_stdout equ $+0x12345600
%else
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
extern mini_stdout
extern mini_vfprintf
%endif

section .text
mini_printf:
; int mini_printf(const char *fmt, ...) { return mini_vfprintf(mini_stdout, fmt, ap); }
;esp:retaddr fmt val
		push esp  ; 1 byte.
;esp:&retaddr retaddr fmt val
		add dword [esp], strict byte 2*4  ; 4 bytes.
;esp:ap=&val retaddr fmt val
		push dword [esp+2*4]  ; 4 bytes.
;esp:fmt ap=&val retaddr fmt val
%ifdef CONFIG_PIC
%error Not PIC because of mini_stdout.
times 1/0 nop
%endif
		push dword [mini_stdout]  ; 6 bytes.
;esp:filep fmt ap=&val retaddr fmt val
		call B.code+mini_vfprintf  ; 5 bytes.
;esp:filep fmt ap=&val retaddr fmt val
		add esp, strict byte 3*4  ; 3 bytes, same as `times 3 pop edx'.
;esp:retaddr fmt val
		ret  ; 1 byte.

		
; __END__

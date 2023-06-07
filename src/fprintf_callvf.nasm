;
; written by pts@fazekas.hu in 2023-05
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o printf_callvf.o printf_callvf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_fprintf
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_vfprintf equ $+0x12345678
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
extern mini_vfprintf
%endif

section .text
mini_fprintf:
; int mini_fprintf(FILE *filep, const char *fmt, ...) { return mini_vfprintf(filep, fmt, ap); }
;esp:retaddr filep fmt val
		push esp  ; 1 byte.
;esp:&retaddr retaddr filep fmt val
		add dword [esp], strict byte 3*4  ; 4 bytes.
;esp:ap=&val retaddr filep fmt val
		push dword [esp+3*4]  ; 4 bytes.
;esp:fmt ap=&val retaddr filep fmt val
		push dword [esp+3*4]  ; 4 bytes.
;esp:filep fmt ap=&val retaddr filep fmt val
		call mini_vfprintf  ; 5 bytes.
;esp:filep fmt ap=&val retaddr filep fmt val
		add esp, strict byte 3*4  ; 3 bytes, same as `times 3 pop edx'.
;esp:retaddr filep fmt val
		ret  ; 1 byte.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

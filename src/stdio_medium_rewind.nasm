;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_rewind.o c_stdio_medium_rewind.nasm
;

bits 32
cpu 386

global mini_rewind
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fseek equ +0x12345678
%else
extern mini_fseek
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

mini_rewind:  ; void mini_rewind(FILE *filep);
		push byte 0  ; SEEK_SET.
		push byte 0  ; Desired offset is start of file.
		push dword [esp+3*4]  ; filep.
		call mini_fseek
		add esp, byte 3*4  ; Clean up arguments of mini_fseek.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

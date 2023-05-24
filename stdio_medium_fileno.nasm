;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_fileno.o c_stdio_medium_fileno.nasm
;

bits 32
cpu 386

global mini_fileno
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

mini_fileno:
		mov eax, [esp+4]
		mov eax, [eax+0x10]
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

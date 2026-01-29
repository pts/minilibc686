;
; based on https://github.com/open-watcom/open-watcom-v2/blob/6366191465a4414a2633e982607e776a1950eab2/bld/mathlib/a/fchop87.asm#L57-L75
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __CHP
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
; For OpenWatcom.
__CHP:		push    0x00000c3f    ; allocate space and store new control word
		fnstcw  word [esp+2]  ; save current control word
		fldcw   word [esp]    ; set control word to truncate
		frndint               ; truncate top of stack
		fldcw   word [esp+2]  ; restore old control word
		add esp, byte 4       ; adjust stack pointer
		ret
        
%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

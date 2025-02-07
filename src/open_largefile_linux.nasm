;
; written by pts@fazekas.hu at Fri Feb  7 20:00:36 CET 2025
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o open_largefile_linux.o open_largefile_linux.nasm
;
; Code size: 0x19 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_open_largefile
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_open equ +0x12345678
%else
extern mini_open
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_open_largefile:  ; char *mini_open_largefile(const char *pathname, int flags, mode_t mode);  /* Argument mode is optional. */
		push dword [esp+3*4]  ; Argument mode.
		mov eax, [esp+3*4]  ; Argument flags.
		or ah, 0x80  ; Add O_LARGEFILE (Linux i386).
		push eax
		push dword [esp+3*4]  ; Argument pathname.
		call mini_open
		add esp, byte 3*4  ; Clean up arguments of open above.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

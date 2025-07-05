;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdout.o stdio_medium_stdout.nasm
;
; Uses: %ifdef CONFIG_PIC
;
; This .o file is used only if smart linking is disabled (i.e. smart.nasm is
; not used). smart.nasm inlines this.
;

bits 32
cpu 386

global mini_stdout
global mini___M_start_isatty_stdout
global mini___M_start_flush_stdout
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
mini_isatty equ +0x12345678
mini___M_U_stdout equ +0x12345679
mini_fflush_RP3 equ +0x1234567a
%else
extern mini_isatty
extern mini_fflush_RP3
; This is a difference between GNU ld(1), the TinyCC ELF linker in miniutcc
; and OpenWatcom v2 wlink(1): If there is an `extern
; mini___M_U_stdout' declaration, but the symbol is not used
; in the program anywhere, GNU ld(1) ignores undefined symbol, but the
; TinyCC ELF linker and wlink(1) fail with:
;
;   tcc: error: undefined symbol 'mini___M_U_stdout'
;   Error! E2028: mini___M_U_stdout is an undefined reference
;
; This difference doesn't affect us in practice, because all start source
; files (smart.nasm, sys_*.nasm and start_*.nasm) define this symbol, so
; it never remains undefined.
;
; We work this around (in a way that is compatible with --tccld and the
; default GNU ld(1)) for libca.386.a by adding stdio_medium_u_stdout.o after
; (not to) libca.386.a, which will actually depend on
; mini___M_start_isatty_stdout and mini___M_call_start_flush_stdout, and
; these will be provided by sys_*.nasm.
extern mini___M_U_stdout  ; This will trigger stdio_medium_u_stdout.o to be linked for libca.386.a.
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
%endif
%define CONFIG_SECTIONS_DEFINED

section .text
mini___M_start_isatty_stdout:
		push byte 1  ; STDOUT_FILENO.
		call mini_isatty
		pop edx  ; Clean up the argument of mini_isatty from the stack.
		add eax, eax
		add [mini_stdout_struct.dire], al  ; filep->dire = FD_WRITE_LINEBUF, changed from FD_WRITE.
		ret

mini___M_start_flush_stdout:
		mov eax, [mini_stdout]
		jmp mini_fflush_RP3

%include "src/stdio_medium_stdout_in_data.nasm"

%ifdef CONFIG_PIC
%error Not PIC because it defines and uses global variables.
times 1/0 nop
%endif

; __END__

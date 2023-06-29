;
; written by pts@fazekas.hu at Fri Jun 23 10:31:44 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o gmtime.o gmtime.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_gmtime
global mini_localtime
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
mini_gmtime_r equ +0x12345678
%else
extern mini_gmtime_r
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
%endif

section .text
mini_gmtime:  ; struct tm *mini_gmtime(const time_t *timep);
mini_localtime:  ; struct tm *mini_localtime(const time_t *timep);  /* No concept of time zones, everything is GMT. */
		; TODO(pts): With smart linking, do a fall through to mini_gmtime_r.
		push dword global_struct_tm
		push dword [esp+2*4]  ; Argument timep.
		call mini_gmtime_r
		times 2 pop edx  ; Clean up arguments of mini_gmtime from the stack.
		ret

%ifdef CONFIG_PIC
%error Not PIC because it uses global variable global_struct_pm.
times 1/0 nop
%endif

section .bss
global_struct_tm: resd 9  ; sizeof(struct tm) == 4 * 9.

; __END__

;
; written by pts@fazekas.hu at Fri Jun 30 02:44:33 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ctime.o ctime.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ctime
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_asctime equ +0x12345678
mini_localtime equ +0x12345679
%else
extern mini_asctime
extern mini_localtime
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_ctime:  ; char *mini_ctime(const time_t *timep);
; char *mini_ctime(const time_t *timep) {
;   return mini_asctime(localtime(timep));
; }
		push dword [esp+4]  ; Argument timep.
		call mini_localtime
		pop edx  ; Clean up argument timep from the stack.
		push eax
		call mini_asctime  ; TODO(pts): With smart linking, inline this call as a call to mini_asctime_r, but only if mini_asctime is not used.
		pop edx  ; Clean up argument of mini_asctime from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

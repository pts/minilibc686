;
; written by pts@fazekas.hu at Fri Jun 30 02:44:33 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o ctime_r.o ctime_r.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_ctime_r
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_asctime_r equ +0x12345678
mini_localtime equ +0x12345679
%else
extern mini_asctime_r
extern mini_localtime
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_ctime_r:  ; char *mini_ctime_r(const time_t *timep, char *buf);
; char *mini_ctime_r(const time_t *timep, char *buf) {
;   return mini_asctime_r(mini_localtime(timep) ,buf);
; }
		push dword [esp+8]  ; Argument buf.
		push dword [esp+8]  ; Argument timep.
		call mini_localtime
		pop edx  ; Clean up argument timep from the stack.
		push eax
		call mini_asctime_r
		times 2 pop edx  ; Clean up arguments of mini_asctime_r from the stack.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

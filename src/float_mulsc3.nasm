;
; written by pts@fazekas.hu at Thu Jun 29 14:12:53 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; The following libgcc.a versions were tried, and the shortest code was
; selected: 4.4, 4.6, 4.8, 7.5.0, 8, 9, 10, 11. C source cxmuldiv.c in
; pcc-libs-1.1.0.tgz was also tried with soptcc.pl.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __mulsc3
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
__mulxc3_sub equ +0x12345678
%else
extern __mulxc3_sub
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
; For PCC and GCC >= 4.3.
__mulsc3:  ; float _Complex __muldc3(float a, float b, float c, float d);
; Returns: the product of a + ib and c + id.
		enter 0x3c, 0
		fld dword [ebp+8]  ; Argument a.
		fld dword [ebp+0x10]  ; Argument c. (Order swapped with b!)
		fld dword [ebp+0xc]  ; Argument b.
		fld dword [ebp+0x14]  ; Argument d.
		call __mulxc3_sub
		fstp dword [esp]
		pop eax ; Copy __real__ res to its final return location (EAX), clean up variable TMP at ESP.
		fstp dword [esp]
		pop edx  ; Copy __imag__ res to its final return location (EDX), clean up variable TMP at ESP.
		leave
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

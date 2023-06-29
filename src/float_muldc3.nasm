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

global __muldc3
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
__muldc3:  ; double _Complex __muldc3(double a, double b, double c, double d);
; Returns: the product of a + ib and c + id.
		enter 0x3c, 0
		fld qword [ebp+0xc]  ; Argument a.
		fld qword [ebp+0x1c]  ; Argument c. (Order swapped with b!)
		fld qword [ebp+0x14]  ; Argument b.
		fld qword [ebp+0x24]  ; Argument d.
		call __mulxc3_sub
		mov eax, [ebp+8]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp qword [eax]
		fstp qword [eax+8]
		leave
		ret 4

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

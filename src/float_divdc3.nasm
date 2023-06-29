;
; written by pts@fazekas.hu at Thu Jun 29 12:31:45 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; The following libgcc.a versions were tried, and the shortest code was
; selected: 4.4, 4.6, 4.8, 7.5.0, 8, 9, 10, 11. C source cxmuldiv.c in
; pcc-libs-1.1.0.tgz was also tried with soptcc.pl.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global __divdc3
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
__divxc3_sub equ +0x12345678
%else
extern __divxc3_sub
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

%ifdef CONFIG_I386  ; Emulate the missing i686 instructions using i386 instructions.
  %macro _fucomip 2
    fucomp %1, %2
    fnstsw ax
    sahf
  %endmacro
  %macro _fucomi 2
    fucom %1, %2
    fnstsw ax
    sahf
  %endmacro
%else
  %define _fucomip fucomip
  %define _fucomi fucomi
%endif  ; CONFIG_I386

section .text
; For PCC and GCC >= 4.3.
__divdc3:  ; double _Complex __divdc3(double a, double b, double c, double d);
; Returns: the quotient of (a + ib) / (c + id).
		mov edx, esp
		fld qword [esp+8]  ; Argument a.
		fld qword [esp+0x10]  ; Argument b.
		fld qword [esp+0x18]  ; Argument c.
		fld qword [esp+0x20]  ; Argument d.
		call __divxc3_sub  ; Keeps EDX intact.
		mov eax, [edx+4]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp qword [eax]
		fstp qword [eax+8]
		ret 4

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

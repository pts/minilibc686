;
; based on disassemby from libgcc.a of GCC 7.5.0
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_chp.o float_chp.nasm
;
; The following libgcc.a versions were tried, and the shortest code was
; selected: 4.4, 4.6, 4.8, 7.5.0, 8, 9, 10, 11. C source cxmuldiv.c in
; pcc-libs-1.1.0.tgz was also tried with soptcc.pl.
;
; TODO(pts): Implement all 3 sizes in terms of `long double'. Just adapt the stack.
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

global __mulxc3
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
__mulxc3:  ; long double _Complex __muldc3(long double a, long double b, long double c, long double d);
; Returns: the product of a + ib and c + id.
		push esi
		push ebx
		sub esp, byte 0x24
		fld tword [esp+0x34]
		fld tword [esp+0x4c]
		fld st1
		fmul st0, st1
		fld tword [esp+0x40]
		fld tword [esp+0x58]
		fmul st1, st0
		fxch st1
		fld st0
		fstp tword [esp]
		fxch st1
		fmul st0, st4
		fld tword [esp+0x40]
		fmul st0, st4
		fld st0
		fstp tword [esp+0xc]
		fld st3
		fsubrp st3, st0
		fld st1
		faddp st1, st0
		_fucomi st0, st0
		fxch st2
		setp dl
		_fucomi st0, st0
		setp al
		and dl, al
		jne .4
		fstp st4
		fstp st0
		fstp st3
		fstp st0
		jmp short .3
.1:		fstp st0
.2:		fstp st2
		fstp st0
		fxch st1
.3:		mov eax, [esp+0x30]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp tword [eax]
		fstp tword [eax+0xc]
		add esp, byte 0x24
		pop ebx
		pop esi
		ret 4
.4:		fld st5
		fsub st0, st6
		fstp tword [esp+0x18]
		fld tword [esp+0x40]
		_fucomi st0, st0
		fsub st0, st0
		setpo al
		mov esi, eax
		_fucomip st0, st0
		fxch st5
		setp al
		and esi, eax
		_fucomi st0, st0
		jp .5
		fld tword [esp+0x18]
		_fucomip st0, st0
		jp near .46
.5:		mov eax, esi
		test al, al
		jne near .24
.6:		fld st4
		fsub st0, st5
		fstp tword [esp+0x18]
		fld tword [esp+0x58]
		_fucomi st0, st0
		fld st0
		setpo dl
		fsubrp st1, st0
		_fucomip st0, st0
		fxch st4
		setp al
		and edx, eax
		_fucomi st0, st0
		jp .7
		fld tword [esp+0x18]
		_fucomip st0, st0
		jp near .48
.7:		test dl, dl
		jne near .29
		mov eax, esi
		test al, al
		jne near .21
		fld st3
		fsub st0, st4
		fxch st4
		_fucomip st0, st0
		jp .8
		fxch st3
		_fucomip st0, st0
		jp .14
		jmp short .9
.8:		fstp st3
.9:		fld tword [esp]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .10
		_fucomip st0, st0
		jp .14
		jmp short .11
.10:		fstp st0
.11:		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .12
		_fucomip st0, st0
		jp .15
		jmp short .13
.12:		fstp st0
.13:		fld tword [esp+0xc]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .1
		_fucomip st0, st0
		jpo .2
		jmp short .15
.14:		fstp st0
.15:		fstp st0
		fstp st2
.17:		_fucomi st0, st0
		jp near .45
.18:		fld tword [esp+0x40]
		_fucomi st0, st0
		jp near .43
		fstp st0
		fxch st1
.19:		_fucomi st0, st0
		jp near .41
.20:		fld tword [esp+0x58]
		_fucomi st0, st0
		jp near .39
		fstp st0
		jmp short .23
.21:		fstp st5
		fstp st0
		fstp st0
.22:		fstp st0
		fxch st1
.23:		fld st1
		fmul st0, st1
		fld tword [esp+0x40]
		fld tword [esp+0x58]
		fmul st1, st0
		fxch st2
		fsubrp st1, st0
		push dword 0x7f800000
		fld dword [esp]
		pop ebx  ; TODO(pts): Can we use another register so that we don't have to save ebx?
		fmul st1, st0
		fxch st2
		fmulp st4, st0
		fld tword [esp+0x40]
		fmulp st3, st0
		fxch st3
		faddp st2, st0
		fmulp st1, st0
		fxch st1
		jmp near .3
.24:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .25
		fstp st0
		fldz
		fchs
.25:		fld1
.26:		fld tword [esp+0x40]
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .27
		fchs
.27:		fstp tword [esp+0x40]
		fxch st4
		_fucomi st0, st0
		jp near .38
.28:		fld tword [esp+0x58]
		_fucomip st0, st0
		jp near .36
		fxch st4
		mov esi, edx
		jmp near .6
.29:		fstp st5
		fstp st0
		fstp st0
		fstp st0
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .30
		fstp st0
		fldz
		fchs
.30:		fld1
.31:		fld tword [esp+0x58]
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .32
		fchs
.32:		fstp tword [esp+0x58]
		fxch st1
		_fucomi st0, st0
		jp .35
.33:		fld tword [esp+0x40]
		_fucomi st0, st0
		jpo .22
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .34
		fstp st0
		fldz
		fchs
.34:		fstp tword [esp+0x40]
		fxch st1
		jmp near .23
.35:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .33
		fstp st0
		fldz
		fchs
		jmp short .33
.36:		fld tword [esp+0x58]
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .37
		fstp st0
		fldz
		fchs
.37:		fstp tword [esp+0x58]
		fxch st4
		mov esi, edx
		jmp near .6
.38:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .28
		fstp st0
		fldz
		fchs
		jmp near .28
.39:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .40
		fstp st0
		fldz
		fchs
.40:		fstp tword [esp+0x58]
		jmp near .23
.41:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .42
		fstp st0
		fldz
		fchs
.42:		jmp near .20
.43:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .44
		fstp st0
		fldz
		fchs
.44:		fstp tword [esp+0x40]
		fxch st1
		jmp near .19
.45:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .18
		fstp st0
		fldz
		fchs
		jmp near .18
.46:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .47
		fstp st0
		fld1
		fchs
.47:		mov eax, esi
		test al, al
		jne .25
		fldz
		jmp near .26
.48:		fstp st5
		fstp st0
		fstp st0
		fstp st0
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .49
		fstp st0
		fld1
		fchs
.49:		test dl, dl
		jne .30
		fldz
		jmp near .31

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
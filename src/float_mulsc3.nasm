;
; based on disassemby from libgcc.a of GCC 7.5.0
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

global __mulsc3
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
__mulsc3:  ; float _Complex __muldc3(float a, float b, float c, float d);
; Returns: the product of a + ib and c + id.
		push ebx
		sub esp, byte 0x20
		fld dword [esp+0x28]
		fld dword [esp+0x2c]
		fld dword [esp+0x30]
		fld dword [esp+0x34]
		fld st3
		fmul st0, st2
		fstp dword [esp+0x10]
		fld st2
		fmul st0, st1
		fstp dword [esp+0x14]
		fld st3
		fmul st0, st1
		fstp dword [esp+0x18]
		fld st1
		fmul st0, st3
		fstp dword [esp+0x1c]
		fld dword [esp+0x10]
		fld dword [esp+0x14]
		fst dword [esp]
		fld st1
		fsubrp st1, st0
		fld dword [esp+0x18]
		fst dword [esp+4]
		fld dword [esp+0x1c]
		fst dword [esp+8]
		faddp st1, st0
		_fucomi st0, st0
		fxch st1
		setp dl
		_fucomi st0, st0
		setp al
		and dl, al
		jne .4
		fstp st5
		fstp st5
		fstp st0
		fstp st0
		fstp st0
		jmp short .3
.1:		fstp st0
		fstp st5
		fstp st0
		fstp st0
		fstp st0
		jmp short .3
		nop
		lea esi, [esi]
.2:		fstp st5
		fstp st0
		fstp st0
		fstp st0
.3:		fstp dword [esp]
		mov eax, [esp]
		fstp dword [esp]
		mov edx, [esp]
		add esp, byte 0x20
		pop ebx
		ret
.4:		fld st6
		fsub st0, st7
		fstp dword [esp+0xc]
		fxch st5
		_fucomi st0, st0
		fld st0
		setpo bl
		fsub st0, st1
		_fucomip st0, st0
		fxch st6
		setp al
		and ebx, eax
		_fucomi st0, st0
		jp .5
		fld dword [esp+0xc]
		_fucomip st0, st0
		jp near .51
.5:		test bl, bl
		jne near .29
.6:		fld st4
		fsub st0, st5
		fstp dword [esp+0xc]
		fxch st3
		_fucomi st0, st0
		fld st0
		setpo dl
		fsub st0, st1
		_fucomip st0, st0
		fxch st4
		setp al
		and edx, eax
		_fucomi st0, st0
		jp .7
		fld dword [esp+0xc]
		_fucomip st0, st0
		jp near .53
.7:		test dl, dl
		jne near .37
		test bl, bl
		jne near .24
		fld st2
		fsub st0, st3
		fxch st3
		_fucomip st0, st0
		jp .8
		fxch st2
		_fucomip st0, st0
		jp .14
		jmp short .9
.8:		fstp st2
.9:		fld dword [esp]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .10
		_fucomip st0, st0
		jp .15
		jmp short .11
.10:		fstp st0
.11:		fld dword [esp+4]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .12
		_fucomip st0, st0
		jp .16
		jmp short .13
.12:		fstp st0
.13:		fld dword [esp+8]
		fld st0
		fsub st0, st1
		fxch st1
		_fucomip st0, st0
		jp .1
		_fucomip st0, st0
		jpo .2
		fstp st0
		fstp st3
		fxch st1
		fxch st2
		fxch st1
		jmp short .17
.14:		fstp st0
		fstp st3
		fxch st1
		fxch st2
		fxch st1
		jmp short .17
.15:		fstp st0
		fstp st3
		fxch st1
		fxch st2
		fxch st1
		jmp short .17
.16:		fstp st0
		fstp st3
		fxch st1
		fxch st2
		fxch st1
.17:		_fucomi st0, st0
		jp near .48
		fxch st3
		jmp short .19
.18:		fxch st3
.19:		_fucomi st0, st0
		jp near .47
		fxch st1
		jmp short .21
.20:		fxch st1
.21:		_fucomi st0, st0
		jp near .46
		fxch st2
		jmp short .23
.22:		fxch st2
.23:		_fucomi st0, st0
		jp near .45
		fxch st2
		fxch st1
		fxch st3
		fxch st1
		jmp short .28
.24:		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		jmp short .28
.25:		fxch st3
		fxch st1
		fxch st2
		jmp short .28
.26:		fxch st3
		fxch st1
		fxch st2
		jmp short .28
.27:		fxch st2
		fxch st1
		fxch st3
		fxch st1
.28:		fld st1
		fmul st0, st1
		fld st4
		fmul st0, st4
		fsubp st1, st0
		push dword 0x7f800000
		fld dword [esp]
		pop ecx
		fmul st1, st0
		fxch st3
		fmulp st4, st0
		fxch st1
		fmulp st4, st0
		fxch st2
		faddp st3, st0
		fmulp st2, st0
		jmp near .3
.29:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .30
		fstp st0
		fldz
		fchs
.30:		fld1
		fxch st7
.31:		fxam
		fnstsw ax
		fstp st0
		fxch st6
		test ah, 2
		fabs
		je .32
		fchs
		fxch st4
		jmp short .33
.32:		fxch st4
.33:		_fucomi st0, st0
		jp near .49
		fxch st3
		jmp short .35
.34:		fxch st3
.35:		_fucomi st0, st0
%ifdef CONFIG_I386
		jp near .44
%else
		jp .44
%endif
.36:		fxch st3
		fxch st4
		fxch st6
		mov ebx, edx
		jmp near .6
.37:		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .38
		fstp st0
		fldz
		fchs
.38:		fld1
		fxch st3
.39:		fxam
		fnstsw ax
		fstp st0
		fxch st2
		test ah, 2
		fabs
		je .40
		fchs
		fxch st1
		jmp short .41
.40:		fxch st1
.41:		_fucomi st0, st0
		jp near .50
		fxch st3
		jmp short .43
.42:		fxch st3
.43:		_fucomi st0, st0
		jpo .25
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .26
		fstp st0
		fldz
		fchs
		fxch st3
		fxch st1
		fxch st2
		jmp near .28
.44:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .36
		fstp st0
		fldz
		mov ebx, edx
		fchs
		fxch st3
		fxch st4
		fxch st6
		jmp near .6
.45:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .27
		fstp st0
		fldz
		fchs
		fxch st2
		fxch st1
		fxch st3
		fxch st1
		jmp near .28
.46:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .22
		fstp st0
		fldz
		fchs
		fxch st2
		jmp near .23
.47:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .20
		fstp st0
		fldz
		fchs
		fxch st1
		jmp near .21
.48:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .18
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .19
.49:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .34
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .35
.50:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fldz
		je .42
		fstp st0
		fldz
		fchs
		fxch st3
		jmp near .43
.51:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .52
		fstp st0
		fld1
		fchs
.52:		test bl, bl
		jne .30
		fldz
		fxch st7
		jmp near .31
.53:		fstp st5
		fstp st0
		fstp st0
		fxch st1
		fxch st2
		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fld1
		je .54
		fstp st0
		fld1
		fchs
.54:		test dl, dl
		jne .38
		fldz
		fxch st3
		jmp near .39

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

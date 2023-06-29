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

global __divsc3
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
__divsc3:  ; double _Complex __divsc3(double a, double b, double c, double d);
; Returns: the quotient of (a + ib) / (c + id).
		push ecx  ; Create variable tmp at ESP. Shorter than `sub esp, byte 4'.
		fld dword [esp+8]  ; !! Use EBP everywhere, it's shorter.
		fld dword [esp+0xc]
		fld dword [esp+0x10]
		fld dword [esp+0x14]
		fld st1
		fabs
		fld st1
		fabs
		_fucomip st0, st1
		fstp st0
		jbe .8
		fld st1
		fdiv st0, st1
		fld st2
		fmul st0, st1
		fadd st0, st2
		fld st5
		fmul st0, st2
		fadd st0, st5
		fdiv st0, st1
		fstp dword [esp]  ; Save __real__ res to tmp.
		fxch st1
		fmul st0, st4
		fsub st0, st5
		fdivrp st1, st0
.1:		_fucomi st0, st0  ; isnan(x)?
		jp .9
		fstp st3
		fstp st0
		fstp st0
		fstp st1
		jmp short .7
.3:		fstp st0
.4:		fstp st0
.5:		fstp st0
		fstp st0
		fstp st0
		fstp st0
.7:		pop eax  ; Copy __real__ res to its final return location (EAX), clean up variable TMP at ESP.
		push edx  ; Create variable tmp at ESP. Shorter than `sub esp, byte 4'.
		fstp dword [esp]  ; Save __imag__ res to tmp.
		pop edx  ; Copy __imag__ res to its final return location (EDX), clean up variable TMP at ESP.
		ret
.8:		fld st0
		fdiv st0, st2
		fld st1
		fmul st0, st1
		fadd st0, st3
		fld st1
		fmul st0, st5
		fadd st0, st6
		fdiv st0, st1
		fstp dword [esp]  ; Save __real__ res to tmp.
		fxch st1
		fmul st0, st5
		fsubr st0, st4
		fdivrp st1, st0
		jmp short .1
.9:		fld dword [esp]  ; Push tmp containing __real__ res (to st0). TODO(pts): Don't truncate.
		_fucomip st0, st0  ; isnan(y)?
		jpo .1  ; if (!(isnan(x) && isnan(y))) goto .1;
		fxch st4
		_fucomi st0, st0
		fldz
		setpo cl
		_fucomi st0, st3
		jp .12
		jne .12
		_fucomip st0, st2
		jp .13
		jne .13
		fxch st3
		_fucomi st0, st0
		jnp .10  ; if (!isnan(b)) goto .10;  Jump on PF=1, indicating unordered==nan (C2=1).
		test cl, cl
		jnz .10  ; if (!isnan(a)) goto .10;
		fld st3
		xor eax, eax
		fsub st0, st4
		fxch st1
		fxch st4
		fxch st1
		jmp short .14
.10:
; x = COPYSIGN(INFINITY, c) * a; y = COPYSIGN(INFINITY, c) * b;
		fstp st4
		fstp st0
		fxch st1
		fxch st2
		fxch st1
		fxam
		fnstsw ax
		fstp st0
		shr eax, 9
		shl eax, 31  ; EAX := (st0 was negative when fxam was called) ? 0x80000000 : 0.
		or eax, 0x7f800000  ; EAX := (st0 was negative when fxam was called) ? (f32)-inf : (f32)inf.
		push eax ; inf or -inf.
		fld dword [esp]  ; inf or -inf.
		pop eax
		fmul st2, st0
		fxch st2
		fstp dword [esp]  ; Save __real__ res to tmp.
		fmulp st1, st0
		jmp near .7
.12:		fstp st0
.13:		fld st0
		fsub st0, st1
		_fucomi st0, st0
		setp al
		and al, cl
		jne near .29
.14:		fld st4
		fsub st0, st5
		fxch st5
		_fucomi st0, st0
		jp .15
		fxch st5
		_fucomip st0, st0
		jp near .29
		jmp short .16
.15:		fstp st5
.16:		fld st3
		fsub st0, st4
		fxch st4
		jmp short .18
.17:		fxch st4
.18:		_fucomi st0, st0
		fxch st4
		setpo al
		_fucomip st0, st0
		setp cl
		and al, cl
		jnz .21
		fld st2
		fsub st0, st3
		fxch st3
		jmp short .20
.19:		fxch st3
.20:		_fucomi st0, st0
		jp .3
		fxch st3
		_fucomip st0, st0
		jpo .4
		xor eax, eax
.21:		_fucomip st0, st0
		jp .5
		fld st3
		fsub st0, st4
		_fucomip st0, st0
		jp .5
		fstp st4
		fxch st1
		fxch st2
		fxch st3
		test al, al
		fldz
		jnz near .36
		fxch st3
.22:		fxam
		fnstsw ax
		fstp st0
		fxch st2
		test ah, 2
		fabs
		je .23
		fchs
.23:		fld st1
		fsub st0, st2
		fxch st2
		_fucomi st0, st0
		jp .24
		fxch st2
		_fucomip st0, st0
		jp near .38
		jmp short .25
.24:		fstp st2
.25:		fldz
		fxch st2
.26:		fxam
		fnstsw ax
		fstp st0
		fxch st1
		test ah, 2
		fabs
		je .27
		fchs
.27:		fld st2
		fmul st0, st2
		fld st4
		fmul st0, st2
		faddp st1, st0
		fldz
		fmul st1, st0
		fxch st1
		fstp dword [esp]  ; Save __real__ res to tmp.
		fxch st4
		fmulp st2, st0
		fmulp st2, st0
		fsubrp st1, st0
		fmulp st1, st0
		jmp near .7
.29:		fld st3
		fsub st0, st4
		_fucomi st0, st0
		jp .17
		fstp st0
		fld st2
		fsub st0, st3
		_fucomi st0, st0
		jp .19
		fstp st0
		fstp st0
		fstp st4
		fxch st1
		fxch st2
		fxch st3
		test al, al
		fldz
		jnz .37
		fxch st1
.30:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .31
		fchs
.31:		fld st3
		fsub st0, st4
		fxch st4
		_fucomi st0, st0
		jp .32
		fxch st4
		_fucomip st0, st0
		jp .39
		jmp short .33
.32:		fstp st4
.33:		fldz
		fxch st4
.34:		fxam
		fnstsw ax
		fstp st0
		fxch st3
		test ah, 2
		fabs
		je .35
		fchs
.35:		fld st2
		fmul st0, st4
		fld st2
		fmul st0, st2
		faddp st1, st0
		push dword 0x7f800000  ; inf.
		fld dword [esp]  ; inf.
		pop edx
		fmul st1, st0
		fxch st1
		fstp dword [esp]  ; Save __real__ res to tmp.
		fxch st3
		fmulp st1, st0
		fxch st3
		fmulp st1, st0
		fsubp st2, st0
		fmulp st1, st0
		jmp near .7
.36:		fstp st0
		fld1
		fxch st3
		jmp near .22
.37:		fstp st0
		fld1
		fxch st1
		jmp short .30
.38:		fld1
		fxch st2
		jmp near .26
.39:		fld1
		fxch st4
		jmp short .34

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

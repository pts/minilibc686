;
; a bit manually optimized disassembly from libgcc.a of GCC 7.5.0
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

global __divxc3
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
__divxc3:  ; long double _Complex __divxc3(long double a, long double b, long double c, long double d);
; Returns: the quotient of (a + ib) / (c + id).
		mov edx, esp
		fld tword [edx+8]  ; Argument a.
		fld tword [edx+0x14]  ; Argument b.
		fld tword [edx+0x20]  ; Argument c.
		fld tword [edx+0x2c]  ; Argument d.
		call __divxc3_sub  ; Keeps EDX intact.
		mov eax, [edx+4]  ; Struct return pointer. We return it in EAX according to the ABI.
		fstp tword [eax]
		fstp tword [eax+0xc]
		ret 4

; Input: a in ST3, b in ST2, c in ST1, d in ST0, all pushed to the FPU stack.
; Output: x in ST1, y in ST0, both pushed to the FPU stack.
; Side effect: Ruins AX, CL and EFLAGS, keeps other registers (other parts of EAX, EBX, other parts of ECX, EDX, ESI, EDI, EBP, ESP) intact.
__divxc3_sub:	fld st1
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
		fxch st2
		fmul st0, st5
		fsub st0, st6
		fdivrp st1, st0
.1:		_fucomi st0, st0
		jp .9
		fstp st5
		fstp st3
		jmp short .2b
.2:		fstp st4
		fstp st4
.2b:		fstp st0
		fstp st0
		ret
.3:		fstp st0
.4:		fstp st0
.5:		fstp st0
		fstp st3
		fstp st0
		fstp st0
		fxch st1
.8:		fld st0
		fdiv st0, st2
		fld st1
		fmul st0, st1
		fadd st0, st3
		fld st1
		fmul st0, st5
		fadd st0, st6
		fdiv st0, st1
		fxch st2
		fmul st0, st6
		fsubr st0, st5
		fdivrp st1, st0
		jmp short .1
.9:		fxch st1
		_fucomi st0, st0
		jpo .2
		fxch st5
		_fucomi st0, st0
		fldz
		setpo cl
		_fucomi st0, st4
		jp .13
		jne .13
		_fucomip st0, st3
		jp .14
		jne .14
		fxch st4
		_fucomi st0, st0
		jnp .10  ; if (!isnan(b)) goto .10;  Jump on PF=1, indicating unordered==nan (C2=1).
		test cl, cl
		jnz .10  ; if (!isnan(a)) goto .10;
		fld st4
		fsub st0, st5
		fxch st1
		fxch st5
		fxch st1
		jmp short .15
.10:
; x = COPYSIGN(INFINITY, c) * a; y = COPYSIGN(INFINITY, c) * b;
		fstp st5
		fstp st0
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
		fmulp st1, st0
		fxch st1
		ret
.13:		fstp st0
.14:		fld st0
		fsub st0, st1
		_fucomi st0, st0
		setp al
		and cl, al
		jnz near .30
.15:		fld st5
		fsub st0, st6
		fxch st6
		_fucomi st0, st0
		jp .16
		fxch st6
		_fucomip st0, st0
		jp near .30
		jmp short .17
.16:		fstp st6
.17:		fld st4
		fsub st0, st5
		fxch st5
		jmp short .19
.18:		fxch st5
.19:		_fucomi st0, st0
		fxch st5
		setpo al
		_fucomip st0, st0
		setp cl
		and al, cl
		jne .22
		fld st3
		fsub st0, st4
		fxch st4
		jmp short .21
.20:		fxch st4
.21:		_fucomi st0, st0
		jp .3
		fxch st4
		_fucomip st0, st0
		jpo .4
		xor eax, eax
.22:		_fucomip st0, st0
		jp .5
		fld st4
		fsub st0, st5
		_fucomip st0, st0
		jp .5
		fstp st5
		fstp st0
		fxch st1
		fxch st2
		fxch st3
		test al, al
		jne near .37
		fldz
		fxch st3
.23:		fxam
		fnstsw ax
		fstp st0
		fxch st2
		test ah, 2
		fabs
		je .24
		fchs
.24:		fld st1
		fsub st0, st2
		fxch st2
		_fucomi st0, st0
		jp .25
		fxch st2
		_fucomip st0, st0
		jp near .39
		jmp short .26
.25:		fstp st2
.26:		fldz
		fxch st2
.27:		fxam
		fnstsw ax
		fstp st0
		fxch st1
		test ah, 2
		fabs
		je .28
		fchs
.28:		fld st2
		fmul st0, st2
		fld st4
		fmul st0, st2
		faddp st1, st0
		fldz
		fmul st1, st0
		fxch st5
		fmulp st3, st0
		fxch st1
		fmulp st3, st0
		fxch st2
		fsubp st1, st0
		fmulp st2, st0
		ret
.30:		fld st4
		fsub st0, st5
		_fucomi st0, st0
		jp .18
		fstp st0
		fld st3
		fsub st0, st4
		_fucomi st0, st0
		jp .20
		fstp st0
		fstp st0
		fstp st5
		fstp st0
		fxch st1
		fxch st2
		fxch st3
		test cl, cl
		jnz .38
		fldz
		fxch st1
.31:		fxam
		fnstsw ax
		fstp st0
		test ah, 2
		fabs
		je .32
		fchs
.32:		fld st3
		fsub st0, st4
		fxch st4
		_fucomi st0, st0
		jp .33
		fxch st4
		_fucomip st0, st0
		jp .40
		jmp short .34
.33:		fstp st4
.34:		fldz
		fxch st4
.35:		fxam
		fnstsw ax
		fstp st0
		fxch st3
		test ah, 2
		fabs
		je .36
		fchs
.36:		fld st2
		fmul st0, st4
		fld st2
		fmul st0, st2
		faddp st1, st0
		push dword 0x7f800000  ; inf.
		fld dword [esp]
		pop eax
		fmul st1, st0
		fxch st4
		fmulp st2, st0
		fxch st4
		fmulp st2, st0
		fsubrp st1, st0
		fmulp st1, st0
		fxch st1
		ret
.37:		fld1
		fxch st3
		jmp near .23
.38:		fld1
		fxch st1
		jmp short .31
.39:		fld1
		fxch st2
		jmp near .27
.40:		fld1
		fxch st4
		jmp short .35

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

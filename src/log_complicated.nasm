;
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o log_complicated.o log_complicated.nasm
;
; This implementation is not needed, because log.nasm also works wherever
; this one works (i.e. on an i686 or on an i386 + an FPU). So this
; implementation is only for educational purposes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_log_complicated
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=8
section .data align=1
section .bss align=1
%endif

section .text
mini_log_complicated:  ; double mini_log_complicated(double x);
		; This implementation is based on c_log.c, with just format conversions, no manual optimizations.
		push ebp
		mov ebp, esp
		push edi
		push esi
		and esp, byte -0x8
		sub esp, byte 0x28
		fld qword [ebp+0x8]
		fst qword [esp+0x18]
		mov ecx, [esp+0x18]
		mov eax, [esp+0x1c]
		test eax, eax
		js .5
		cmp eax, 0xfffff
		jbe .5
		cmp eax, 0x7fefffff
		ja near .13
		fstp st0
		xor edx, edx
		test ecx, ecx
		mov edi, -0x3ff
		fldz
		jne .10
		cmp eax, 0x3ff00000
		je near .13
		jmp short .12
.5:		mov edx, eax
		and edx, 0x7fffffff
		or ecx, edx
		je .8
		test eax, eax
		js .9
		fmul dword [fpconst.0]
		fstp qword [esp+0x10]
		mov ecx, [esp+0x10]
		mov eax, [esp+0x14]
		xor edx, edx
		mov edi, -0x435
		jmp short .11
.8:		fmul st0  ; Bad: fmul st0, st0
		fld1
		fchs
		fdivrp st1  ; Bad: fdivp st1
		jmp .13
.9:		fsub st0  ; Bad: fsubr st0, st0
		fldz
		fdivp st1, st0  ; Bad: fdivrp st1
		jmp .13
.10:		fstp st0
.11:		fldz
.12:		fstp st0
		add eax, 0x95f62
		mov esi, eax
		shr esi, 0x14
		add esi, edi
		and eax, 0xfffff
		add eax, 0x3fe6a09e
		or eax, edx
		mov [esp+0x8], ecx
		mov [esp+0xc], eax
		fld1
		fchs
		fadd qword [esp+0x8]
		fld st0
		fmul dword [fpconst.1]
		fmul st1
		fld st1
		fadd dword [fpconst.2]
		fdivr st2
		fld st0
		fmul st1
		fld st0
		fmul st1
		fld st0
		fmul qword [fpconst.3]
		fadd qword [fpconst.4]
		fmul st1
		fadd qword [fpconst.5]
		fmul st1
		fld st1
		fmul qword [fpconst.6]
		fadd qword [fpconst.7]
		fmul st2
		fadd qword [fpconst.8]
		fmulp st2
		fxch st1
		fadd qword [fpconst.9]
		fmulp st2
		faddp st1
		mov [esp+0x4], esi
		fild dword [esp+0x4]
		fxch st1
		fadd st3
		fmulp st2
		fld st0
		fmul qword [fpconst.10]
		faddp st2
		fxch st1
		fsubrp st2  ; Bad: fsubp st2
		fxch st1
		faddp st2
		fmul qword [fpconst.11]
		faddp st1
		fstp qword [esp+0x20]
		fld qword [esp+0x20]
.13:		lea esp, [ebp-0x8]
		pop esi
		pop edi
		pop ebp
		ret

section .rodata
fpconst:
		align 8, db 0  ; Not strictly necessary, but it's faster to align the f64 constants to a multiple of 8.
.3:		dd 0xd078c69f, 0x3fc39a09
.4:		dd 0x1d8e78af, 0x3fcc71c5
.5:		dd 0x9997fa04, 0x3fd99999
.6:		dd 0xdf3e5244, 0x3fc2f112
.7:		dd 0x96cb03de, 0x3fc74664
.8:		dd 0x94229359, 0x3fd24924
.9:		dd 0x55555593, 0x3fe55555
.10:		dd 0x35793c76, 0x3dea39ef
.11:		dd 0xfee00000, 0x3fe62e42
.0:		dd 0x5a800000
.1:		dd 0x3f000000
.2:		dd 0x40000000

%ifdef CONFIG_PIC
%error Not PIC because of read-only fp constants.
times 1/0 nop
%endif

; __END__

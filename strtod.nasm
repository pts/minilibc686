;
; Manually optimized for size based on the output of soptcc.pl for c_strtod.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtod_f64.o strtod_f64.nasm
;
; Code+data size: 0x17c bytes; 0x17e bytes with CONFIG_PIC. CONFIG_I386 (independently) adds 3 bytes.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;
; It doesn't set errno, see -D_STDTOD_ERRNO c_strtod.c for that.
;
; The results are still accurate, test_strtod_f64.sh passes.
;
; 80387 FPU timings: https://www2.math.uni-wuppertal.de/~fpf/Uebungen/GdR-SS02/opcode_f.html
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global mini_strtod
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

global mini_strtod

section .text
mini_strtod:  ; double mini_strtod(const char *str, char **endptr)
%define VAR_TMP_DIGIT 0  ; 4 bytes.
%define VAR_F32_10 4  ; 4 bytes f32.
%define VARS_SIZE 8
; esp+9 is pushed EBP.
; esp+0xc is pushed EDI.
; esp+0x10 is pushed ESI.
; esp+0x14 is pushed EBX.
; esp+0x18 is the return address.
%define ARG_STR 0x1c  ; 4 bytes char*.
%define ARG_ENDPTR 0x20  ; 4 bytes char**.
;
F32_10 equ 0x41200000  ; (f32)10.0.
DECIMAL_DIG equ 21
MAX_ALLOWED_EXP equ 4973
%define NAN_INF_STR_DB db 5, 'nan', 0, 10, 'infinity', 0, 5, 'inf', 0, 0
		push ebx
		push esi
		push edi
		push ebp
		push dword F32_10
		push ebp  ; Just a shorter `sub esp, byte 4'.
		mov ebx, [esp+ARG_STR]
.1:		mov al, [ebx]
		cmp al, ' '
		je .2
		mov ah, al
		sub ah, 9  ; "\t".
		cmp ah, 4  ; ord("\r")-ord("\t").
		ja .3
.2:		inc ebx
		jmp .1
.3:		xor ebp, ebp
		cmp al, '-'
		je .4
		cmp al, '+'
		je .5
		jmp short .6
.4:		inc ebp  ; ++pos;
.5:		inc ebx
.6:		or eax, byte -1  ; num_digits = -1;
		xor edi, edi
		xor esi, esi
		fldz  ; number = 0;  `number' will be kept in ST0 for most of this function.
		xor edx, edx  ; Clear high 24 bits, for the `mov [esp+VAR_TMP_DIGIT], edx' below.
.loop7:		mov dl, [ebx]
		sub dl, '0'
		cmp dl, 9
		ja .after_loop7
		test eax, eax
		jge .8
		inc eax
.8:		test eax, eax
		jnz .9
		test dl, dl
		jz .10
.9:		inc eax
		cmp eax, byte DECIMAL_DIG
		jg .10
		mov [esp+VAR_TMP_DIGIT], edx
		fmul dword [esp+VAR_F32_10]
		fiadd dword [esp+VAR_TMP_DIGIT]
.10:		inc ebx
		jmp .loop7
.after_loop7:	cmp dl, '.'-'0'
		jne .done_loop7
		test esi, esi
		jne .done_loop7
		inc ebx
		mov esi, ebx  ; pos0 = pos;
		jmp .loop7
.done_loop7:	test eax, eax
		jge .18
		test esi, esi
		jne .17
		; Now we use ESI for something else (i), with initial value already 0.
		xor ecx, ecx  ; Keep high 24 bits 0, for ch and ecx below.
		mov [esp+VAR_TMP_DIGIT], esi  ; 0.
%ifdef CONFIG_PIC
		call .after_nan_inf_str
.nan_inf_str:	NAN_INF_STR_DB
		db 0  ; Overhead to produce valid disassembly.
.after_nan_inf_str:
		pop esi  ; ESI := .nan_inf_str.
%else
		mov esi, nan_inf_str
%endif
.loop13:	mov edx, ebx
		mov eax, esi
		lea eax, [esi+1]  ; Same size as `mov' + `inc'.
.14:		mov cl, [edx]
		or cl, 0x20
		cmp cl, [eax]
		jne .16
		inc edx
		inc eax
		cmp [eax], ch  ; Same as: cmp byte [eax], 0
		jne .14
		fstp st0  ; Pop `number' (originally in ST0) from the stack.
		fild dword [esp+VAR_TMP_DIGIT]
		fldz
		fdivp st1, st0
		test ebp, ebp
		je .15
		fchs  ; number = -number.
.15:		mov cl, [esi]
		add ebx, ecx
		dec ebx
		dec ebx
		jmp short .store_done
.16:		mov cl, [esi]
		add esi, ecx
		inc byte [esp+VAR_TMP_DIGIT]  ; Set it to anything positive.
		cmp cl, ch
		jne .loop13
.17:		mov ebx, [esp+ARG_STR]  ; pos = str;
		jmp short .store_done
.18:		cmp eax, byte DECIMAL_DIG
		jle .19
		sub eax, byte DECIMAL_DIG
		add edi, eax
.19:		test esi, esi
		je .20
		mov eax, esi
		sub eax, ebx
		add edi, eax
.20:		test ebp, ebp  ; if (negative);
		je .21
		fchs  ; number = -number;
.21:		mov al, [ebx]
		or al, 0x20
		cmp al, 'e'
		jne .29
		mov [esp+VAR_TMP_DIGIT], ebx  ; pos1 = pos;  ! Maybe push ebx/pop ebx? Only if we don't use other variables in the meantime.
		xor esi, esi
		inc esi  ; negative = 1;
		inc ebx  ; Skip past the 'e'.
		mov al, [ebx]
		cmp al, '-'
		je .22
		cmp al, '+'
		je .23
		jmp short .24
; We put this to the middle so that we don't need `jmp near'.
.store_done:	; VAR_NUMBER is already populated.
		mov eax, [esp+ARG_ENDPTR]  ; Argument endptr.
		test eax, eax
		je .36
		mov [eax], ebx
.36:		fstp qword [esp]
		fld qword [esp]  ; By doing this fstp+fld combo, we round the result to f64.
		times 2 pop ebp  ; Just `add esp, byte VARS_SIZE'.
		pop ebp
		pop edi
		pop esi
		pop ebx
		ret
.22:		neg esi  ; negative = -1;
.23:		inc ebx
.24:		mov ebp, ebx
		xor eax, eax
		xor edx, edx  ; Clear high 24 bits, for the `add eax, edx' below.
.loop25:	mov dl, [ebx]
		sub dl, '0'
		cmp dl, 9
		ja .27
		cmp eax, MAX_ALLOWED_EXP  ; if (exponent_temp < MAX_ALLOWED_EXP);
		jge .26
		imul eax, byte 10
		add eax, edx
.26:		inc ebx
		jmp .loop25
.27:		cmp ebx, ebp
		jne .28
		mov ebx, [esp+VAR_TMP_DIGIT]  ; pos = pos1;
.28:		imul eax, esi
		add edi, eax
.29:		fldz
%ifdef CONFIG_I386
		fucomp st1  ; if (number == 0.);  True for +0.0 and -0.0.
		fnstsw ax
		sahf
%else  ; Needs i686 (P6).
		fucomip st1  ; if (number == 0.);  True for +0.0 and -0.0.
%endif  ; CONFIG_I386.
		je .store_done  ; if (number == 0.) goto DONE;
		mov eax, edi
		test eax, eax
		jz .store_done
		jge .skip_neg
		neg eax  ; Exponent_temp = -exponent_temp;
.skip_neg:	fld dword [esp+VAR_F32_10]  ; p_base = 10.0, but with higher (f80) precision.
.loop31:	; Now: ST0 is p_base, ST1 is number.
		test al, 1
		jz .34
		test edi, edi
		jge .32
		fdiv st1, st0  ; number /= p_base;
		jmp short .34
.32:		fmul st1, st0  ; number *= p_base;
.34:		fmul st0, st0  ; p_base *= p_base;
		shr eax, 1
		jnz .loop31
		; Now: ST0 is p_base, ST1 is number.
		fstp st0  ; Pop p_base. `number' remains on the stack.
		jmp short .store_done

%ifndef CONFIG_PIC
section .rodata
nan_inf_str:	NAN_INF_STR_DB
%endif

; __END__

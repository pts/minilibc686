;
; based on https://github.com/open-watcom/open-watcom-v2/blob/dd492927af350c50d063b6fa7cd24529c80d0624/bld/clib/cgsupp/a/7fu8386.asm#L48
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_fsu87.o float_fsu87.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
global __FSU87
__FSU87:  ; Convert float in EAX to uint64_t in EDX:EAX.
; For OpenWatcom.
	sub esp, byte 0xc
	mov [esp], eax
	fld dword [esp]
	jmp short convert

global __FDU87
__FDU87:  ; Convert double in EDX:EAX to uint64_t in EDX:EAX.
; For OpenWatcom.
	sub esp, byte 0xc
	mov [esp], eax
	mov [esp+4], edx
	fld qword [esp]
	; Fall through.

convert:
	push ecx
	fstp tword [esp+4]  ; get number out in memory
	mov ax, [esp+0xc]  ; pick up sign/exponent
	and ax, 0x7fff  ; isolate exponent
	sub ax, 16383  ; remove bias
	jl .ret_zero  ; if less than .5, return zero
	cmp ax, strict word 64  ; are we too big?
	jae .ret_inf  ; if so, return infinity
	mov cl, 63  ; calculate shift count
	sub cl, al  ; ...
	mov eax, [esp+4]  ; pick up mantissa
	mov edx, [esp+8]  ; ...
	je .negate  ; skip out if no shifting
.2:	shr edx, 1  ; shift down one bit
	rcr eax, 1  ; ...
	dec cl  ; are we done?
	jne .2  ; do it again if not
.negate:
	test byte [esp+13], 0x80  ; is number negative?
	jns .done  ; if not, we're done
	neg edx  ; negate number
	neg eax  ; ...
	sbb edx, byte 0  ; ...
.done:	pop ecx  ; ...
	add esp, byte 0xc
	ret  ; ...
.ret_zero:
	xor edx, edx
	xor eax, eax
	jmp .done

.ret_inf:
	or edx, byte -1
	mov eax, edx
	jmp short .done

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

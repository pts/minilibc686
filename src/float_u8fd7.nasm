;
; based on https://github.com/open-watcom/open-watcom-v2/blob/dd492927af350c50d063b6fa7cd24529c80d0624/bld/clib/cgsupp/a/7u8f386.asm#L64
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_u8fd7.o float_u8fd7.nasm
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
global __U8FD7
__U8FD7:  ; Convert uint64_t in EDX:EAX to double in EAX.
; For OpenWatcom.
	push edx  ; save unsigned int64 (hi)
	push eax  ; save unsigned int64 (lo)
	fild qword [esp]  ; load as int64
	test byte [esp+7], 0x80  ; most significant bit set?
	jns .3  ; no, jump
	push dword 0x5f800000  ; (float)(ULONGLONG_MAX +1) (only exponent set)
	fadd dword [esp]   ; correct int64 to unsigned int64 as
	; as float (because expression is exact
	; in powers of 2, so save 4 bytes)
	pop eax
.3:	fstp qword [esp]  ; save double and pop coproc stack
	pop eax  ; return double (lo)
	pop edx  ; return double (hi)
	ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

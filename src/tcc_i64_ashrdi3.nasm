;
; written by pts@fazekas.hu at Mon May 29 12:52:30 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o tcc_i64_ashrdi3.o tcc_i64_ashrdi3.nasm
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I64_SHIFT_CALL
;

bits 32
cpu 386

global ___ashrdi3
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%ifdef CONFIG_I64_SHIFT_CALL
__I8RS equ +0x12345678
%endif
%else
%ifdef CONFIG_I64_SHIFT_CALL
extern __I8RS
%endif
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif


section .text
__ashrdi3:  ; long long __ashrdi3(long long a, int b) { return a >> b; }
; For TinyCC 0.9.26.
%ifdef CONFIG_I64_SHIFT_CALL  ; TODO(pts): Enable this with smart linking.
		push ebx
		mov eax, [esp+8]  ; Low dword of argument a.
		mov edx, [esp+0xc]  ; High dword of argument a.
		mov ebx, [esp+0x10]  ; Argument b: shift amount.
		call __I8RS
		pop ebx
%else
		push esi
		mov cl, [esp+0x10]  ; Argument b: shift amount.
		mov eax, [esp+0x8]  ; Low dword of argument a.
		mov esi, [esp+0xc]  ; High dword of argument a.
		mov edx, esi
		sar edx, cl
		shrd dword eax, esi, cl
		test cl, 0x20
		jz .done
		sar esi, 0x1f
		mov eax, edx
		mov edx, esi
.done:		pop esi
%endif
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

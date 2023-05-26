;
; written by pts@fazekas.hu at Fri May 26 00:50:07 CEST 2023
; inspired by https://github.com/nidud/asmc/blob/master/source/libc/string/memmove.asm
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o memmove.o memmove.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_memmove
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
mini_memmove:  ; void *mini_memmove(void *dest, const void *src, size_t n);
		push edi
		push esi
		mov eax, [esp+0xc]  ; Argument dest. It will remain in EAX until return.
		mov esi, [esp+0x10]  ; Argument src.
		mov ecx, [esp+0x14]  ; Argument n.
		cmp eax, esi
		mov edi, eax
		jnc .reverse
		rep movsb
		jmp short .return2
.reverse:	add esi, ecx
		add edi, ecx
		dec esi
		dec edi
		std
		rep movsb
		cld
.return2:	pop esi
		pop edi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

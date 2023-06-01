;
; written by pts@fazekas.hu at pts@fazekas.hu at Thu Jun  1 02:48:00 CEST 2023
; nased on .nasm source file generated by soptcc.pl from fyi/qsort.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o qsort.o qsort.nasm
;
; Code size: 0x7c bytes. TODO(pts): Whay did the C compiler generate 0x83 bytes?
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_qsort
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

mini_qsort:  ; void mini_qsort(void *base, size_t n, size_t size, int (*cmp)(const void*, const void*));
; The code for i386 has been generated by the C compiler, see C source in
; fyi/qsort.c. Then a few small optimizations were done.
		push ebx
		push esi
		push edi
		enter 0x8, 0x0
		mov edi, [ebp+0x1c]
		mov eax, [ebp+0x18]
		cmp eax, byte 0x1
		jbe .7
		mov ebx, [ebp+0x14]
		add ebx, edi
		imul eax, edi
		mov edx, [ebp+0x14]
		add edx, eax
		mov [ebp-0x8], edx
.1:		cmp ebx, [ebp-0x8]
		je .7
		lea eax, [ebx+edi]
		mov [ebp-0x4], eax
		mov eax, ebx
		sub eax, edi
		push eax
		push ebx
		call [ebp+0x20]  ; cmp.
		pop edx
		pop edx  ; EDX := junk. Clean up the arguments of cmp from the stack.
		test eax, eax
		jge .6
		mov esi, ebx
.2:		sub ebx, edi
		cmp ebx, [ebp+0x14]
		je .3
		mov eax, ebx
		sub eax, edi
		push eax
		push esi
		call [ebp+0x20]  ; cmp.
		pop edx
		pop edx  ; EDX := junk. Clean up the arguments of cmp from the stack.
		test eax, eax
		jl .2
.3:		cmp esi, [ebp-0x4]
		je .6
		mov eax, esi
		mov cl, [esi]
.4:		cmp eax, ebx
		je .5
		mov edx, eax
		sub edx, edi
		mov ch, [edx]
		mov [eax], ch
		mov eax, edx
		jmp short .4
.5:		mov [ebx], cl
		inc esi
		inc ebx
		jmp short .3
.6:		mov ebx, [ebp-0x4]
		jmp short .1
.7:		leave
		pop edi
		pop esi
		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__
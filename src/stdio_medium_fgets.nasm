;
; based on .nasm source file generated by soptcc.pl from c_stdio_medium_fgets.c
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_stdio_medium_fgets.o c_stdio_medium_fgets.nasm
;
; Code size: 0x64 bytes.
;

bits 32
cpu 386

global mini_fgets
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fread equ +0x12345678
%else
extern mini_fread
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

mini_fgets:  ; char *mini_fgets(char *s, int size, FILE *filep);
		push ebx
		push esi
		enter 4, 0
		mov ebx, [ebp+0x18]
		cmp dword [ebp+0x14], byte 0
		jg short .1
		xor eax, eax
		jmp short .done
.1:		xor esi, esi
.2:		lea eax, [esi+0x1]
		cmp eax, [ebp+0x14]
		jge short .5
		mov eax, [ebx+0x8]
		cmp eax, [ebx+0xc]
		je short .3
		inc eax
		mov [ebx+0x8], eax
		mov al, [eax-1]
		mov [ebp-0x4], al
.4:		mov edx, esi
		inc esi
		add edx, [ebp+0x10]
		mov al, [ebp-0x4]
		mov [edx], al
		cmp al, 10  ; '\n'
		jne short .2
.5:		mov eax, [ebp+0x10]
		mov byte [esi+eax], 0x0
		jmp short .done
.3:		push ebx
		push byte 1
		push byte 1
		lea eax, [ebp-0x4]
		push eax
		call mini_fread  ; This will fill up the buffer.
		add esp, byte 4*4
		test eax, eax
		jne short .4  ; Not EOF.
		test esi, esi
		jne short .5
		; Indicate EOF as EAX == NULL.
.done:		leave
		pop esi
		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

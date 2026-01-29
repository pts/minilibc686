;
; Manually optimized for size based on the output of soptcc.pl for c_strtok_sep1.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtok_sep1.o strtok_sep1.nasm
;
; Code size: 0x50 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strtok
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
%endif

section .text
; This is a mini strtok implementation which assumes strlen(sep) == 1. This
; assumption makes the code much shorter.
mini_strtok:  ; char *mini_strtok(char *__restrict__ s, const char *__restrict__ sep);
		mov eax, [esp+4]
		mov edx, [esp+8]
		push ebx
		mov dl, [edx]
		test eax, eax
		mov ebx, mini_strtok_global_ptr
		jne .1
		mov eax, [ebx]
		test eax, eax
		jne .1
		pop ebx
		ret
.1:		cmp dl, [eax]
		jne .2
		inc eax
		jmp short .1
.2:		cmp byte [eax], 0
		jne .3
		xor ecx, ecx
		jmp short .set0_return
.3:		mov ecx, eax
.4:		cmp byte [eax], 0
		je .5
		cmp dl, [eax]
		je .5
		inc eax
		jmp short .4
.5:		mov [ebx], eax
		cmp byte [eax], 0
		je .set0_return
		inc eax
		mov byte [eax-1], 0
		jmp short .set_return
.set0_return:	xor eax, eax
.set_return:	mov [ebx], eax
		mov eax, ecx
		pop ebx
		ret

section .bss
mini_strtok_global_ptr:
		resb 4

%ifdef CONFIG_PIC
%error Not PIC because of read-write mini_strtok_global_ptr.
times 1/0 nop
%endif

; __END__

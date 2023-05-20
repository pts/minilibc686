;
; Mostly based on the output of soptcc.pl for c_strtok.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strtok.o strtok.nasm
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
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini_strtok:  ; char *mini_strtok(char *__restrict__ s, const char *__restrict__ sep);
		push ebp
		mov ecx, 0x8
		push edi
		push esi
		push ebx
		sub esp, byte 0x24
		mov eax, [esp+0x3c]
		lea edi, [esp+0x4]
		mov edx, [esp+0x38]
		mov [esp], eax
		xor eax, eax
		test edx, edx
		rep stosd
		jne .2
		mov edx, [mini_strtok_global_ptr]
		test edx, edx
		je near .3
.2:		mov eax, [esp]
		mov al, [eax]
		test al, al
		je .4
		mov esi, [esp]
		mov ebp, 0x1
		cmp byte [esi+0x1], 0x0
		jne .6
.5:		cmp al, [edx]
		jne .4
		inc edx
		jmp short .5
.8:		mov bl, cl
		and cl, 0x1f
		shr bl, 0x5
		movzx edi, bl
		mov ebx, ebp
		sal ebx, cl
		or [esp+edi*0x4+0x4], ebx
		je .11
		inc esi
.6:		mov cl, [esi]
		test cl, cl
		jne .8
.11:		xor esi, esi
		inc esi
		jmp short .9
.42:		mov bl, cl
		and cl, 0x1f
		shr bl, 0x5
		movzx edi, bl
		mov ebx, esi
		sal ebx, cl
		test [esp+edi*0x4+0x4], ebx
		je .4
		inc edx
.9:		mov cl, [edx]
		test cl, cl
		jne .42
.4:		cmp byte [edx], 0x0
		jne .13
		mov dword [mini_strtok_global_ptr], 0x0
		xor edx, edx
		jmp short .3
.13:		test al, al
		je .23
		mov esi, [esp]
		mov ebx, edx
		cmp byte [esi+0x1], 0x0
		je .16
		xor esi, esi
		inc esi
		jmp short .15
.23:		mov ebx, edx
.16:		mov cl, [ebx]
		test cl, cl
		je .19
		cmp al, cl
		je .19
		inc ebx
		jmp short .16
.43:		mov al, cl
		mov edi, esi
		shr al, 0x5
		and cl, 0x1f
		movzx eax, al
		sal edi, cl
		test [esp+eax*0x4+0x4], edi
		jne .19
		inc ebx
.15:		mov cl, [ebx]
		test cl, cl
		jne .43
.19:		cmp byte [ebx], 0x0
		mov [mini_strtok_global_ptr], ebx
		je .21
		lea eax, [ebx+0x1]
		mov [mini_strtok_global_ptr], eax
		mov byte [ebx], 0x0
		jmp short .3
.21:		mov dword [mini_strtok_global_ptr], 0x0
.3:		add esp, byte 0x24
		mov eax, edx
		pop ebx
		pop esi
		pop edi
		pop ebp
		ret

section .bss
mini_strtok_global_ptr:
		resb 4

%ifdef CONFIG_PIC
%error Not PIC because of read-write mini_strtok_global_ptr.
times 1/0 nop
%endif

; __END__

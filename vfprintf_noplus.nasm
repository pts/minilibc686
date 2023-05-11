;
; It supports format flags '-', '0', and length modifiers. It doesn't support format flag '+'.
; Manually improved (but not optimized for size )based on the output of soptcc.pl for c_vfprintf_noplus.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o vfprintf_noplus.o vfprintf_noplus.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_vfprintf
%ifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fputc equ +0x12345678
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
extern mini_fputc
%endif

section .text  ; _TEXT
mini_vfprintf:
		push ebx
		push esi
		push edi
		push ebp
		sub esp, byte 0x24
		mov ebx, [esp+0x3c]
		xor ebp, ebp
.1:
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		jne near .30
		xor eax, eax
		mov [esp+0x14], eax
		xor edi, edi
		inc ebx
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		je near .30
		cmp al, 0x2d
		jne .2
		mov eax, 0x1
		mov [esp+0x14], eax
		add ebx, eax
.2:
		cmp byte [ebx], 0x30
		jne .3
		or byte [esp+0x14], 0x2
		inc ebx
		jmp .2
.3:
		mov al, [ebx]
		cmp al, 0x30
		jl .4
		cmp al, 0x39
		jg .4
		imul edi, byte 0xa
		movsx eax, al
		sub eax, byte 0x30
		add edi, eax
		inc ebx
		jmp .3
.4:
		mov al, [ebx]
		mov esi, esp
		mov ecx, [esp+0x40]
		add ecx, byte 0x4
		cmp al, 0x73
		jne near .14
		mov [esp+0x40], ecx
		mov esi, [ecx-0x4]
		test esi, esi
		jne .5
%ifdef CONFIG_PIC
		call .after_str_null
.str_null:
		; This is also valid i386 machine code:
		; db '(nu'  ;  sub [esi+0x75], ch
		; db 'l'  ; insb
		; db 'l'  ; insb
		; db ')', 0  ; sub [eax], eax
		db '(null)', 0
.after_str_null:
		pop esi  ; ESI := &.str_null.
%else  ; CONFIG_PIC
		mov esi, str_null
%endif  ; CONFIG_PIC
.5:
		mov byte [esp+0x1c], 0x20
		test edi, edi
		jbe .10
		xor eax, eax
		mov ecx, esi
.6:
		cmp byte [ecx], 0x0
		je .7
		inc eax
		inc ecx
		jmp .6
.7:
		cmp eax, edi
		jb .8
		xor edi, edi
		jmp short .9
.8:
		sub edi, eax
.9:
		test byte [esp+0x14], 0x2
		je .10
		mov byte [esp+0x1c], 0x30
.10:
		test byte [esp+0x14], 0x1
		jne .12
.11:
		test edi, edi
		jbe .12
		push dword [esp+0x38]
		movsx eax, byte [esp+0x20]
		push eax
		call mini_fputc
		add esp, byte 0x8
		inc ebp
		dec edi
		jmp .11
.12:
		mov al, [esi]
		test al, al
		je .13
		push dword [esp+0x38]
		movsx eax, al
		push eax
		call mini_fputc
		add esp, byte 0x8
		inc ebp
		inc esi
		jmp .12
.13:
		test edi, edi
		jbe near .32
		push dword [esp+0x38]
		movsx eax, byte [esp+0x20]
		push eax
		call mini_fputc
		add esp, byte 0x8
		inc ebp
		dec edi
		jmp .13
.14:
		cmp al, 0x63
		jne .15
		mov [esp+0x40], ecx
		mov al, [ecx-0x4]
		mov [esp], al
		test edi, edi
		je near .29
		jmp short .17
.15:
		mov [esp+0x40], ecx
		mov ecx, [ecx-0x4]
		cmp al, 0x64
		je .16
		cmp al, 0x75
		je .16
		mov ah, al
		or ah, 0x20
		cmp ah, 0x78
		jne near .33
.16:
		test ecx, ecx
		jne .18
		mov byte [esi], 0x30
.17:
		mov byte [esi+0x1], 0x0
		jmp .5
.18:
		mov ah, al
		or ah, 0x20
		cmp ah, 0x78
		jne .19
		mov esi, 0x10
		jmp short .20
.19:
		mov esi, 0xa
.20:
		mov [esp+0xc], esi
		cmp al, 0x58
		jne .21
		mov esi, 0x41
		jmp short .22
.21:
		mov esi, 0x61
.22:
		sub esi, byte 0x3a
		mov [esp+0x10], esi
		mov ah, [esp+0x10]
		mov [esp+0x20], ah
		cmp al, 0x64
		jne .23
		cmp dword [esp+0xc], byte 0xa
		jne .23
		test ecx, ecx
		jge .23
		mov byte [esp+0x18], 0x1
		neg ecx
		jmp short .24
.23:
		mov byte [esp+0x18], 0x0
.24:
		lea esi, [esp+0xa]
		mov byte [esp+0xa], 0x0
.25:
		test ecx, ecx
		je .27
		xor edx, edx
		mov eax, ecx
		div dword [esp+0xc]
		mov eax, edx
		cmp dl, 0xa
		jb .26
		add al, [esp+0x20]
.26:
		add al, 0x30
		dec esi
		mov [esi], al
		xor edx, edx
		mov eax, ecx
		div dword [esp+0xc]
		mov ecx, eax
		jmp .25
.27:
		cmp byte [esp+0x18], 0x0
		je .5
		test edi, edi
		je .28
		test byte [esp+0x14], 0x2
		je .28
		push dword [esp+0x38]
		push byte 0x2d
		call mini_fputc
		add esp, byte 0x8
		inc ebp
		dec edi
		jmp .5
.28:
		dec esi
		mov byte [esi], 0x2d
		jmp .5
.29:
		push dword [esp+0x38]
		movsx eax, al
		jmp short .31
.30:
		push dword [esp+0x38]
		movsx eax, byte [ebx]
.31:
		push eax
		call mini_fputc
		add esp, byte 0x8
		inc ebp
.32:
		inc ebx
		jmp .1
.33:
		mov eax, ebp
		add esp, byte 0x24
		pop ebp
		pop edi
		pop esi
		pop ebx
		ret

%ifndef CONFIG_PIC
section .rodata
str_null:
		db '(null)', 0
%endif

; __END__

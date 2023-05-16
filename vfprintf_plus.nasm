;
; It supports format flags '-', '+', '0', and length modifiers.
; Manually optimized for size based on the output of soptcc.pl for c_vfprintf_plus.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o vfprintf_plus.o vfprintf_plus.nasm
;
; Code+data size: 0x214 bytes; 0x215 bytes with CONFIG_PIC.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386
B.code equ 0

global mini_vfprintf
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fputc equ $+0x12345678
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
		sub esp, byte 0x20
		mov ebx, [esp+0x38]
		xor ebp, ebp
.1:
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		jne near .30
		xor eax, eax
		mov [esp+0x10], eax
		xor edi, edi
		inc ebx
		mov al, [ebx]
		test al, al
		je near .33
		cmp al, 0x25
		je near .30
		lea edx, [ebx+0x1]
		cmp al, 0x2d
		jne .2
		mov dword [esp+0x10], 0x1
		jmp short .3
.2:
		cmp al, 0x2b
		jne .4
		mov dword [esp+0x10], 0x4
.3:
		mov ebx, edx
.4:
		cmp byte [ebx], 0x30
		jne .5
		or byte [esp+0x10], 0x2
		inc ebx
		jmp short .4
.5:
		xor eax, eax
.5cont:
		mov al, [ebx]
		sub al, '0'
		jl short .6
		cmp al, 9
		jg short .6
		imul edi, byte 0xa
		add edi, eax
		inc ebx
		jmp short .5cont
.6:
		mov al, [ebx]
		mov esi, esp
		mov ecx, [esp+0x3c]
		add ecx, byte 0x4
		cmp al, 0x73
		jne .16
		mov [esp+0x3c], ecx
		mov esi, [ecx-0x4]
		test esi, esi
		jne .7
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
.7:
		mov byte [esp+0x1c], 0x20
		test edi, edi
		jbe .12
		xor edx, edx
		mov ecx, esi
.8:
		cmp byte [ecx], 0x0
		je .9
		inc edx
		inc ecx
		jmp short .8
.9:
		cmp edx, edi
		jb .10
		xor edi, edi
		jmp short .11
.10:
		sub edi, edx
.11:
		test byte [esp+0x10], 0x2
		je .12
		mov byte [esp+0x1c], 0x30
.12:
		test byte [esp+0x10], 0x1
		jne .14
.13:
		test edi, edi
		jbe .14
		mov al, byte [esp+0x1c]
		call .call_mini_fputc
		dec edi
		jmp short .13
.14:
		mov al, [esi]
		test al, al
		je .15
		call .call_mini_fputc
		inc esi
		jmp short .14
.15:
		test edi, edi
		jbe near .32
		mov al, byte [esp+0x1c]
		call .call_mini_fputc
		dec edi
		jmp short .15
.16:
		cmp al, 0x63
		jne .17
		mov [esp+0x3c], ecx
		mov al, [ecx-0x4]
		mov [esp], al
		test edi, edi
		je near .31
		mov byte [esp+0x1], 0x0
		jmp near .7
.17:
		mov [esp+0x3c], ecx
		mov ecx, [ecx-0x4]
		cmp al, 0x64
		je .18
		cmp al, 0x75
		je .18
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne near .33
.18:
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne .19
		mov edx, 0x10
		jmp short .20
.19:
		mov edx, 0xa
.20:
		mov [esp+0xc], edx
		cmp al, 0x58
		jne .21
		mov edx, 0x41
		jmp short .22
.21:
		mov edx, 0x61
.22:
		sub edx, byte 0x3a
		mov [esp+0x18], dl
		cmp al, 0x64
		jne .23
		cmp dword [esp+0xc], byte 0xa
		jne .23
		test ecx, ecx
		jge .23
		mov byte [esp+0x14], 0x2d
		neg ecx
		jmp short .25
.23:
		test byte [esp+0x10], 0x4
		je .24
		mov byte [esp+0x14], 0x2b
		jmp short .25
.24:
		mov byte [esp+0x14], 0x0
.25:
		lea esi, [esp+0xa]
		mov byte [esi], 0x0
		xchg eax, ecx  ; EAX := positive number to print; ECX := junk.
.26:
		xor edx, edx
		div dword [esp+0xc]
		xchg eax, edx  ; EAX := remainder; EDX := quotient.
		cmp al, 10
		jb .27
		add al, [esp+0x18]
.27:
		add al, 0x30
		dec esi
		mov [esi], al
		xchg edx, eax  ; Ater this: EAX == quotient.
		test eax, eax
		jnz .26
		cmp byte [esp+0x14], 0x0
		je .7
		test edi, edi
		jz .28
		test byte [esp+0x10], 0x2
		jz .28
		mov al, byte [esp+0x14]
		call .call_mini_fputc
		dec edi  ; EDI contains the (remaining) width of the current number.
.jmp7:		jmp near .7
.28:
		dec esi
		mov al, [esp+0x14]
		mov [esi], al
		jmp short .jmp7
.30:
		mov al, byte [ebx]
.31:
		call .call_mini_fputc
.32:
		inc ebx  ; TODO(pts): Swap the role of EBX and ESI, and use lodsb.
		jmp near .1
.33:
		xchg eax, ebp  ; EAX := number of bytes written; EBP := junk.
		add esp, byte 0x20
		pop ebp
		pop edi
		pop esi
		pop ebx
		ret
.call_mini_fputc:
		push dword [esp+0x38]
		push eax  ; Only the low 8 bits matter for mini_fputc, the high 24 bits of EAX is garbage here.
		; movsx eax, al : Not neede,d mini_fputc ignores the high 24 bits anyway.
		call B.code+mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
		ret
		
%ifndef CONFIG_PIC
section .rodata
str_null:
		db '(null)', 0
%endif

; __END__

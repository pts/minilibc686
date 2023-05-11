;
; It supports format flags '-', '+', '0', and length modifiers.
; Manually optimized for size based on the output of soptcc.pl for c_vfprintf_plus.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o vfprintf_plus.o vfprintf_plus.nasm

bits 32
cpu 386

global mini_vfprintf
%ifidn __OUTPUT_FORMAT__, bin
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
		sub esp, 0x20
		mov ebx, [esp+0x38]
		xor ebp, ebp
$L$1:
		mov al, [ebx]
		test al, al
		je $L$33
		cmp al, 0x25
		jne $L$30
		xor eax, eax
		mov [esp+0x10], eax
		xor edi, edi
		inc ebx
		mov al, [ebx]
		test al, al
		je $L$33
		cmp al, 0x25
		je $L$30
		lea edx, [ebx+0x1]
		cmp al, 0x2d
		jne $L$2
		mov dword [esp+0x10], 0x1
		jmp $L$3
$L$2:
		cmp al, 0x2b
		jne $L$4
		mov dword [esp+0x10], 0x4
$L$3:
		mov ebx, edx
$L$4:
		cmp byte [ebx], 0x30
		jne $L$5
		or byte [esp+0x10], 0x2
		inc ebx
		jmp $L$4
$L$5:
		mov al, [ebx]
		cmp al, 0x30
		jl $L$6
		cmp al, 0x39
		jg $L$6
		imul edi, 0xa
		movsx edx, al
		sub edx, 0x30
		add edi, edx
		inc ebx
		jmp $L$5
$L$6:
		mov al, [ebx]
		mov esi, esp
		mov ecx, [esp+0x3c]
		add ecx, 0x4
		cmp al, 0x73
		jne $L$16
		mov [esp+0x3c], ecx
		mov esi, [ecx-0x4]
		test esi, esi
		jne $L$7
		mov esi, $L$34
$L$7:
		mov byte [esp+0x1c], 0x20
		test edi, edi
		jbe $L$12
		xor edx, edx
		mov ecx, esi
$L$8:
		cmp byte [ecx], 0x0
		je $L$9
		inc edx
		inc ecx
		jmp $L$8
$L$9:
		cmp edx, edi
		jb $L$10
		xor edi, edi
		jmp $L$11
$L$10:
		sub edi, edx
$L$11:
		test byte [esp+0x10], 0x2
		je $L$12
		mov byte [esp+0x1c], 0x30
$L$12:
		test byte [esp+0x10], 0x1
		jne $L$14
$L$13:
		test edi, edi
		jbe $L$14
		movsx eax, byte [esp+0x1c]
		push dword [esp+0x34]
		push eax
		call mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
		dec edi
		jmp $L$13
$L$14:
		mov al, [esi]
		test al, al
		je $L$15
		movsx eax, al
		push dword [esp+0x34]
		push eax
		call mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
		inc esi
		jmp $L$14
$L$15:
		test edi, edi
		jbe $L$32
		movsx eax, byte [esp+0x1c]
		push dword [esp+0x34]
		push eax
		call mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
		dec edi
		jmp $L$15
$L$16:
		cmp al, 0x63
		jne $L$17
		mov [esp+0x3c], ecx
		mov al, [ecx-0x4]
		mov [esp], al
		test edi, edi
		je $L$29
		mov byte [esp+0x1], 0x0
		jmp $L$7
$L$17:
		mov [esp+0x3c], ecx
		mov ecx, [ecx-0x4]
		cmp al, 0x64
		je $L$18
		cmp al, 0x75
		je $L$18
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne $L$33
$L$18:
		mov dl, al
		or dl, 0x20
		cmp dl, 0x78
		jne $L$19
		mov edx, 0x10
		jmp $L$20
$L$19:
		mov edx, 0xa
$L$20:
		mov [esp+0xc], edx
		cmp al, 0x58
		jne $L$21
		mov edx, 0x41
		jmp $L$22
$L$21:
		mov edx, 0x61
$L$22:
		sub edx, 0x3a
		mov [esp+0x18], dl
		cmp al, 0x64
		jne $L$23
		cmp dword [esp+0xc], 0xa
		jne $L$23
		test ecx, ecx
		jge $L$23
		mov byte [esp+0x14], 0x2d
		neg ecx
		jmp $L$25
$L$23:
		test byte [esp+0x10], 0x4
		je $L$24
		mov byte [esp+0x14], 0x2b
		jmp $L$25
$L$24:
		mov byte [esp+0x14], 0x0
$L$25:
		lea esi, [esp+0xa]
		mov byte [esi], 0x0
$L$26:
		xor edx, edx
		mov eax, ecx
		div dword [esp+0xc]
		xchg eax, edx  ; After this: EAX == remainder, EDX == quotient.
		cmp al, 10
		jb $L$27
		add al, [esp+0x18]
$L$27:
		add al, 0x30
		dec esi
		mov [esi], al
		xchg eax, edx  ; After this: EAX == quotient.
		mov ecx, eax
		; !! Do we still need EAX here? If not, we could do `xchg edx, ecx' above.
		test ecx, ecx
		jnz $L$26
		cmp byte [esp+0x14], 0x0
		je $L$7
		test edi, edi
		je $L$28
		test byte [esp+0x10], 0x2
		je $L$28
		movsx eax, byte [esp+0x14]
		push dword [esp+0x34]
		push eax
		call mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
		dec edi
		jmp $L$7
$L$28:
		dec esi
		mov al, [esp+0x14]
		mov [esi], al
		jmp $L$7
$L$29:
		movsx eax, al
		jmp $L$31
$L$30:
		movsx eax, byte [ebx]
$L$31:
		push dword [esp+0x34]
		push eax
		call mini_fputc
		times 2 pop eax  ; Shorter than `add esp, strict byte 8'.
		inc ebp
$L$32:
		inc ebx
		jmp $L$1
$L$33:
		mov eax, ebp
		add esp, 0x20
		pop ebp
		pop edi
		pop esi
		pop ebx
		ret

section .rodata
$L$34:
		db '(null)', 0  ; !! Embed into .text, position-independent.

; __END__

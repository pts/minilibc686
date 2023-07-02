;
; written by pts@fazekas.hu at Tue May 16 20:08:52 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strcasecmp.o strcasecmp.nasm
;
; Code size: 0x41 bytes.
;
; If you need both mini_strcasecmp(...) and mini_strncasecmp(...), then use
; strncasecmp_both.nasm instead, it has a more compact dual implementation.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcasecmp
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
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
; This only adds 5 bytes to the existing mini_strncasecmp(...) implementation.
mini_strcasecmp:  ; int mini_strcasecmp(const char *l, const char *r);
		push esi
		push edi
		mov esi, [esp+3*4]  ; Start of string l.
		mov edi, [esp+4*4]  ; Start of string r.
; ESI: Start of string l. Will be ruined.
; EDI: Start of string r. Will be ruined.
; ECX: Scratch. Will be ruined.
; EDX: Scratch. Will be ruined.
; EAX: Scratch. The result is returned here.
		xor eax, eax
		xor ecx, ecx
.again:		lodsb
		mov dh, al
		sub dh, 'A'
		cmp dh, 'Z'-'A'
		mov dl, al
		ja .2a
		or al, 0x20
.2a:		movzx eax, al
		mov cl, [edi]
		inc edi
		mov dh, cl
		sub dh, 'A'
		cmp dh, 'Z'-'A'
		mov dh, cl
		ja .2b
		or cl, 0x20
.2b:		sub eax, ecx  ; EAX := tolower(*(unsigned char*)l) - tolower(*(unsigned char*)r), zero-extended.
		jnz .return
		test dh, dh
		jz .return
		test dl, dl
		jnz .again
.return:	pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

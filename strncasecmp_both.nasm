;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strncasecmp_both.o strncasecmp_both.nasm
;
; Code size: 0x4e == 0x4a + 5 bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strcasecmp
global mini_strncasecmp
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
; TODO(pts): Do this with smart linking.
;
; This only adds 5 bytes to the existing mini_strncasecmp(...) implementation.
mini_strcasecmp:  ; int mini_strcasecmp(const char *l, const char *r);
		or ecx, byte -1  ; ECX := -1.
		jmp strict short mini_strncasecmp.have_ecx

; Manually written, 0x4a bytes.
mini_strncasecmp:  ; int mini_strncasecmp(const char *l, const char *r, size_t n);
		mov ecx, [esp+3*4]  ; n (maximum number of bytes to scan).
.have_ecx:	push esi
		push edi
		push ebx
		mov esi, [esp+4*4]  ; Start of string l.
		mov edi, [esp+5*4]  ; Start of string r.
; ESI: Start of string l. Will be ruined.
; EDI: Start of string r. Will be ruined.
; ECX: n (maximum number of bytes to scan). Will be ruined.
; EBX: Scratch. Will be ruined.
; EDX: Scratch. Will be ruined.
; EAX: Scratch. The result is returned here.
		xor eax, eax
		xor ebx, ebx
.again:		jecxz .return
		dec ecx
		lodsb
		mov dh, al
		sub dh, 'A'
		cmp dh, 'Z'-'A'
		mov dl, al
		ja .2a
		or al, 0x20
.2a:		movzx eax, al
		mov bl, [edi]
		inc edi
		mov dh, bl
		sub dh, 'A'
		cmp dh, 'Z'-'A'
		mov dh, bl
		ja .2b
		or bl, 0x20
.2b:		sub eax, ebx  ; EAX := tolower(*(unsigned char*)l) - tolower(*(unsigned char*)r), zero-extended.
		jnz .return
		test dh, dh
		jz .return
		test dl, dl
		jnz .again
.return:	pop ebx
		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

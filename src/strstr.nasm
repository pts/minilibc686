;
; written by pts@fazekas.hu at Wed May 24 23:04:46 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o strchr.o strchr.nasm
;
; Code size: 0x3a bytes.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_strstr
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
mini_strstr:  ; char *strstr(const char *haystack, const char *needle);
; ESI: haystack
; EDI: needle
; EDX: strlen(haystack)
; ECX: strlen(needle)
		push esi
		push edi
		xor eax, eax  ; AL := 0, for the scasb comparisons below.
		mov esi, [esp+0xc]  ; Argument haystack.
		mov edi, esi
		or edx, byte -1  ; EDX := -1.
		mov ecx, edx  ; ECX := 1.
		repne scasb
		not ecx  ; ECX := strlen(haystack) + 1.
		xchg edx, ecx  ; ECX := -1, EDX := strlen(haystack) + 1.
		mov edi, [esp+0x10]  ; Argument needle.
		push edi
		repne scasb
		not ecx
		dec ecx  ; ECX := strlen(needle).
		pop edi
		; Now EDI, ESI, EDX and ECX are corredly set up (as above).
		jecxz .found
		sub edx, ecx
		jbe .missing  ; needle too long.
		; From this point EDX is a counter, not strlen(haystack) anymore.
.again:		push esi
		push edi
		push ecx
		repz cmpsb  ; Continue while equal.
		pop ecx
		pop edi
		pop esi
		je .found
		inc esi  ; haystack += 1.
		dec edx
		jnz .again
.missing:	xor esi, esi  ; Result := NULL.
.found:		xchg eax, esi  ; Result := haystack.
.done:		pop edi
		pop esi
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

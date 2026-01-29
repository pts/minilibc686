;
; written by pts@fazkeas.hu at Tue May 23 15:56:06 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_puts.o stdio_medium_puts.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_puts
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_fwrite equ +0x12345678
mini_stdout equ +0x12345678
%else
extern mini_fwrite
extern mini_stdout
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_puts:  ; int mini_puts(const char *s);
; TODO(pts): Provide an alternative implementation based on mini_fputc(...),
; like mini_vfprintf(...). Will it be shorter (when also considering the
; size of mini_fwrite(...)?
		push edi
		mov edi, [esp+8]  ; Argument s.
		push edi
		xor eax, eax
		or ecx, byte -1  ; ECX := -1.
		repne scasb
		sub eax, ecx
		dec eax
		dec eax  ; EAX := strlen(s).
		pop edi  ; EDI := s.
		push byte 0xa  ; '\n'.
		; size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep);
		push dword [mini_stdout]  ; Argument filep of mini_fwrite(...).
		push eax  ; Argument nmemb of mini_fwrite(...).
		push byte 1  ; Argument size of mini_fwrite(...).
		push edi  ; Argument ptr of mini_fwrite(...).
		call mini_fwrite
		test eax, eax
		js .done
		add esp, byte 3*4  ; Clean up arguments of mini_fwrite(...) from the stack, except from filep.
		; size_t fwrite(const void *ptr, size_t size, size_t nmemb, FILE *filep);
		lea eax, [esp+4]  ; Points to the '\n' pushed above.
		push byte 1  ; Argument nmemb of mini_fwrite(...).
		push byte 1  ; Argument size of mini_fwrite(...).
		push eax  ; Argument ptr of mini_fwrite(...).
		call mini_fwrite
.done:		add esp, byte 5*4  ; Clean up arguments of mini_fwrite(...) and the '\n' from the stack.
		pop edi
		ret  ; The return value in EAX is just perfect for us.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Thu Jun 22 11:56:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o getcwd_linux.o getcwd_linux.nasm
;
; Code size: 0x1f bytes.
;
; Limitation: if argument buf is NULL, then it returns NULL, it doesn't allocate memory dynamically.

; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_getcwd
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
mini_getcwd:  ; char *mini_getcwd(char *buf, size_t size);
		push ebx
		xor eax, eax
		mov ebx, [esp+2*4]  ; Argument buf.
		test ebx, ebx
		jz .done  ; We don't support dynamic memory allocation if buf is NULL. TODO(pts): Set errno = EINVAL.
		mov al, 183  ; __NR_getcwd.
		mov ecx, [esp+3*4]  ; Argument size.
		int 0x80  ; Linux i386 syscall.
		cmp eax, -0x100  ; Treat very large (e.g. <-0x100; with Linux 5.4.0, 0x85 seems to be the smallest) non-negative return values as success rather than errno. This is needed by time(2) when it returns a negative timestamp. uClibc has -0x1000 here.
		jna .success  ; Ignore the return value (number of bytes copied to `buf', including the terminating NUL).
		; TODO(pts): Set errno = EBX.
		xor ebx, ebx  ; EBX := NULL, indicating error.
.success:	xchg eax, ebx  ; EAX := argument buf or NULL; EBX := junk.
.done:		pop ebx
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

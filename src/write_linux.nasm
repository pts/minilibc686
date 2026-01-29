;
; written by pts@fazekas.hu at Tue May 16 13:38:22 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o write_linux.o write_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_write
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_write:  ; ssize_t mini_write(int fd, const void *buf, size_t count);
		push ebx  ; EAX, ECX and EDX doesn't have to be restored, according to the SYSV calling convention.
		xor eax, eax
		mov al, 4  ; EAX := 4 == __NR_write.
		mov ebx, [esp+8]  ; Argument fd.
		mov ecx, [esp+0xc]  ; Argument buf.
		mov edx, [esp+0x10]  ; Argument count.
		int 0x80  ; Linux i386 syscall, write(2) doesn't return.
		pop ebx
		test eax, eax
		jns .ok
		;neg eax
		;mov dword [__minidiet_errno], eax
		or eax, byte -1	; Set return value to -1.
.ok:		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Wed May 17 00:43:13 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o start_linux.o start_linux.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_fputc
global mini_stdout
global mini_stderr
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_write equ +0x12345678
%else
extern mini_write
section .text align=1
section .rodata align=4
section .data align=1
section .bss align=1
%endif

section .text
; It ignores the `stream' argument, always writes to stdout.
mini_fputc:  ; int fputc(int c, FILE *filep);
		movzx eax, byte [esp+4]  ; Byte to be written.
.again:		push eax
		push strict byte 1  ; Write 1 byte.
		push esp
		add dword [esp], byte 4  ; Points to the EAX pushed, byte to be written.
		mov eax, [esp+0x14]  ; filep argument. The dword there is the file descriptor.
		push dword [eax]
		call mini_write
		add esp, byte 3*4
		test eax, eax
		jnz .nz
		pop eax
		jmp short .again  ; No bytes written, write again.
.nz:		cmp eax, byte -1
		jne .ok
		pop edx  ; Ignore original character, return -1 indicating error.
		ret
.ok:		pop eax  ; Return (unsigned char)c.
		ret

section .rodata
struct_stdout:	dd 1  ; File descriptor.
struct_stderr:	dd 2  ; File descriptor.
mini_stdout:	dd struct_stdout
mini_stderr:	dd struct_stderr

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

;
; written by pts@fazekas.hu at Tue Nov 19 18:31:56 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o perror.o perror.nasm
;
; Code size: 0x5a bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_perror
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini_strerror equ +0x12345678
mini_errno equ +0x12345679
mini_write equ +0x1234567a
%else
extern mini_strerror
extern mini_errno
extern mini_write
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_perror:  ; void mini_perror(const char *s);
		mov ecx, [esp+4]  ; s.
		test ecx, ecx
		jz short .after_prefix
		cmp byte [ecx], 0
		je short .after_prefix
		push ecx
		call write_msg_to_stderr
		push strict dword ':'|(' '<<8)  ; Separator.
		push esp
		call write_msg_to_stderr
		pop eax  ; Pop the separator pointer.
.after_prefix:	push dword [mini_errno]  ; Argument errnum of mini_strerror.
		call mini_strerror
		pop ecx  ; Clean up argument errnum of mini_strerror.
		push eax  ; Error message returned by mini_stderror.
		call write_msg_to_stderr
		push strict dword 10  ; Newline.
		push esp
		call write_msg_to_stderr
		pop eax  ; Pop the newline pointer.
		ret

; !! Write single message only. Is it shorter?
write_msg_to_stderr:  ; Takes and pops NUL-terminated message from the stack. !! Doesn't: Ruins EAX, ECX, EDX and EDI.
.next_str:	mov eax, [esp+4]  ; Message.
		xor ecx, ecx
.0:		inc ecx
		cmp byte [eax+ecx-1], 0
		jne short .0
		dec ecx
		push ecx  ; Argument count of mini_write.
		push eax  ; Argument buf of mini_write.
		push byte 2  ; STDERR_FILENO.
		call mini_write
		add esp, byte 3*4  ; Clean up arguments of mini_write from the stack.
.done:		ret 4

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

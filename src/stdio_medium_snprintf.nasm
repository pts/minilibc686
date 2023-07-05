;
; written by pts@fazkeas.hu at Tue May 23 13:37:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_snprintf.o stdio_medium_snprintf.nasm
;
; Code size: 0x41 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_snprintf
global mini_snprintf.do
%ifdef CONFIG_SECTIONS_DEFINED
extern mini_vfprintf
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini_vfprintf equ +0x12345678
%else
extern mini_vfprintf
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .text
mini_snprintf:  ; int mini_snprintf(char *str, size_t size, const char *format, ...);
		lea edx, [esp+4]  ; Address of argument str.
		lea eax, [edx+0xc]  ; Address of `...'.
mini_snprintf.do:  ; !! mini_vsnprintf(...) jumps here.
		; It matches struct _SMS_FILE defined in c_stdio_medium.c. sizeof(struct _SMS_FILE).
		push byte 0  ; .buf_off.
		push byte -1  ; .buf_capacity_end.
		push dword [edx]  ; .buf_start == str argument.
		push byte 7  ; .dire == FD_WRITE_SATURATE. Also push the 3 .padding bytes.
		push byte -1  ; .fd.
		push byte 0  ; .buf_last.
		push byte 0  ; .buf_read_ptr.
		mov ecx, [edx-8+0xc]  ; Argument size.
		test ecx, ecx
		jnz .set_limit
.zero_size:	push ecx  ; .buf_end := NULL: practically unlimited buffer.
		push ecx  ; .buf_write_ptr := .buf_end (== NULL) if size == 0. Actual value doesn't matter.
		jmp short .after_size
.set_limit:	dec ecx
		add ecx, [edx]  ; Argument str.
		push ecx  ; .buf_end: limited by argument size.
		push dword [edx]  ; .buf_write_ptr == str argument.
.after_size:
		; int mini_vfprintf(FILE *filep, const char *format, va_list ap);
		mov ecx, esp  ; Address of newly created struct _SMS_FILE on stack.
		push eax  ; Argument ap of mini_vfprintf(...).
		push dword [edx-4+0xc]  ; Argument format of mini_vfprintf(...).
		push ecx  ; Argument filep of mini_vfprintf(...). Address of newly created struct _SMS_FILE on stack.
		call mini_vfprintf
		mov edx, [esp+3*4]  ; .buf_write_ptr.
		test edx, edx  ; .buf_write_ptr == NULL?
		jz .no_term
		mov byte [edx], 0  ; Terminate with '\0'.
.no_term:	add esp, byte (3+9)*4  ; Clean up arguments of mini_vfprintf(...) and the struct _SMS_FILE from the stack.
		ret 

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

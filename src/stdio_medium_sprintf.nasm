;
; written by pts@fazkeas.hu at Tue May 23 13:37:23 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_sprintf.o stdio_medium_sprintf.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_sprintf
global mini_sprintf.do
%ifdef CONFIG_SECTIONS_DEFINED
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
mini_sprintf:  ; int mini_sprintf(char *str, const char *format, ...);
		lea edx, [esp+0xc]  ; Argument `...'.
		mov eax, edx  ; Smart linking could eliminate this (and use EDX instead) if mini_vsprintf(...) wasn't in use.
mini_sprintf.do:  ; mini_vsprintf(...) jumps here.
		; It matches struct _SMS_FILE defined in c_stdio_medium.c. sizeof(struct _SMS_FILE).
		push byte 0  ; .buf_off.
		push byte -1  ; .buf_capacity_end.
		push dword [edx-8]  ; .buf_start == str argument.
		push byte 4  ; .dire == FD_WRITE. Also push the 3 .padding bytes.
		push byte -1  ; .fd.
		push byte 0  ; .buf_last.
		push byte 0  ; .buf_read_ptr.
		push byte -1  ; .buf_end: practically unlimited buffer.
		push dword [edx-8]  ; .buf_write_ptr == str argument.
		; int mini_vfprintf(FILE *filep, const char *format, va_list ap);
		mov ecx, esp  ; Address of newly created struct _SMS_FILE on stack.
		push eax  ; Argument ap of mini_vfprintf(...).
		push dword [edx-4]  ; Argument format of mini_vfprintf(...).
		push ecx  ; Argument filep of mini_vfprintf(...). Address of newly created struct _SMS_FILE on stack.
		call mini_vfprintf
		mov edx, [esp+3*4]  ; .buf_write_ptr.
		mov byte [edx], 0  ; Add '\0'. It's OK to omit the `EDX == NULL' check here, uClibc and EGLIBC also omit it.
		add esp, byte (3+9)*4  ; Clean up arguments of mini_vfprintf(...) and the struct _SMS_FILE from the stack.
		ret 

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

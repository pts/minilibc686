;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdout.o stdio_medium_stdout.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_stdout
global mini___M_start_isatty_stdout
global mini___M_start_flush_stdout
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
mini_isatty equ +0x12345678
mini_fflush equ +0x12345679
%else
extern mini_isatty  ; Force linking it.
extern mini_fflush
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
%endif

section .text
mini___M_start_isatty_stdout:
		push byte 1  ; STDOUT_FILENO.
		call mini_isatty
		pop edx  ; Clean up the argument of mini_isatty from the stack.
		add eax, eax
		add [mini_stdout_struct.dire], al  ; filep->dire = FD_WRITE_LINEBUF, changed from FD_WRITE.
		ret
mini___M_start_flush_stdout:
		push dword [mini_stdout]
		call mini_fflush
		pop edx  ; Clean up the argument of mini_fflush from the stack.
		ret
%ifidn __OUTPUT_FORMAT__, bin  ; Affects start_stdio_medium_linux.nasm %included()d later: it won't try to redefine these symbols.
  %define mini___M_start_isatty_stdout mini___M_start_isatty_stdout
  %define mini___M_start_flush_stdout  mini___M_start_flush_stdout
%endif

section .data
mini_stdout:	dd mini_stdout_struct
mini_stdout_struct:  ; Layout must match `struct _SMS_FILE' in stdio_medium_*.nasm and c_stdio_medium.c.
.buf_write_ptr	dd stdout_buf
.buf_end	dd stdout_buf.end
.buf_read_ptr	dd stdout_buf
.buf_last	dd stdout_buf
.fd		dd 1  ; STDOUT_FILENO.
.dire		db 4  ; FD_WRITE.
.padding	db 0, 0, 0
.buf_start	dd stdout_buf
.buf_capacity_end dd stdout_buf.end
.buf_off	dd 0

section .bss
stdout_buf	resb 0x400  ; Match glibc 2.19 stdout buffer size on a TTY.
.end:

%ifdef CONFIG_PIC
%error Not PIC because it defines global variables.
times 1/0 nop
%endif

; __END__

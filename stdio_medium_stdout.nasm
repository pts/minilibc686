;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdout.o stdio_medium_stdout.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_stdout
global mini___M_stdout_for_flushall
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
mini___M_init_isatty equ +0x12345678
%else
extern mini___M_init_isatty  ; Force linking it.
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .data
mini___M_stdout_for_flushall:
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

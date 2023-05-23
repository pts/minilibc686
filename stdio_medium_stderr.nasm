;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_stderr.o stdio_medium_stderr.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_stderr
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .data
mini_stderr:	dd mini_stderr_struct
mini_stderr_struct:  ; Layout must match `struct _SMS_FILE' in stdio_medium_*.nasm and c_stdio_medium.c.
.buf_write_ptr	dd stderr_buf
.buf_end	dd stderr_buf  ; Since buf_end == buf_write_str, stderr is unbuffered (i.e. autoflushed).
.buf_read_ptr	dd stderr_buf
.buf_last	dd stderr_buf
.fd		dd 2  ; STDERR_FILENO.
.dire		db 4  ; FD_WRITE.
.padding	db 0, 0, 0
.buf_start	dd stderr_buf
.buf_capacity_end dd stderr_buf.end
.buf_off	dd 0

section .bss
stderr_buf	resb 0x400  ; Match glibc 2.19 stderr buffer size on a TTY.
.end:

%ifdef CONFIG_PIC
%error Not PIC because it defines global variables.
times 1/0 nop
%endif

; __END__

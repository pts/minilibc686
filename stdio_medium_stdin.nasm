;
; written by pts@fazkeas.hu at Mon May 22 20:04:02 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_stdin.o stdio_medium_stdin.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_stdin
global mini___M_stdin_for_flushall
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

section .data
mini___M_stdin_for_flushall:
mini_stdin:	dd mini_stdin_struct
mini_stdin_struct:  ; Layout must match `struct _SMS_FILE' in stdio_medium_*.nasm and c_stdio_medium.c.
.buf_write_ptr	dd stdin_buf.end  ; Sentinel to prevent writes.
.buf_end	dd stdin_buf.end
.buf_read_ptr	dd stdin_buf
.buf_last	dd stdin_buf
.fd		dd 0  ; STDIN_FILENO.
.dire		db 1  ; FD_READ.
.padding	db 0, 0, 0
.buf_start	dd stdin_buf
.buf_capacity_end dd stdin_buf.end
.buf_off	dd 0

section .bss
stdin_buf	resb 0x400  ; Match glibc 2.19 stdin buffer size on a TTY.
.end:

%ifdef CONFIG_PIC
%error Not PIC because it defines global variables.
times 1/0 nop
%endif

; __END__

;
; demo_hello_linux_nasm.nasm: Linux i386 32-bit ELF executable program without a libc
; by pts@fazekas.hu at Tue May 16 12:20:36 CEST 2023
;
; Compile to Linux i386 32-bit ELF executable:
;
;     nasm -O999999999 -w+orphan-labels -f bin -o demo_hello_linux_nolibc.prog demo_hello_linux_nolibc.nasm &&
;     chmod +x demo_hello_linux_nolibc.prog
;
; Alternatively, you can compile with Yasm (tested with 1.2.0 and 1.3.0)
; instead of NASM. The output is bitwise identical.
;
; Run it on Linux i386 or Linux amd64 systems:
;
;     ./demo_hello_linux_nolibc.prog
;
; Please note that this is an educational example program, and it's not
; intended to be absolutely minimal in size. For that, see
; https://github.com/pts/mininasm/blob/master/demo/hello/hellohli3.nasm and
; https://github.com/pts/mininasm/blob/master/demo/hello/helloli3.nasm .
;

%define ALIGN_RODATA 1
%include "elf0.inc.nasm"

_start:  ; ELF program entry point.
		xor ebx, ebx		; EBX := 0. This isn't necessary since Linux 2.2, but it is in Linux 2.0: ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		inc ebx			; EBX := 1 == STDOUT_FILENO.
		mov al, 4		; EAX := __NR_write == 4. EAX happens to be 0. https://stackoverflow.com/a/9147794
		push ebx
		mov ecx, message	; Pointer to message string.
		mov dl, message.end-message  ; EDX := size of message to write. EDX is 0 since Linux 2.0 (or earlier): ELF_PLAT_INIT: https://asm.sourceforge.net/articles/startup.html
		int 0x80		; Linux i386 syscall.
		;mov eax, 1		; __NR_exit.
		pop eax			; EAX := 1 == __NR_exit.
		;mov ebx, 0		; EXIT_SUCCESS.
		dec ebx			; EBX := 0 == EXIT_SUCCESS.
		int 0x80		; Linux i386 syscall.

section .rodata
message:	db 'Hello, World!', 10
.end:

_end  ; __END__

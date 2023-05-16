;
; demo_hello_linux.nasm: 
; by pts@fazekas.hu at Tue May 16 12:20:36 CEST 2023
;
; Compile to Linux i386 32-bit ELF executable:
;
;     nasm -O999999999 -w+orphan-labels -f bin -o demo_hello_linux demo_hello_linux.nasm &&
;     chmod +x demo_hello_linux
;
; Run it on Linux i386 or Linux amd64 systems:
;
;     ./demo_hello_linux
;

bits 32
cpu 386

%ifdef __YASM_MAJOR__  ; Yasm. For correct memsz calculation of .bss.
%define NOBITS_VFOLLOWS(x) vfollows=x
%else  ; NASM. It fails for sections with `nobits vfollows=...'.
%define NOBITS_VFOLLOWS(x)
%endif

; TODO(pts): Add support for alignment (align=4 and align=8).
%define CONFIG_SECTIONS_DEFINED  ; Used by the %include files.
section .elfhdr align=1 valign=1 vstart=0x8048000
section .text align=1 valign=1 follows=.elfhdr vfollows=.elfhdr
text_start:
section .rodata align=1 valign=1 follows=.text vfollows=.text
rodata_start:
;section .data align=1 valign=1 follows=.rodata vfollows=.rodata
;section .bss align=1 NOBITS_VFOLLOWS(.data) nobits

PT:  ; Symbolic constants for ELF PT_... (program header type).
.LOAD equ 1
.NOTE equ 4
.GNU_EH_FRAME equ 0x6474e550
.GNU_STACK equ 0x6474e551  ; GNU stack.

section .elfhdr
X.ELF_ehdr:
ehdr:					; Elf32_Ehdr
		db 0x7f, 'ELF'		;   e_ident[EI_MAG...]
		db 1			;   e_ident[EI_CLASS]: 32-bit
		db 1			;   e_ident[EI_DATA]: little endian
		db 1			;   e_ident[EI_VERSION]
		db 3			;   e_ident[EI_OSABI]: Linux
		db 0			;   e_ident[EI_ABIVERSION]
		db 0, 0, 0, 0, 0, 0, 0	;   e_ident[EI_PAD]
		dw 2			;   e_type == ET_EXEC.
		dw 3			;   e_machine == x86.
		dd 1			;   e_version
		dd _start		;   e_entry
		dd phdr0-ehdr		;   e_phoff
		dd 0			;   e_shoff
		dd 0			;   e_flags
		dw .size		;   e_ehsize
		dw phdr0.size		;   e_phentsize
		dw (phdr_end-phdr0)/phdr0.size  ;   e_phnum
		dw 0x28			;   e_shentsize
		dw 0			;   e_shnum
		dw 0			;   e_shstrndx
ehdr.size	equ $-ehdr

phdr0:					; Elf32_Phdr
		dd PT.LOAD		;   p_type
		dd 0			;   p_offset
		dd ehdr			;   p_vaddr
		dd ehdr			;   p_paddr
		dd elf_file_size	;   p_filesz
		dd elf_file_size	;   p_memsz
		dd 5			;   p_flags: r-x: read and execute, no write
		dd 0x1000		;   p_align
.size		equ $-phdr0
;phdr1:					; Elf32_Phdr
;		dd PT.LOAD		;   p_type
;		dd .........		;   p_offset
;		dd .........		;   p_vaddr
;		dd .........		;   p_paddr
;		dd .........		;   p_filesz
;		dd .........		;   p_memsz
;		dd 6			;   p_flags: rw-: read and write, no execute
;		dd 0x1000		;   p_align
;hdr2:					; Elf32_Phdr
;		dd PT.GNU_STACK		;   p_type
;		dd 0			;   p_offset
;		dd 0			;   p_vaddr
;		dd 0			;   p_paddr
;		dd +0			;   p_filesz
;		dd +0			;   p_memsz
;		dd 6			;   p_flags: rw-: read and write, no execute
;		dd 0			;   p_align
phdr_end:

section .text
_start:  ; ELF program entry point.
%ifdef CONFIG_NO_LIBC
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
%else
		push eax		; Push 0 == EXIT_SUCCESS early, just to show that we clean up the stack properly.

		sub esp, byte 0x7f	; Create buffer of this size on the stack.
		push esp		; End pointer for printing.
		mov eax, esp
		push strict dword addressee
		push esp		; va_list ap.
		push strict dword format
		push eax		; Push the address of the end pointer.
		call mini_vfprintf	; Print to buffer. Calls mini_putc (defined below) for each byte.
		add esp, byte 4*4	; Clean up arguments the stack, now the end pointer and the buffer remains.

		mov eax, 4		; EAX := __NR_write == 4.
		mov ebx, 1		; EBX := 1 == STDOUT_FILENO.
		lea ecx, [esp+4]	; ECX: := Address of buffer.
		mov edx, [esp]		; EDX := End pointer value.
		sub edx, ecx		; EDX := Number of bytes to print.
		int 0x80		; Linux i386 syscall.

		pop eax			; Remove end pointer from the stack.
		add esp, byte 0x7f	; Remove buffer from the stack.

		pop ebx			; EBX := Exit code.
		xor eax, eax
		inc eax			; EAX := 1 == __NR_exit.
		int 0x80		; Linux i386 syscall.

; Appends the character to the end pointer, increments te end pointer.
mini_fputc:	mov dl, [esp+4]		; Byte (character) to be printed.
		mov eax, [esp+8]	; End pointer.
		push eax
		mov eax, [eax]
		mov [eax], dl
		pop eax			; End pointer.
		inc dword [eax]
		ret
%endif

%ifndef CONFIG_NO_LIBC
%include "vfprintf_noplus.nasm"
%endif

section .rodata
%ifdef CONFIG_NO_LIBC
message:	db 'Hello, World!', 10
.end:
%else
format:		db 'Hello, %s!', 10, 0
addressee:	db 'World', 0
%endif

section .elfhdr
elfhdr_end:
section .text
text_end:
section .rodata
rodata_end:
elf_file_size equ (elfhdr_end-ehdr)+(text_end-text_start)+(rodata_end-rodata_start)

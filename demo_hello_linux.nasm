;
; demo_hello_linux.nasm: 
; by pts@fazekas.hu at Tue May 16 12:20:36 CEST 2023
;
; Compile to Linux i386 32-bit ELF executable:
;
;     nasm -O999999999 -w+orphan-labels -f bin -o demo_hello_linux demo_hello_linux.nasm &&
;     chmod +x demo_hello_linux
;
; Alternatively, you can compile with Yasm (tested with 1.2.0 and 1.3.0)
; instead of NASM. The output is bitwise identical.
;
; Run it on Linux i386 or Linux amd64 systems:
;
;     ./demo_hello_linux
;

bits 32
cpu 386

; TODO(pts): Add support for alignment (align=4 and align=8).
%define CONFIG_SECTIONS_DEFINED  ; Used by the %include files.
prog_org equ 0x8048000
section .elfhdr align=1 valign=1 vstart=(prog_org)
section .text align=1 valign=1 follows=.elfhdr vfollows=.elfhdr
text_start:
section .rodata align=1 valign=1 follows=.text vfollows=.text
rodata_start:
%ifdef __YASM_MAJOR__
section .datagap align=1 valing=1 follow=.rodata vfollows=.rodata nobits
section .data align=1 valign=1 follows=.rodata vfollows=.datagap progbits
%else
section .data align=1 valign=1 follows=.rodata vstart=(data_vstart) progbits
%endif
data_start:
%ifdef __YASM_MAJOR__
section .bss align=1 valign=1 follows=.data vfollows=.data nobits
%else
section .bss align=1 follows=.data nobits
%endif
bss_start:


PT:  ; Symbolic constants for ELF PT_... (program header type).
.LOAD equ 1
.NOTE equ 4
.GNU_EH_FRAME equ 0x6474e550
.GNU_STACK equ 0x6474e551  ; GNU stack.

section .elfhdr
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
		dd file_size_before_data  ;   p_filesz
		dd file_size_before_data  ;   p_memsz
		dd 5			;   p_flags: r-x: read and execute, no write
		dd 0x1000		;   p_align
.size		equ $-phdr0
%ifndef CONFIG_NO_RW_SECTIONS
phdr1:					; Elf32_Phdr
		dd PT.LOAD		;   p_type
		dd file_size_before_data  ;   p_offset
		dd data_vstart		;   p_vaddr
		dd data_vstart		;   p_paddr
		dd (elf_file_size-file_size_before_data)  ;   p_filesz
		dd (elf_file_size-file_size_before_data)+(bss_end-bss_start)  ;   p_memsz
		dd 6			;   p_flags: rw-: read and write, no execute
		dd 0x1000		;   p_align
%endif
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
%ifdef CONFIG_NO_LIBC
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
%else
main:  ; int main(int argc, char **argv, char **envp);  /* envp is optional to declare and/or use. */
		cmp dword [esp+4], byte 4  ; argc == 4?
		jne short .after_envp
		; If argc == 4, print envp[0] (without a trailing newline).
		mov eax, [esp+0xc]	; EAX := address of the envp[0] string.
		mov edx, [eax]		; EDX := The envp[0] string.
		call strlen_edx		; EAX := strlen(envp[0]). TODO(pts): Use mini_strlen(...), when available.
		push eax		; Argument count for mini_write(...): strlen(envp[0]).
		push edx		; Argument buf for mini_write(...): envp[0].
		push strict byte 1	; Argument fd (1 == STDOUT_FILENO) for mini_write(...).
		call mini_write
		add esp, byte 3*4	; Clean up arguments of mini_write(...) above from the stack.
.after_envp:

		xor eax, eax		; EAX := 0 == EXIT_SUCCESS.
		push eax		; Push 0 == EXIT_SUCCESS early, just to show that we clean up the stack properly.

		sub esp, byte 0x7c	; Create buffer of this size on the stack.
		push esp		; End pointer for printing.
		mov eax, esp
		push strict dword addressee
		push esp		; va_list ap.
		push strict dword format
		push eax		; Push the address of the end pointer.
		call mini_vfprintf	; Print to buffer. Calls mini_putc (defined below) for each byte.
		add esp, byte 4*4	; Clean up arguments of mini_vfprintf(...) above from the stack, now the end pointer and the buffer remains.

		lea ecx, [esp+4]	; ECX: := Address of buffer.
		mov edx, [esp]		; EDX := End pointer value.
		add ecx, [esp+0x7c+0xc] ; ECX += argc. Skip printing of the first few bytes.
		dec ecx			; Base skip count: if argc == 0, don't skip anything.
		sub edx, ecx		; EDX := Number of bytes to print.
		push edx		; Argument count for mini_write(...).
		push ecx		; Argument buf for mini_write(...).
		push strict byte 1	; Argument fd (1 == STDOUT_FILENO) for mini_write(...).
		call mini_write
		add esp, byte 3*4	; Clean up arguments of mini_write(...) above from the stack.

		pop eax			; Remove end pointer from the stack.
		add esp, byte 0x7c	; Remove buffer from the stack.

		pop eax			; Return value (program exit code).
		ret

; Appends the character to the end pointer, increments te end pointer.
mini_fputc:	mov dl, [esp+4]		; Byte (character) to be printed.
		mov eax, [esp+8]	; End pointer.
		push eax
		mov eax, [eax]
		mov [eax], dl
		pop eax			; End pointer.
		inc dword [eax]
		ret

; Set EAX to the ASCIIZ string length (excluding the trailing NUL) starting at EDX.
strlen_edx:	xor eax, eax
.next:		cmp byte [edx+eax], 0
		je strict short .done
		inc eax
		jmp strict short .next
.done:		ret

;section .data
;		db 'Hit'
;		dd buf
;section .bss
;buf:		resb 0x100

%endif

%ifndef CONFIG_NO_LIBC
%include "vfprintf_plus.nasm"
%include "write_linux.nasm"
%include "start_linux.nasm"
_start equ mini__start  ; ELF program entry point defined in start_linux.nasm.
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
section .data
data_end:
section .bss
bss_end:
;
file_size_before_data equ (elfhdr_end-ehdr)+(text_end-text_start)+(rodata_end-rodata_start)
elf_file_size equ file_size_before_data+(data_end-data_start)
data_vstart equ prog_org+((file_size_before_data+0xfff)&~0xfff)+(file_size_before_data&0xfff)
%ifdef __YASM_MAJOR__
  section .datagap
  resb data_vstart-(prog_org+file_size_before_data)
%endif
%ifdef CONFIG_NO_RW_SECTIONS
  %if data_end-data_start
    %error .data must be empty with .CONFIG_NO_RW_SECTIONS
    times 1/0 nop  ; Force fatal error.
  %endif
  %if bss_end-bss_start
    %error .bss must be empty with .CONFIG_NO_RW_SECTIONS
    times 1/0 nop  ; Force fatal error.
  %endif
%endif

; __END__

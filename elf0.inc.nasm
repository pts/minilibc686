;
; elf0.inc.nasm: NASM plumbing to build Linux i386 32-bit ELF executables
; by pts@fazekas.hu at Tue May 16 12:20:36 CEST 2023
;
; Usage in your prog.nasm:
;
;     %include "elf0.inc.nasm"
;     _start:
;     ... ; Put your code here.
;     _end  ; Must be at the end of the file.
;
; If you forget the _end, NASM (and Yasm) will fail with an error:
;
;     error: symbol `prog_org' not defined before use
;
; Compile to Linux i386 32-bit ELF executable:
;
;     nasm -O999999999 -w+orphan-labels -f bin -o prog prog.nasm &&
;     chmod +x prog
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
section .elfhdr align=1 valign=1 vstart=(prog_org)
section .text align=1 valign=1 follows=.elfhdr vfollows=.elfhdr
text_start:
section .rodata align=1 valign=1 follows=.text vfollows=.text
rodata_start:
%ifdef __YASM_MAJOR__
section .datagap align=1 valign=1 follow=.rodata vfollows=.rodata nobits
datagap_start:
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

section .text

%macro _end 0
prog_org equ 0x8048000

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
  datagap_presize equ $-datagap_start
  times datagap_presize|-datagap_presize nop  ; Fails with `error: multiple is negative' if datagap_presize is nonzero.
  resb data_vstart-(prog_org+file_size_before_data)
  times (data_end-data_start)|-(data_end-data_start) nop
  times (bss_end-bss_start)|-(bss_end-bss_start) nop
%else
  %ifdef CONFIG_NO_RW_SECTIONS
    %if data_end-data_start  ; Doesn't work in Yasm, Yasm needs a constant expression here.
      %error .data must be empty with .CONFIG_NO_RW_SECTIONS
      times 1/0 nop  ; Force fatal error.
    %endif
    %if bss_end-bss_start  ; Doesn't work in Yasm, Yasm needs a constant expression here.
      %error .bss must be empty with .CONFIG_NO_RW_SECTIONS
      times 1/0 nop  ; Force fatal error.
    %endif
  %endif
%endif
section .bss

%endmacro  ; _end

;
; written by pts@fazkeas.hu at Tue May 23 03:06:53 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_flush_opened.o stdio_medium_flush_opened.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_global_files
global mini___M_global_files_end
global mini___M_global_file_bufs
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
%else
extern mini_fflush_RP3  ; !! Is this needed for smart.nasm etc. to track dependencies?
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

; Using the SMGF_ prefix to avoid `equ' conflict with
; stdio_medium_flush_opened.nasm, both us and them included from smart.nasm.
SMGF_SIZEOF_STRUCT_SMS_FILE equ 0x24   ; It matches struct _SMS_FILE defined in c_stdio_medium.c. sizeof(struct _SMS_FILE).
SMGF_BUF_SIZE equ 0x1000  ; It matches BUFSIZ defined in <stdio.h>. It matches BUF_SIZE defined in c_stdio_medium.c.
%ifndef CONFIG_FILE_CAPACITY
  %define CONFIG_FILE_CAPACITY 20
%endif
SMGF_FILE_CAPACITY equ CONFIG_FILE_CAPACITY

section .bss
		alignb 4
mini___M_global_files: times SMGF_FILE_CAPACITY resb SMGF_SIZEOF_STRUCT_SMS_FILE
mini___M_global_files_end:
mini___M_global_file_bufs: times SMGF_FILE_CAPACITY resb SMGF_BUF_SIZE
section .text  ; Switch back, for inclusion from smart.nasm.

%ifdef CONFIG_PIC
%error Not PIC because it defines global variables.
times 1/0 nop
%endif

; __END__

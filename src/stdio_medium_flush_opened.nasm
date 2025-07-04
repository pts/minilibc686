;
; written by pts@fazkeas.hu at Tue May 23 03:06:53 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o stdio_medium_flush_opened.o stdio_medium_flush_opened.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_start_flush_opened
global mini___M_global_files
global mini___M_global_files_end
global mini___M_global_file_bufs
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=4
mini_fflush_RP3 equ +0x12345678
mini___M_global_files equ +0x12345679
mini___M_global_files_end equ +0x1234567a
mini___M_global_file_bufs equ +0x1234567b
%else
extern mini_fflush_RP3
extern mini___M_global_files
extern mini___M_global_files_end
extern mini___M_global_file_bufs
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%endif

SIZEOF_STRUCT_SMS_FILE equ 0x24   ; It matches struct _SMS_FILE defined in c_stdio_medium.c. sizeof(struct _SMS_FILE).
BUF_SIZE equ 0x1000  ; It matches BUF_SIZE defined in c_stdio_medium.c.
%ifndef CONFIG_FILE_CAPACITY
  %define CONFIG_FILE_CAPACITY 999  ; Large enough for the %ifs below.
%endif
FILE_CAPACITY equ CONFIG_FILE_CAPACITY

section .text
mini___M_start_flush_opened:
; Called from mini_exit(...).
; It flushes all files opened by mini_fopen(...).
; It ruins EAX, EBX, ECX and EDX.
%if FILE_CAPACITY <= 0
%else
%if FILE_CAPACITY == 1
		mov eax, mini___M_global_files
		call mini_fflush_RP3
%elif FILE_CAPACITY == 2
		mov eax, mini___M_global_files
		lea ebx, [byte eax+SIZEOF_STRUCT_SMS_FILE]
		call mini_fflush_RP3
		xchg eax, ebx  ; EAX := EBX; EBX := junk.
		call mini_fflush_RP3
%elif FILE_CAPACITY == 3
		mov eax, mini___M_global_files
		lea ebx, [byte eax+SIZEOF_STRUCT_SMS_FILE]
		call mini_fflush_RP3
		xchg eax, ebx  ; EAX := EBX; EBX := junk.
		lea ebx, [byte eax+SIZEOF_STRUCT_SMS_FILE]
		call mini_fflush_RP3
		xchg eax, ebx  ; EAX := EBX; EBX := junk.
		call mini_fflush_RP3
%else
		mov eax, mini___M_global_files
.next_file:	mov ebx, eax  ; Save for the duration of mini_fflush_RP3 below.
		call mini_fflush_RP3
		lea eax, [byte ebx+SIZEOF_STRUCT_SMS_FILE]
		cmp eax, strict dword mini___M_global_files_end
		jne short .next_file
.after_files:
%endif
%endif
		ret 
%ifidn __OUTPUT_FORMAT__, bin  ; Affects start_stdio_medium_linux.nasm %included()d later: it won't try to redefine these symbols.
  %define mini___M_start_flush_opened mini___M_start_flush_opened
%endif

%ifdef CONFIG_PIC
%error Not PIC because it uses global variables.
times 1/0 nop
%endif

; __END__

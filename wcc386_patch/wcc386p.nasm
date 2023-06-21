;
; wcc386p.nasm: generates the patched wcc386
; by pts@fazekas.hy at Wed Jun 21 22:22:14 CEST 2023
;
; Iput files: wcc386.nasm, wcc386.sym
; Compile: ../tools/nasm-0.98.39 -O0 -w+orphan-labels -f bin -o wcc386.unc wcc386p.nasm && chmod +x wcc386.unc
;

bits 32
cpu 386
org 0

B.code equ -0x8048000
R.code equ $+B.code
B.data equ B.code

; Extracted from the output of: objdump -p wcc386.sym
PHDR0_OFFSET equ 0x100
PHDR0_VADDR equ PHDR0_OFFSET-B.code
PHDR0_FILESZ equ 0xabe97
PHDR0_MEMSZ equ PHDR0_FILESZ

; Extracted from the output of: objdump -p wcc386.sym
PHDR1_OFFSET equ 0xac000
PHDR1_VADDR equ PHDR1_OFFSET-B.code
PHDR1_FILESZ equ 0x5572
PHDR1_MEMSZ equ 0xd964

ENTRY_POINT equ $$+0x809e7de

PT:  ; Symbolic constants for ELF PT_... (program header type).
.LOAD equ 1

OSABI:
.Linux: equ 3

ehdr:					; Elf32_Ehdr
		db 0x7f, 'ELF'		;   e_ident[EI_MAG...]
		db 1			;   e_ident[EI_CLASS]: 32-bit
		db 1			;   e_ident[EI_DATA]: little endian
		db 1			;   e_ident[EI_VERSION]
		db OSABI.Linux		;   e_ident[EI_OSABI]
		db 0			;   e_ident[EI_ABIVERSION]
		db 0, 0, 0, 0, 0, 0, 0	;   e_ident[EI_PAD]
		dw 2			;   e_type == ET_EXEC.
		dw 3			;   e_machine == x86.
		dd 1			;   e_version
		dd ENTRY_POINT		;   e_entry
		dd phdr0-ehdr		;   e_phoff
		dd 0			;   e_shoff
		dd 0			;   e_flags
		dw .size		;   e_ehsize
		dw phdr0.size		;   e_phentsize
		dw (phdr.end-phdr0)/phdr0.size  ;   e_phnum
		dw 0x28			;   e_shentsize
		dw 0			;   e_shnum
		dw 0			;   e_shstrndx
ehdr.size	equ $-ehdr

phdr0:					; Elf32_Phdr
		dd PT.LOAD		;   p_type
		dd 0			;   p_offset
		dd PHDR0_VADDR-PHDR0_OFFSET  ;   p_vaddr
		dd PHDR0_VADDR-PHDR0_OFFSET  ;   p_paddr
		dd +PHDR0_FILESZ+PHDR0_OFFSET  ;   p_filesz
		dd +PHDR0_MEMSZ+PHDR0_OFFSET  ;   p_memsz
		dd 5			;   p_flags: r-x: read and execute, no write
		dd 0x1000		;   p_align
.size		equ $-phdr0
phdr1:					; Elf32_Phdr
		dd PT.LOAD		;   p_type
		dd PHDR1_OFFSET		;   p_offset
		dd PHDR1_VADDR		;   p_vaddr
		dd PHDR1_VADDR		;   p_paddr
		dd +PHDR1_FILESZ	;   p_filesz
		dd +PHDR1_MEMSZ		;   p_memsz
		dd 6			;   p_flags: rw-: read and write, no execute
		dd 0x1000		;   p_align
phdr.end:

%assign CODE_ADDR $-ehdr-B.code

%macro _emit_code_until 1
  %if CODE_ADDR>(%1)-$$
    %error 'Bad code order.'
    times 1/0 nop
  %else
    incbin 'wcc386.sym', CODE_ADDR+B.code, (%1)-$$-CODE_ADDR
    %assign CODE_ADDR (%1)-$$
  %endif
%endmacro

%macro _skip_code 0
  %assign CODE_ADDR ($-$$)-B.code
%endmacro

%macro _skip_code_until 1
  %if (%1)<$-B.code
    %error 'Bad code padding (replacement code too long?).'
    times 1/0 nop
  %elif CODE_ADDR>(%1)-$$
    %error 'Bad code order (replacement code too long?).'
    times 1/0 nop
  %else
    times (%1)-($-B.code) db 0
    %assign CODE_ADDR (%1)-$$
  %endif
%endmacro

%macro _emit_rest 0
  _emit_code_until $$+PHDR0_OFFSET+PHDR0_FILESZ-B.code
  times PHDR1_OFFSET-(PHDR0_OFFSET+PHDR0_FILESZ) db 0
  incbin 'wcc386.sym', PHDR1_OFFSET, PHDR1_FILESZ
%endmacro

ec_switch_used_byte equ $$+0x80fd08a
ec_switch_used_mask equ 8

_emit_code_until $$+0x8048074
;test byte [ec_switch_used_byte], ec_switch_used_mask
;_skip_code_until $$+0x8048074+7
;_skip_code

_emit_rest

;
; start_uclibc_linux.nasm: an uClibc _start function without init/fini initializers
; by pts@fazekas.hu at Sat May  6 11:51:57 CEST 2023
;
; Compile: nasm-0.98.39 -O0 -w+orphan-labels -f elf -o start_uclibc_linux.o start_uclibc_linux.nasm
;

bits 32
cpu 386

global _start
%ifidn __OUTPUT_FORMAT__, bin
main equ +0x12345678
__uClibc_main equ +0x12345679
%else
extern main
extern __uClibc_main  ; In glibc, this would be __libc_start_main.
%endif

; Same as in xlib/crt1.o.
section .text align=1
_init_and_fini:
		ret
_start:
		mov ebp, _init_and_fini  ; Address of the ret.
		pop esi
		mov ecx, esp
		and esp, byte -0x10  ; Stack alignment not mandatory.
		push eax
		push esp
		push edx
		push ebp  ; _fini: Just a ret.
		push ebp  ; _init: Just a ret.
		push ecx
		push esi
		push main
		xor ebp, ebp
		call __uClibc_main  ; It never returns.

%ifdef CONFIG__PIC  ; Double underscore, because we don't want build.sh to build it.
%error Not PIC because of _init_and_fini.
endif

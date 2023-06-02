;
; demo_obj.nasm: demonstrates various object file format features
; by pts@fazekas.hu at Thu Jun  1 12:40:36 CEST 2023
;
; Compile to i386 ELF .o   object: nasm -O0 -w+orphan-labels -f elf -o demo_obj.o demo_obj.nasm
; Compile to i386 OMF .obj object: nasm -O0 -w+orphan-labels -f obj -o demo_obj.obj demo_obj.nasm
;
; The NASM output .o (i386 ELF relocatable object) and .obj (i386 OMF object) files should
; be equivalent to the OpenWatcom (wcc386) output OMF on demo_c_obj.c.
;

bits 32
cpu 386

%ifidn __OUTPUT_FORMAT__, elf
  %define _TEXT  .text
  %define CONST  .rodata.str1.1
  %define CONST2 .rodata
  %define _DATA  .data
  %define _BSS   .bss
  section _TEXT  align=1
  section CONST  align=1
  section CONST2 align=4
  section _DATA  align=4
  section _BSS   align=4
%elifidn __OUTPUT_FORMAT__, obj
  section _TEXT  USE32 class=CODE align=1
  section CONST  USE32 class=DATA align=1  ; OpenWatcom generates align=4.
  section CONST2 USE32 class=DATA align=4
  section _DATA  USE32 class=DATA align=4
  section _BSS   USE32 class=BSS  align=4 NOBITS  ; NOBITS is ignored by NASM, but class=BSS works.
  group DGROUP CONST CONST2 _DATA _BSS
%else
  %error Unsupported NASM output format: __OUTPUT_FORMAT__
  times 1/0 nop
%endif

global _get_exit_code
global main_
global _knock
global _rodata_global
global _data_global
global _bss_global1
global _bss_global2
global _bss_global0
extern _printf
extern _extern_answers
%ifidn __OUTPUT_FORMAT__, obj
; Just ignore, wcc386 adds them if main(...) is present.
; TODO(pts): Add main (__cdecl) which calls main_ (__watcall).
extern __argc
extern _cstart_
%endif

section _TEXT
_get_addressee:	push ebp
		mov ebp, esp
		cmp dword [ebp+8], byte 2
		jge .1
		mov eax, str.3
		pop ebp
		ret
.1:		mov eax, [ebp+0xc]
		mov eax, [eax+4]
		pop ebp
		ret
;
_get_exit_code:	push ebp
		mov ebp, esp
		mov eax, [ebp+8]
		cmp eax, byte 1
		jl .2
		cmp eax, byte 9
		jg .2
		mov eax, 1
		pop ebp
		ret
.2:		xor eax, eax
		pop ebp
		ret
;
; OpenWatcom has generated main_ with __watcall, even when __cdecl is the
; default (wcc386 -ecc).
main_:		push ebx
		push ecx
		mov ebx, eax
		push edx
		push eax
		call _get_addressee
		add esp, byte 8
		push eax
		push str.5
		call _printf
		add esp, byte 8
		push ebx
		call _get_exit_code
		add esp, byte 4
		pop ecx
		pop ebx
		ret

section CONST
str.3:		db 'World', 0
str.4:		db 'rld', 0
str.5:		db 'Hello, %s!', 10, 0

section CONST2
_knock:		db 'Knock?', 0
		; Oddly enough, OpenWatcom doesn't align _rodata_local to a multiple of 4.
_rodata_local:	dd 5, 6
		dd _extern_answers+8
		dd _knock
		dd _bss_global2
		dd _bss_local3
		dd str.3
_rodata_global:	dd 7, 8
		dd _extern_answers+8
		dd _knock
		dd _bss_global2
		dd _bss_local3
		dd _rodata_local+0x10
		dd _data_local+4
		dd _data_global+8
		dd str.3

section _DATA
; NASM doesn't export _data_local (or other non-global symbols) to the .obj file at all, there is no way to ask it.
_data_local:	dd 0xf, 0x10
		dd _extern_answers+0x30
		dd _bss_global2+4
		dd _bss_local3+1
		dd _knock+2
		dd _rodata_local+0x14
		dd str.4
_data_global:	dd 0x11, 0x12
		dd _extern_answers+0x30
		dd _bss_global2+4
		dd _bss_local3+1
		dd _knock+2
		dd _rodata_local+0xc
		dd _data_local+8
		dd str.4

section _BSS
_bss_global1:	resd 3
_bss_global2:	resd 7
_bss_local3:	resb 2
_bss_global0:	resb 1

; NASM adds a .comment section describing the NASM version.

; __END__

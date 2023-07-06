;
; written by pts@fazekas.hu at Sat Jun 10 22:58:58 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o float_fixunsxfdi.o float_fixunsxfdi.nasm
;
; Code size: 0x2e bytes. (libgcc code size is 0xc9 bytes.)
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global __fixunsxfdi
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
__fixunsxfdi:  ; unsigned long long __fixunsxfdi(long double a);
; Part of libgcc, called by GCC 4.6 and earlier. Unfortunately GCC >=4.7
; generates longer, suboptimal code for this.
;
; Converts a long double (80-bit) to an unsigned long long (64-bit). If the
; input is negative or overflows, it returns 0 (just like libgcc, but unlike
; inline code generated by GCC >= 4.7).
%if 1
; In the implementation we take advantage of the stack layout of the __cdecl
; calling convention, and implement this instead (with `a' spanning over
; `a1' and `a2' in memory):
;
; unsigned long long __fixunsxfdi(unsigned long long a1, unsigned short a2) {
;   const unsigned short e = (a2 & 0x7fff) - 0x3fff;
;   if (e > 63 || (a2 & 0x8000)) return 0;
;   return a1 >> (63 - e);
; }
		mov ecx, [esp+0xc]  ; Argument a2.
		xor eax, eax
		test cx, cx  ; a2 & 0x8000.
		js short .zerod  ; Return 0.
		sub cx, 0x3fff + 0x3f
		ja short .zerod  ; Return 0. EAX is still 0.
		neg ecx
		mov eax, [esp+4]  ; Low dword of a1.
		mov edx, [esp+8]  ; High dword of a1.
		; Now shift EDX:EAX right by CL. This is similar to __U8RS.
		test cl, 0x20
		jnz short .big
		shrd eax, edx, cl
		shr edx, cl
		ret
.big:		mov eax, edx
		shr eax, cl
.zerod:		xor edx, edx
%else  ; TODO(pts): Test this. It's 3 bytes shorter.
		lea edx, [esp+4]
		fld tword [edx+0]
		fnstcw word [edx+0+8]
		fnstcw word [edx+0+10]  ; Save.
		mov byte [edx+0+8+1], 0xf
		fldcw word [edx+0+8]
		mov dword [edx+0], 0x5f000000
		fsub dword [edx+0]
		fistp qword [edx+0]
		xor byte [edx+0+7], 0x80  ; Flip sign.
		fldcw word [edx+0+10]  ; Load and use saved.
		mov eax, [edx+0]
		mov edx, [edx+0+4]
%endif
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

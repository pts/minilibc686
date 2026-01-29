;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o longjmp.o longjmp.nasm
;
; Code size: 0c18 bytes.
;
; Limitation: It never restores the signal mask. That's fine, there is siglongjmp(...) (unimplemented) for that.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_longjmp
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%else
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text
mini_longjmp:  ; void longjmp(jmp_buf env, int val) __attribute__((__noreturn__));
		pop eax  ; Pop and ignore return address.
		pop edx  ; Argument env.
		pop eax  ; Argument val (desired return value).
		test eax, eax
		jnz .1
		inc eax  ; Change return value from 0 to 1.
.1:		mov ebx, [edx+0*4]
		mov esi, [edx+1*4]
		mov edi, [edx+2*4]
		mov ebp, [edx+3*4]
		mov esp, [edx+4*4]
		jmp [edx+5*4]  ; Saved EIP.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

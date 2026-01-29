;
; written by pts@fazekas.hu at Tue May 16 18:16:29 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o setjmp.o setjmp.nasm
;
; Code size: 0x18 bytes.
;
; Limitation: It never saves the signal mask. That's fine, there is sigsetjmp(...) (unimplemented) for that.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_setjmp
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
mini_setjmp:  ; int mini_setjmp(jmp_buf env);
		pop ecx  ; Return address, will be saved as EIP.
		pop edx  ; Argument env.
		push edx  ; Push argument env back.
		mov [edx+0*4], ebx
		mov [edx+1*4], esi
		mov [edx+2*4], edi
		mov [edx+3*4], ebp
		mov [edx+4*4], esp  ; ESP now points to argument env.
		mov [edx+5*4], ecx  ; Save EIP (in ECX).
		xor eax, eax  ; Return value := 0.
		jmp ecx  ; `ret', but the retun address is not on the stack anymore.
		; Not reached.

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

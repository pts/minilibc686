;
; Manually optimized for size based on the output of soptcc.pl for c_rand.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o rand.o rand.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_srand
global mini_rand
%ifidn __OUTPUT_FORMAT__, bin
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
mini_srand:
; static unsigned long long seed;
; void mini_srand(unsigned s) { seed = s - 1; }
		mov eax, [esp+0x4]
		dec eax
		push edi
%ifdef CONFIG_PIC
%error Not PIC because of read-write seed.
times 1/0 nop
%endif
		mov edi, seed
		stosd
		xor eax, eax
		stosd
		pop edi
		ret

mini_rand:
		push edi
; static unsigned long long seed;
; int mini_rand(void) {
;   seed = 6364136223846793005ULL * seed + 1;
;   return seed >> 33;
; }
%ifdef CONFIG_PIC
%error Not PIC because of read-write seed.
times 1/0 nop
%endif
		mov edi, seed
		imul dword eax, [edi], 0x5851f42d  ; 32*32-->32 bit multiplication.
		imul dword ecx, [edi+0x4], 0x4c957f2d  ; 32*32-->32 bit multiplication.
		add ecx, eax
		mov eax, 0x4c957f2d
		mul dword [edi]  ; Unsigned 32*32-->64 bit multiplication.
		add eax, byte 1
		adc edx, ecx
		stosd
		xchg eax, edx  ; EAX := EDX; EDX := junk.
		stosd
		shr eax, 1
		pop edi
		ret

section .bss  ; common
alignb 4
seed: resb 8  ; align=4

; __END__

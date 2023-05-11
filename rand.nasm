;
; Manually optimized for size based on the output of soptcc.pl for c_rand.c.
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o c_rand.o c_rand.nasm
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386
B.code equ 0

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
; static unsigned long long seed;
; int mini_rand(void) {
;   seed = 6364136223846793005ULL * seed + 1;
;   return seed >> 33;
; }
%ifdef CONFIG_PIC
%error Not PIC because of read-write seed.
times 1/0 nop
%endif
; TODO(pts): Optimize it like this.
;
; return (U << 32 | L) * B;
;
; return (U:L) * B;
;
; return ((U*B) << 32) + L*B;
;
; PU:PL = U*B;
; return (PU:PL << 32) + L*B;
;
; PU:PL = U*B;
; ignore PU;
; return PL:0 + L*B;
;
; mov eax, U
; mul B
; xchg eax, ecx  ; ECX := PL; EAX := junk.
; mov eax, L
; mul B
; add edx, ecx  ; Result is in EDX:EAX.
		imul dword eax, [seed], 0x5851f42d
		imul dword ecx, [seed+0x4], 0x4c957f2d
		add ecx, eax
		mov eax, 0x4c957f2d
		mul dword [seed]
		add edx, ecx
		add eax, byte 0x1
		adc edx, byte 0x0
		mov [seed], eax
		mov eax, edx
		mov [seed+0x4], edx
		shr eax, 0x1
		ret

section .bss  ; common
alignb 4
seed: resb 8  ; align=4

; __END__

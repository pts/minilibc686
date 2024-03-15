;
; written by pts@fazekas.hu at Fri Mar 15 03:38:43 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o qsort_stable_fast_shortcut.o qsort_stable_fast_shortcut.nasm
;
; Code size: 0x58 bytes for i686, 0x59 bytes for i386.
;
; Based on ip_merge (C, simplest) at https://stackoverflow.com/a/22839426/97248
; Based on ip_merge in test/test_qstort_stable_mini.c.
; Does the same number of comparisons and swaps as test/test_qstort_stable_analyze.c.
;
; Uses: %ifdef CONFIG_PIC
; Uses: %ifdef CONFIG_I386
;

bits 32
%ifdef CONFIG_I386
cpu 386
%else
cpu 686
%endif

global mini_qsort_stable_fast_shortcut
%ifdef CONFIG_SECTIONS_DEFINED
%elifidn __OUTPUT_FORMAT__, bin
section .text align=1
section .rodata align=4
section .data align=4
section .bss align=4
mini___M_inplace_merge_RX equ +0x12345678
mini___M_cmp_RX equ +0x12345679
%else
extern mini___M_inplace_merge_RX
extern mini___M_cmp_RX
section .text align=1
section .rodata align=1
section .data align=1
section .bss align=1
%endif

section .text

; /* Constant state for ip_merge and ip_mergesort. */
; struct ip_cs {  /* Same memory layout as the qsort arguments on the stack. */
;   const void *base;
;   size_t unused_n;
;   size_t item_size;
;   int CMPDECL (*cmp)(const void*, const void*);
; };

mini_qsort_stable_fast_shortcut:  ; void mini_qsort_stable_fast_shortcut(void *base, size_t n, size_t size, int (*cmp)(const void*, const void*));
; In-place stable sort using in-place mergesort.
; Same signature and semantics as qsort(3).
;
; If you don't need a stable sort, try qsort_fast(...) instead, because
; that does fewer comparisons. (That may do a bit more swaps though.)
;
; If you want to use much less stack space, or you need a shorter qsort(3)
; implementation, try qsort_fast(...) instead. Please note that that is not
; stable, and that may do a bit more swaps.
;
; The formulas below are mathematically correct, without rounding.
;
; Number of item swaps:
;
; * O(n*log(n)*log(n)).
; * If n <= 1, then 0.
; * If n == 2, then at most 1.
; * If n >= 2, then less than 0.75 * n * log2(n) * log2(n).
; * If the input is already sorted, then 0.
; * If large chunks of the input is already shorted, then less.
;
; Number of comparisons:
;
; * O(n*log(n)*log(n)), but typically much less.
; * If n <= 1, then 0.
; * If n == 2, then at most 1.
; * If n >= 2, then less than 0.5308 * n * log2(n) * log2(n).
; * If 2 <= n <= 2**32, then less than 1.9844 * n * log2(n).
; * If 2 <= n <= 2**64, then less than 2.0078 * n * log2(n).
; * If 2 <= n <= 2**128, then less than 2.0193 * n * log2(n).
; * If 2 <= n <= 2**256, then less than 2.0251 * n * log2(n).
; * If 2 <= n <= 2**512, then less than 2.0279 * n * log2(n).
; * If the input is already sorted, and n >= 1, then n-1.
;
; Uses O(log(n)) stack memory, mostly recursive calls to
; mini___M_inplace_merge_RX(...). More exactly, this function uses at most
; 1348 (mini___M_inplace_merge_RX) + 4 (return address) + 4*4 (arguments) +
; 32 (pushad) == 1400 bytes of stack.
;
;
; void mini_qsort_stable_fast_shortcut(void *base, size_t n, size_t item_size, int CMPDECL (*cmp)(const void *, const void *)) {
;   size_t a, b, d;
;   struct ip_cs cs;
;   cs.base = base; cs.item_size = item_size; cs.cmp = cmp;
;   for (d = 1; d != 0 && d < n; d <<= 1) {  /* We check `d != 0' to detect overflow in the previous: `d <<= 1'. */
;     for (a = 0; a < n - d; a = b) {
;       b = a + (d << 1);
;       /* Shortcut if [a,c) is already sorted. */
;       if (d > 1 && mini___M_cmp_RX(&cs, a + d - 1, a + d) <= 0) continue;
;       mini___M_inplace_merge_RX(&cs, a, a + d,  b > n ? n : b);
;     }
;   }
; }
;
		; !! TODO(pts): Remove code duplication with src/qsort_stable_fast.nasm.
		; Register allocation: ESI: cs; EAX: a; EBX: b and various temporaries; ECX: n; EDX: d.
		push esi  ; Save.
		push ebx  ; Save.
		lea esi, [esp+12]  ; cs.
		mov ecx, [esi+4]  ; ECX := n.
		xor edx, edx
		inc edx
.next:		test edx, edx
		jz short .done
		cmp edx, ecx
		jae short .done
		xor eax, eax
.nextin:	mov ebx, ecx
		sub ebx, edx
		cmp eax, ebx  ; a < n - d.
		jnb short .donein
		mov ebx, edx
		add ebx, ebx
		add ebx, eax  ; b = a + (d << 1);
		; Now: Shortcut if [a,c) is already sorted. if (d > 1 && mini___M_cmp_RX(&cs, a + d - 1, a + d) <= 0) continue;
		cmp edx, byte 1
		jbe short .noshortcut
		push eax  ; Save.
		push edx  ; Save.
		push ebx  ; Save.
		add edx, eax
		mov ebx, edx  ; a + d.
		dec edx  ; a + d - 1.
		call mini___M_cmp_RX  ; mini___M_cmp_RX(&cs, a + d - 1, a + d).
		cmp eax, byte 0
		pop ebx  ; Restore.
		pop edx  ; Restore.
		pop eax  ; Restore.
		jle short .contin
.noshortcut:	pushad  ; Save.
		cmp ebx, ecx
%ifdef CONFIG_I386
		ja .usen
		mov ecx, ebx
.usen:
%else
		cmovna ecx, ebx
%endif
		mov ebx, eax
		add ebx, edx
		call mini___M_inplace_merge_RX  ; mini___M_inplace_merge_RX(&cs, a, a + d,  b > n ? n : b);
		popad  ; mini___M_inplace_merge_RX has ruined all registers.
.contin:	xchg eax, ebx   ; a := b, b := junk.
		jmp short .nextin
.donein:	add edx, edx
		jmp short .next
.done:		pop ebx  ; Restore.
		pop esi  ; Restore.
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

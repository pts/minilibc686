;
; written by pts@fazekas.hu at Fri Mar 15 03:38:43 CET 2024
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o inplace_merge_impl.o inplace_merge_impl.nasm
;
; Code size: 0x122 bytes, 0x160 bytes including src/qsort_stable_fast.nasm.
;
; Based on ip_merge (C, simplest) at https://stackoverflow.com/a/22839426/97248
; Based on ip_merge in test/test_qstort_stable_mini.c.
; Does the same number of comparisons and swaps as test/test_qstort_stable_analyze.c.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini___M_inplace_merge_RX
global mini___M_cmp_RX
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

; /* Constant state for ip_merge and ip_mergesort. */
; struct ip_cs {  /* Same memory layout as the qsort arguments on the stack. */
;   const void *base;
;   size_t unused_n;
;   size_t item_size;
;   int CMPDECL (*cmp)(const void*, const void*);
; };

ip_reverse:  ; void ip_reverse(const struct ip_cs *cs, size_t a, size_t b);
; 0 comparisons, (b-a)//2 swaps.
;
; Precondition: a < b.
;
; It is quite slow, because it moves 1 byte a time (rather than 4 or 8).
;
; It's not OK to a bytewise reverse, because this function is also used for
; item swapping.
;
; # pragma aux ip_reverse  __parm __caller [__esi] [__edx] [__ebx] __value __struct __caller [] [__eax] __modify []
; void ip_reverse(const struct ip_cs *cs, size_t a, size_t b) {
;    const size_t item_size = cs->item_size;
;    char *cbase = (char*)cs->base;
;    char *ca = cbase + item_size * a, *cb = cbase + item_size * b, *ca_end;
;    char t;
;    size_t cabd;
;    while (0 < (ssize_t)(cabd = (cb -= item_size) - ca)) {  /* cabd cast to ssize_t can overflow here. We'll fix it in assembly. */
;      /* ip_swap(cs, a, b); */  /* 0 comparisons, 1 (item) swap. */
;      for (ca_end = ca + item_size; ca != ca_end; ++ca) {
;        t = *ca;
;        *ca = ca[cabd];
;        ca[cabd] = t;
;      }
;    }
;  }
		pushad
		mov eax, [esi]  ; EAX := cs->base. (cbase)
		mov esi, [esi+8]  ; ESI := cs->item_size (item_size).
		imul ebx, esi  ; EBX := item_size * b.
		add ebx, eax  ; EBX := cbase + item_size * b. (cb)
		imul edx, esi  ; EBD := item_size * a.
		add edx, eax  ; EDX := cbase + item_size * a. (ca)
.next:		sub ebx, esi  ; EBX -= item_size. (cb)
		mov ecx, ebx
		sub ecx, edx  ; ECX := cb - ca. (cabd)
		jna short .done
		mov edi, edx
		add edi, esi  ; EDI := ca + item_size. (ca_end).
.nextin:	cmp edx, edi
		je short .next
		mov al, [edx]
		xchg [edx+ecx], al
		mov [edx], al  ; TODO(pts): stosb if EDI and EDX are swapped.
		inc edx
		jmp short .nextin
.done:		popad
		ret

mini___M_cmp_RX:  ; int mini___M_cmp_RX(const struct ip_cs *cs, size_t a, size_t b);
; Calls cs->cmp with the right arguments.
;
; #pragma aux mini___M_cmp_RX  __parm __caller [__esi] [__edx] [__ebx] __value __struct __caller [] [__eax] __modify [__edx __ebx]
; int mini___M_cmp_RX(const struct ip_cs *cs, size_t a, size_t b) {
;   return cs->cmp((char*)cs->base + cs->item_size * a, (char*)cs->base + cs->item_size * b);
; }
		; Register allocation: ESI: cs; EDX: a, EBX: b.
		push ecx  ; Save.
		; TODO(pts): Size-optimize this function.
		mov ecx, [esi+8]  ; ECX := cs->item_size.
		imul ebx, ecx  ; EBX := b * cs->item_size.
		add ebx, [esi]  ; EBX += cs->base.
		push ebx  ; Push arg2.
		imul edx, ecx  ; EDX := a * cs->item_size.
		add edx, [esi]  ; EDX += cs->base.
		push edx  ; Push arg1.
		call [esi+12]  ; Call cs->cmp. May ruin EDX and ECX. Return value in ESI.
		pop ecx  ; Clean up arg1 from stack.
		pop ecx  ; Clean up arg2 from stack.
		pop ecx  ; Restore.
		ret

mini___M_inplace_merge_RX:  ; void mini___M_inplace_merge(const struct ip_cs *cs, size_t a, size_t b, size_t c);
; In-place merge of [a,b) and [b,c) to [a,c) within base.
;
; Precondition: a <= b && b <= c.
;
; See also function ip_merge in test/test_qsort_stable_mini.c.
;
; This is a recursive function, but it uses very little stack space: only 16
; bytes per recursion level. Maximum recursion depth is less than
; log(c-a)/log(4/3)+1.
;
; Since c-a < 2**32 on 32-bit systems such as i386, maximum recursion depth
; is less than log(2**32)/(4/3)+1, so it is at most 78. Thus maximum stack
; size used for recursion is 78*16 == 1248 bytes. Add about 100 bytes for
; saves and other function calls (e.g. ip_reverse and mini___M_cmp_RX), so
; this function uses at most 1348 bytes of stack space.
;
; #pragma aux mini___M_inplace_merge_RX  __parm __caller [__esi] [__eax] [__ebx] [__ecx] __value __struct __caller [] [__eax] __modify [__eax __edx __ebx __ecx __eax __esi __edi]
; void mini___M_inplace_merge_RX(const struct ip_cs *cs, size_t a, size_t b, size_t c) {
;   size_t p, q, i;
;   if (a == b || b == c) return;
;   if (c - a == 2) {
;     if (mini___M_cmp_RX(cs, b, a) < 0) {  /* 1 comparison. */
;       ip_reverse(cs, a, c);  /* Same as: ip_swap(cs, a, b); */  /* 1 swap. */
;     }
;     return;
;   }
;   /* Finds first element not less (for is_lower) or greater (for !is_lower)
;    * than key in sorted sequence [low,high) or end of sequence (high) if not found.
;    * ceil(log2(high-low+1)) comparisons, which is == ceil(log2(min(b-a,c-b)+1)) <= ceil(log2((c-a)//2+1)).
;    */
;   if (b - a > c - b /* is_lower */) {
;     /* key = */ p = a + ((b - a) >> 1); /* low = */ q = b; /* high = c; */ i = c - b;
;     for (/* i = high - low */; i != 0; i >>= 1) {  /* low = ip_bound(cs, low, high, key, is_lower); */
;       /* mid = low + (i >> 1); */
;       if (mini___M_cmp_RX(cs, p, q + (i >> 1)) >= 1) {
;         q += (i >> 1) + 1;
;         i--;
;       }
;     }
;   } else {
;     /* key = */ q = b + ((c - b) >> 1); /* low = */ p = a; /* high = b; */ i = b - a;
;     for (/* i = high - low */; i != 0; i >>= 1) {  /* low = ip_bound(cs, low, high, key, is_lower); */
;       /* mid = low + (i >> 1); */
;       if (mini___M_cmp_RX(cs, q, p + (i >> 1)) >= 0) {
;         p += (i >> 1) + 1;
;         i--;
;       }
;     }
;   }
;   if (p != b && b != q) {  /* swap adjacent sequences [p,b) and [b,q). */
;     ip_reverse(cs, p, b);
;     ip_reverse(cs, b, q);
;     ip_reverse(cs, p, q);
;   }
;   b = p + (q - b);  /* Sets b_new. */
;   ip_merge(cs, a, p, b);
;   ip_merge(cs, b, q, c);
; }
;
		; Register allocation: ESI: cs; EAX: a; EBX: b; ECX: c; EDX: i (after .afterbound: q); EDI: p; EBP: q.
.re:		cmp eax, ebx
		jne short .c1
.ret:		ret
.c1:		cmp ebx, ecx
		je short .ret
		mov edi, ecx
		sub edi, eax
		cmp edi, byte 2
		jne short .c2
		push eax  ; Save a.
		xchg edx, eax  ; EDX := EAX; EAX := junk.
		call mini___M_cmp_RX  ; mini___M_cmp_RX(cs, a, b);
		cmp eax, byte 0
		pop edx  ; EDX := EAX (a).
		jle short .ret
		mov ebx, ecx
		call ip_reverse  ; ip_reverse(cs, a, c);
		jmp short .ret

.c2:		push ebp  ; Save. (OpenWatcom doesn't allow __modify [__ebp].)
		push eax  ; Save a.
		mov edx, ebx
		sub edx, eax
		mov edi, ecx
		sub edi, ebx
		cmp edx, edi
		jna short .upper  ; if (b - a > c - b /-* is_lower *-/)

		mov edi, ebx
		sub edi, eax
		shr edi, 1
		add edi, eax  ; p = a + ((b - a) >> 1);
		mov ebp, ebx  ; q = b;
		mov edx, ecx
		sub edx, ebx  ; i = c - b;
.lowernext:	test edx, edx
		jz short .afterbound
		push edx  ; Save.
		push ebx  ; Save.
		mov ebx, edx
		shr ebx, 1
		add ebx, ebp
		mov edx, edi
		call mini___M_cmp_RX  ; mini___M_cmp_RX(cs, p, q + (i >> 1));
		pop ebx  ; Restore.
		pop edx  ; Restore.
		cmp eax, byte 1
		jl short .lowercont
		mov eax, edx
		shr eax, byte 1
		inc eax
		add ebp, eax  ; q += (i >> 1) + 1;
		dec edx  ; i--;
.lowercont:	shr edx, 1
		jmp short .lowernext
.ree:		jmp short .re  ; Just a trampoline for .re, to save a byte of code.

.upper:		mov ebp, ecx
		sub ebp, ebx
		shr ebp, 1
		add ebp, ebx  ; q = b + ((c - b) >> 1);
		mov edi, eax  ; p = a;
		mov edx, ebx
		sub edx, eax  ; i = b - a;
.uppernext:	test edx, edx
		jz short .afterbound
		push edx  ; Save.
		push ebx  ; Save.
		mov ebx, edx
		shr ebx, 1
		add ebx, edi
		mov edx, ebp
		call mini___M_cmp_RX  ; mini___M_cmp_RX(cs, q, p + (i >> 1));
		pop ebx  ; Restore.
		pop edx  ; Restore.
		cmp eax, byte 0
		jl short .uppercont
		mov eax, edx
		shr eax, 1
		inc eax
		add edi, eax  ; p += (i >> 1) + 1;
		dec edx  ; i--;
.uppercont:	shr edx, 1
		jmp short .uppernext

.afterbound:	pop eax  ; Restore a.
		mov edx, ebp  ; EDX := q.
		pop ebp  ; Restore.
		cmp edi, ebx
		je short .rec
		cmp ebx, edx
		je short .rec
		push edx  ; Save.
		push ebx  ; Save.
		push edx
		mov edx, edi
		call ip_reverse  ; ip_reverse(cs, p, b);
		pop edx
		xchg edx, ebx
		call ip_reverse  ; ip_reverse(cs, b, q);
		mov edx, edi
		call ip_reverse  ; ip_reverse(cs, p, q);
		pop ebx  ; Restore.
		pop edx  ; Restore.

.rec:		neg ebx
		add ebx, edi
		add ebx, edx
		push ebx  ; Pushed for the 2nd ip_merge call below.
		push edx  ; Pushed for the 2nd ip_merge call below.
		push ecx  ; Pushed for the 2nd ip_merge call below.
		mov ecx, ebx
		mov ebx, edi
		call mini___M_inplace_merge_RX  ; mini___M_inplace_merge_RX(cs, a, p, b);  !! TODO(pts): Make this a jump, use a sentinel 0 to figure out when to end. Thus use 4 bytes less stack space per level.
		pop ecx
		pop ebx
		pop eax
		jmp short .ree  ; mini___M_inplace_merge_RX(cs, b, q, c);

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

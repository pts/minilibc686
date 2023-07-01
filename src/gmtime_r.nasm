;
; written by pts@fazekas.hu at Thu Jun 22 17:23:12 CEST 2023
; Compile to i386 ELF .o object: nasm -O999999999 -w+orphan-labels -f elf -o gmtime_r.o gmtime_r.nasm
;
; Code size: 0xa3 bytes.
;
; Uses: %ifdef CONFIG_PIC
;

bits 32
cpu 386

global mini_gmtime_r
global mini_localtime_r
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

; struct tm {...}. Each field is a signed 32-bit integer.
TM_sec   equ 0*4  ; Seconds.	[0-60]  (1 leap second =60, mini_gmtime(...) never generates it)
TM_min   equ 1*4  ; Minutes.	[0-59]
TM_hour  equ 2*4  ; Hours.	[0-23]
TM_mday  equ 3*4  ; Day.	[1-31]
TM_mon   equ 4*4  ; Month.	[0-11]
TM_year  equ 5*4  ; Year - 1900.
TM_wday  equ 6*4  ; Day of week. [0-6, Sunday==0]
TM_yday  equ 7*4  ; Days in year. [0-365]
TM_isdst equ 8*4  ; DST.	[-1/0/1]

section .text
mini_gmtime_r:  ; struct tm *mini_gmtime_r(const time_t *timep, struct tm *tm);
mini_localtime_r:  ; struct tm *mini_localtime_r(const time_t *timep, struct tm *tm);  /* No concept of time zones, everything is GMT. */
; /* We assume that time_t is int32_t. If that breaks, not only the int
;  * sizes change, but also the algorithm, because the `t' becomes incorrect
;  * in `yday = t - ...'.
;  */
		push ebp
		mov eax, [esp+2*4]
		mov eax, [eax]
		mov ebp, [esp+3*4]  ; Argument `tm'.
		mov ecx, 86400
		cdq  ; Sign-extend EAX to EDX:EAX.
		idiv ecx
		test edx, edx
		jns .sign_fixed
		dec eax
		add edx, ecx  ; Make sure `idiv' rounds down. Needed for i386+.
.sign_fixed:	push eax
		; Now: -24856 <= EAX (t) <= 24855.
		xchg eax, edx  ; EAX (hms) := EDX; EDX := junk.
		; Now: 0 <= hms <= 86399.
		cdq
		xor ecx, ecx
		mov [ebp+TM_isdst], ecx  ; tm->tm_isdst = 0;
		mov cl, 60
		div ecx
		mov [ebp+TM_sec], edx
		xor edx, edx
		div ecx
		mov [ebp+TM_min], edx
		mov [ebp+TM_hour], eax
		pop eax  ; EAX (t) := ts / 86400.
		push eax
		; Now: -24856 <= t <= 24855.
		add eax, 24861
		; Now: 5 <= EAX <= 49726.
		cdq
		mov cl, 7
		div ecx
		mov [ebp+TM_wday], edx

		pop eax  ; EAX (t) := ts / 86400.
		push eax
		lea eax, [eax*4+102035]
		cdq
		mov cx, 1461  ; Higher bits of ECX are already 0.
		div ecx  ; EAX (c) := (t * 4 + 102035) / 1461; EDX := junk.
		; Now: 1 <= c <= 137.
		xchg eax, edx  ; EDX (c) := EAX; EAX := junk.
		pop eax  ; EAX (t) := ts / 86400.
		push edx  ; Save c.
		add eax, 25568
		mov ecx, edx
		shr ecx, 2
		sub eax, ecx
		imul edx, edx, dword 365
		; Now: 364 <= EDX <= 50005.
		sub eax, edx  ; EAX (yday) := t - 365 * c - (c >> 2) + 25568.
		; Now: 0 <= yday <= 425.
		push eax  ; Save yday.
		lea eax, [eax+eax*4+8]  ; EAX (a) := yday * 5 + 8.
		; Now: 8 <= EAX (a) <= 2133.
		cdq
		mov cx, 153  ; Highest 16 bits of ECX were already 0.
		div ecx
		push eax  ; tm->tm_mon = a / 153;  Save tm->tm_mon to the stack, will be restored to EAX.
		; Now: 2 <= EAX (tm->tm_mon) <= 13.
		xchg eax, edx  ; EAX (a) := a % 153; EDX := junk.
		; Now: 0 <= EAX (a) <= 152.
		cdq
		mov cl, 5  ; Highest 24 bits of ECX were already 0.
		div ecx
		inc eax
		mov [ebp+TM_mday], eax  ; tm->tm_mday = 1 + a / 5;

		; Now: 1 <= tm->tm_mday <= 31.
		pop eax  ; EAX ;= tm->tm_mon.
		pop ecx  ; ECX := yday.
		pop edx  ; EDX := c.

		cmp al, 12
		jb .month_else  ; if (tm->tm_mon >= 12) {
		sub al, 12  ; tm->tm_mon -= 12;
		; Now: 0 <= EAX (tm->tm_mon) <= 1.
		inc edx  ; ++c;
		; Now 366 <= EAX (yday) <= 366 + 59 == 425.
		sub cx, 366  ; EAX (yday) -= 366. Highest 16 bits of EAX are already 0.
		jmp short .month_fi  ; } else {
.month_else:	; Now: 2 <= EAX (tm->tm_mon) <= 11.
		test dl, 3  ; if ((c & 3) != 0) ...
		jz .month_fi
		dec ecx  ; --yday;
.month_fi:	mov [ebp+TM_mon], eax
		mov [ebp+TM_year], edx  ; tm->tm_year = c;
		; Now: 1901 <= tm->tm_year <= 2038.
		; Now: 0 <= tm->tm_mon <= 11.
		; Now: 0 <= yday <= 365.
		mov [ebp+TM_yday], ecx  ; tm->tm_yday = yday;
		xchg eax, ebp  ; EAX := argument `tm' (return value); EBP := junk.
		pop ebp
		ret

%ifdef CONFIG_PIC  ; Already position-independent code.
%endif

; __END__

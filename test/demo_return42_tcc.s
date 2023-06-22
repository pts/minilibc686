.text
.global main
jmp main
mov 0x55(%eax), %al
main:
mov $42, %eax
ret
jmp main


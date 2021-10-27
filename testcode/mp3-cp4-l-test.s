.align 4
.section .text
.globl _start
_start:


load_byte:

lb x2,0(A)
lb x3,1(A)
lb x4,2(A)
lb x5,3(A)
lb x6,-1(B)
lb x7,-2(B)
lb x8,-3(B)
lb x9,-4(B)

load_hword:
lh x10,0(A)
lh x11,1(A)
lh x2,-1(B)
lh x13,-2(B)





.section .rodata

A:               .word 0xABCDEFAB
B:               .word 0x11111111

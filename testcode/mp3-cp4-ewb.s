#  mp3-cp3.s version 1.2
.align 4
.section .text
.globl _start
_start:

# Mispredict taken branch flushing tests
    la x9, DataSeg
    add x10, x0, x0
    lw x11, LENGTH

write_loop:
    sw x10, 0(x9)
    add x9, x9, 1024
    add x10, x10, 1
    bne x10, x11, write_loop

    la x9, DataSeg
    add x10, x0, x0
    lw x11, LENGTH

read_loop:
    lw x1, 0(x9)
    bne x1, x10, 
    add x9, x9, 1024
    add x10, x10, 1
    bne x10, x11, read_loop

    lw x7, GOOD

halt:
    beq x0, x0, halt

bad:
    lw x1, BAD
    beq x0, x0, halt

.section .rodata
.balign 256
BAD:    .word 0x00BADBAD
GOOD:   .word 0x600D600D
LENGTH: .word 0x00000008
    nop
    nop
    nop
    nop
    nop

# cache line boundary
DataSeg:


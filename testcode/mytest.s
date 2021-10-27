mytest.s:
.align 4
.section .text
.globl _start

_start:
    # lw  x1, input1
    # lw  x2, input2
    # sw  x1, 0x0000080(x2)
    # slti x3, x1, 0x001
    # sltiu x4, x1, 0x001
    # sltu x5, x1, x2
    # slt x6, x1, x2

    # lw  x1, input3
    # lw  x2, input4
    # xor x3, x1, x2
    # xor x1, x1, x1
    # xor x2, x2, x2

    # lw  x1, input1
    # sw  x1, 0x0000090(x0)
    # lh  x2, 0x0000090(x0)
    # lhu x3, 0x0000090(x0)
    # lb  x4, 0x0000090(x0)
    # lbu x5, 0x0000090(x0)

    # lw  x1, input1
    # sh  x1, 0x0000090(x0)
    # sb  x1, 0x0000094(x0)

    # lw  x1, input1
    # lw  x6, input2
    # sw  x1, 0x0000100(x6)
    # sh  x1, 0x0000104(x6)
    # sh  x1, 0x0000106(x6)
    # sb  x1, 0x0000108(x6)
    # sb  x1, 0x0000109(x6)
    # sb  x1, 0x000010A(x6)
    # sb  x1, 0x000010B(x6)

    # lh  x2, 0x0000100(x6)
    # lh  x3, 0x0000102(x6)
    # lhu x4, 0x0000100(x6)
    # lhu x5, 0x0000102(x6)
    # lb  x2, 0x0000100(x6)
    # lb  x3, 0x0000101(x6)
    # lb  x4, 0x0000102(x6)
    # lb  x5, 0x0000103(x6)
    # lbu x2, 0x0000100(x6)
    # lbu x3, 0x0000101(x6)
    # lbu x4, 0x0000102(x6)
    # lbu x5, 0x0000103(x6)

    # lw  x1, input3
    # lw  x2, input4
    # lw  x3, input5
    # lw  x4, input6
    
    # TEST W/ CACHE
    # lw  x1, input1
    # lw  x2, input2
    # lw  x3, input3
    # lw  x4, input4
    # lw  x5, input5
    # lw  x6, input6

    la  x7, input1
    lh  x1, 0(x7)
    lh  x2, 0x02(x7)
    lb  x4, 0(x7)
    lb  x5, 1(x7)
    lb  x6, 2(x7)
    lb  x7, 3(x7)

    # la  x7, input1
    # lb  x1, 0x02(x7)
    # la  x7, input2
    # lb  x2, 0x02(x7)
    # la  x7, input3
    # lb  x3, 0x02(x7)
    # la  x7, input4
    # lb  x4, 0x02(x7)
    # la  x7, input5
    # lb  x5, 0x02(x7)
    # la  x7, input6
    # lb  x6, 0x02(x7)

    # la  x7, input0
    # lb  x1, 0x03(x7)
    # la  x7, input1          # storing ECE411AA
    # sb  x1, 0x03(x7)
    # la  x7, input2
    # sb  x1, 0x03(x7)
    # la  x7, input3
    # sb  x1, 0x03(x7)
    # la  x7, input4
    # sb  x1, 0x03(x7)
    # la  x7, input5
    # sb  x1, 0x03(x7)
    # la  x7, input6
    # sb  x1, 0x03(x7)
    # lw  x2, input1
    # lw  x3, input2
    # lw  x4, input3
    # lw  x5, input4
    # lw  x6, input5
    # lw  x7, input6

halt:                 # Infinite loop to keep the processor
    beq x0, x0, halt  # from trying to execute the data below.
                      # Your own programs should also make use
                      # of an infinite loop at the end.

.section .rodata
input0:     .word 0xECE411AA
.align 8
input1:     .word 0xF082818F
.align 8
input2:     .word 0x12345678
.align 8
input3:     .word 0x600D600D
.align 8
input4:     .word 0x00ECE411
.align 8
input5:     .word 0xF818280F
.align 8
input6:     .word 0xABCDEF01
output:     .word 0xBAD0BAD0

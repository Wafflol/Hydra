# Basic RV32I smoke test for the pipeline (no hazard handling yet).
# Dependent instructions are at least 3 apart (2 instructions or NOPs
# in between), and every branch/jump is followed by 2 NOPs.
# Expected final register values are listed on the right.

    .globl _start
_start:
    addi  x1, x0, 5         # x1  = 5
    addi  x2, x0, 7         # x2  = 7
    nop
    nop
    add   x3, x1, x2        # x3  = 12
    sub   x4, x2, x1        # x4  = 2
    lui   x5, 0x12345       # x5  = 0x12345000
    nop
    nop
    sw    x3, 16(x0)        # mem[16] = 12
    auipc x6, 0             # x6  = PC of this instruction (0x28)
    addi  x7, x0, -1        # x7  = -1
    lw    x8, 16(x0)        # x8  = 12
    nop
    slt   x9, x7, x0        # x9  = 1   (-1 < 0 signed)
    sltu  x10, x7, x1       # x10 = 0   (0xFFFFFFFF > 5 unsigned)
    nop
    beq   x1, x1, skip      # taken
    nop
    nop
    addi  x11, x0, 99       # x11 = 0   (skipped)
skip:
    jal   x12, target       # x12 = return address (0x58)
    nop
    nop
    addi  x13, x0, 99       # x13 = 0   (skipped)
target:
    addi  x14, x0, 42       # x14 = 42
    nop
    nop
    nop
    nop
done:
    j     done              # loop forever
    nop
    nop

#define MMULT32_OP   (0x4000500b)
#define RD_A0        (0x00000500)
#define RD_A1        (0x00000580)
#define RD_A2        (0x00000600)
#define RS1_A4       (0x00070000)
#define RS1_A5       (0x00078000)
#define RS1_A6       (0x00080000)
#define RS1_A7       (0x00088000)
#define RS1_T0       (0x00028000)
#define RS1_T1       (0x00030000)
#define RS1_T2       (0x00038000)
#define RS1_T3       (0x000e0000)
#define RS1_T4       (0x000e8000)
#define RS2_ZERO     (0x00000000)
#define RS2_A0       (0x00a00000)
#define RS2_A1       (0x00b00000)
#define RS2_A2       (0x00c00000)
#define MMULT_PARAM0 (0x00000000)
#define MMULT_PARAM1 (0x02000000)
#define MMULT_PARAM2 (0x04000000)
#define MMULT_PARAM3 (0x06000000)
#define MMULT_PARAM4 (0x08000000)
#define MMULT_PARAM5 (0x0a000000)
#define MMULT_PARAM6 (0x0c000000)
#define MMULT_PARAM7 (0x0e000000)
#define MMULT_PARAM8 (0x10000000)


.global mmult27x32
mmult27x32:
    lw      a4,0(a0)
    lw      a5,4(a0)
    lw      a6,8(a0)
    lw      a7,0(a1)
    lw      t0,4(a1)
    lw      t1,8(a1)
    lw      t2,0(a2)
    lw      t3,4(a2)
    lw      t4,8(a2)
loop_mmult27x2:
    .word MMULT32_OP|MMULT_PARAM0|RD_A0|RS1_A4|RS2_ZERO
    .word MMULT32_OP|MMULT_PARAM1|RD_A1|RS1_A5|RS2_ZERO
    addi    a4,a4,1
    .word MMULT32_OP|MMULT_PARAM2|RD_A2|RS1_A6|RS2_ZERO
    .word MMULT32_OP|MMULT_PARAM3|RD_A0|RS1_A7|RS2_A0
    addi    a5,a5,1
    .word MMULT32_OP|MMULT_PARAM4|RD_A1|RS1_T0|RS2_A1
    .word MMULT32_OP|MMULT_PARAM5|RD_A2|RS1_T1|RS2_A2
    addi    a6,a6,1
    .word MMULT32_OP|MMULT_PARAM6|RD_A0|RS1_T2|RS2_A0
    .word MMULT32_OP|MMULT_PARAM7|RD_A1|RS1_T3|RS2_A1
    addi    a7,a7,1
    .word MMULT32_OP|MMULT_PARAM8|RD_A2|RS1_T4|RS2_A2
    addi    t0,t0,1
    add     a0,a1,a0
    add     a0,a2,a0
    addi    t1,t1,1
    addi    t2,t2,1
    addi    t3,t3,1
    addi    t4,t4,1
    sw      a0,0(a3)
    addi    a3,a3,4
    andi    a0,a4,15
    bne     a0,zero,loop_mmult27x2

    ret

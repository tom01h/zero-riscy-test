#define BNN_ACC8_OP  (0x4000500b)
#define RD_A0        (0x00000500)
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
#define BNN_PARAM0   (0x00000000)
#define BNN_PARAM1   (0x02000000)
#define BNN_PARAM2   (0x04000000)
#define BNN_PARAM3   (0x06000000)
#define BNN_PARAM4   (0x08000000)
#define BNN_PARAM5   (0x0a000000)
#define BNN_PARAM6   (0x0c000000)
#define BNN_PARAM7   (0x0e000000)
#define BNN_PARAM8   (0x10000000)


.global bnn_acc8
bnn_acc8:
    lw      a4,0(a0)
    lw      a5,4(a0)
    lw      a6,8(a0)
    lw      a7,0(a1)
    lw      t0,4(a1)
    lw      t1,8(a1)
    lw      t2,0(a2)
    lw      t3,4(a2)
    lw      t4,8(a2)
loop_acc8:
    .word BNN_ACC8_OP|BNN_PARAM0|RD_A0|RS1_A4|RS2_ZERO
    .word BNN_ACC8_OP|BNN_PARAM1|RD_A0|RS1_A5|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM2|RD_A0|RS1_A6|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM3|RD_A0|RS1_A7|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM4|RD_A0|RS1_T0|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM5|RD_A0|RS1_T1|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM6|RD_A0|RS1_T2|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM7|RD_A0|RS1_T3|RS2_A0
    .word BNN_ACC8_OP|BNN_PARAM8|RD_A0|RS1_T4|RS2_A0
    addi    a4,a4,1
    addi    a5,a5,1
    addi    a6,a6,1
    addi    a7,a7,1
    addi    t0,t0,1
    addi    t1,t1,1
    addi    t2,t2,1
    addi    t3,t3,1
    addi    t4,t4,1
	sw      a0,0(a3)
    addi    a3,a3,4
	andi    a0,a4,255
	li      a1,16
	blt     a0,a1,loop_acc8

    ret

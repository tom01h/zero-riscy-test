#define BNN_ACC8_OP  (0x4000500b)
#define RD_A0        (0x00000500)
#define RD_A1        (0x00000580)
#define RD_A2        (0x00000600)
#define RD_A3        (0x00000680)
#define RD_A4        (0x00000700)
#define RD_A5        (0x00000780)
#define RS1_A0       (0x00050000)
#define RS1_A1       (0x00058000)
#define RS1_A2       (0x00060000)
#define RS1_A3       (0x00068000)
#define RS1_A4       (0x00070000)
#define RS1_A5       (0x00088000)
#define RS2_ZERO     (0x00000000)
#define RS2_A0       (0x00a00000)
#define RS2_A1       (0x00b00000)
#define RS2_A2       (0x00c00000)
#define RS2_A3       (0x00d00000)
#define RS2_A4       (0x00e00000)
#define RS2_A5       (0x00f00000)
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
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM0|RD_A5|RS1_A4|RS2_ZERO
    lw      a4,4(a0)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM1|RD_A5|RS1_A4|RS2_A5
    lw      a4,8(a0)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM2|RD_A5|RS1_A4|RS2_A5
    lw      a4,0(a1)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM3|RD_A5|RS1_A4|RS2_A5
    lw      a4,4(a1)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM4|RD_A5|RS1_A4|RS2_A5
    lw      a4,8(a1)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM5|RD_A5|RS1_A4|RS2_A5
    lw      a4,0(a2)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM6|RD_A5|RS1_A4|RS2_A5
    lw      a4,4(a2)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM7|RD_A5|RS1_A4|RS2_A5
    lw      a4,8(a2)
    add     a4,a3,a4
    .word BNN_ACC8_OP|BNN_PARAM8|RD_A0|RS1_A4|RS2_A5
    ret

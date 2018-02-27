#define BNN_INI_OP   (0x0000000b)
#define BNN_ACC_OP   (0x0000100b)
#define BNN_POOL_OP  (0x0000200b)
#define BNN_NORM_OP  (0x0000300b)
#define BNN_ACTIV_OP (0x0000400b)
#define BNN_ACC8_OP  (0x0000500b)
#define BNN_SET_OP   (0x0000600b)
#define BNN_NORM8_OP (0x0000700b)
#define RD_A0        (0x00000500)
#define RS1_A0       (0x00050000)
#define RS2_A0       (0x00a00000)
#define RS2_A1       (0x00b00000)

.global bnn_ini
bnn_ini:
    .word BNN_INI_OP|RS2_A0
    ret

.global bnn_acc
bnn_acc:
    .word BNN_ACC_OP|RS1_A0|RS2_A1
    ret

.global bnn_pool
bnn_pool:
    .word BNN_POOL_OP|RS2_A0
    ret

.global bnn_norm
bnn_norm:
    .word BNN_NORM_OP|RS1_A0
    ret

.global bnn_activ
bnn_activ:
    .word BNN_ACTIV_OP|RD_A0
    ret

.global bnn_acc8
bnn_acc8:
    .word BNN_ACC8_OP|RD_A0|RS1_A0|RS2_A1
    ret

.global bnn_set
bnn_set:
    .word BNN_SET_OP|RS1_A0|RS2_A1
    ret

.global bnn_norm8
bnn_norm8:
    .word BNN_NORM8_OP|RS1_A0
    ret

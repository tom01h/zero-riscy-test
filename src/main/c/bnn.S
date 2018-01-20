/*#define ADD_OP (0x00b50533)*/
#define ADD_OP (0x00b5050b)

.global add
add:
    .word ADD_OP
    ret

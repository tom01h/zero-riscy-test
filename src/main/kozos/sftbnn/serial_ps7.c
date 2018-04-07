#include "defines.h"
#include "serial.h"

#define SERIAL_NUM 2

#define ZYNQ_UART0 ((volatile struct zynq_uart *)0xE0000000)
#define ZYNQ_UART1 ((volatile struct zynq_uart *)0xE0001000)

struct zynq_uart {
  volatile uint32 Control;                 // 0x00000000
  volatile uint32 mode;                    // 0x00000004
  volatile uint32 Intrpt_en;               // 0x00000008
  volatile uint32 Intrpt_dis;              // 0x0000000C
  volatile uint32 Intrpt_mask;             // 0x00000010
  volatile uint32 Chnl_int_sts;            // 0x00000014
  volatile uint32 Baud_rate_gen;           // 0x00000018
  volatile uint32 Rcvr_timeout;            // 0x0000001C
  volatile uint32 Rcvr_FIFO_trigger_level; // 0x00000020
  volatile uint32 Modem_ctrl;              // 0x00000024
  volatile uint32 Modem_sts;               // 0x00000028
  volatile uint32 Channel_sts;             // 0x0000002C
  //TFUL(TXFULL)4 ro 0x0 Transmitter FIFO Full continuous status:
  //  0: Tx FIFO is not full
  //  1: Tx FIFO is full
  //TEMPTY(TXEMPTY)3 ro 0x0 Transmitter FIFO Empty continuous status:
  //  0: Tx FIFO is not empty
  //  1: Tx FIFO is empty
  //RFUL(RXFULL)2 ro 0x0 Receiver FIFO Full continuous status:
  //  1: Rx FIFO is full
  //  0: Rx FIFO is not full
  //REMPTY(RXEMPTY)1 ro 0x0 Receiver FIFO Full continuous status:
  //  0: Rx FIFO is not empty
  //  1: Rx FIFO is empty
  //RTRIG (RXOVR) 0 ro 0x0 Receiver FIFO Trigger continuous status:
  //  0: Rx FIFO fill level is less than RTRIG
  //  1: Rx FIFO fill level is greater than or equal to RTRIG
  volatile uint32 TX_RX_FIFO;              // 0x00000030
  //FIFO 7:0 rw 0x0 Operates as Tx FIFO and Rx FIFO.
  volatile uint32 Baud_rate_divider;       // 0x00000034
  volatile uint32 Flow_delay;              // 0x00000038
  volatile uint32 Tx_FIFO_trigger_level;   // 0x00000044
};

#define ZYNQ_UART_ST_RXE   (1<<1)
#define ZYNQ_UART_ST_TXF   (1<<4)

static struct {
  volatile struct zynq_uart *sci;
} regs[SERIAL_NUM] = {
  { ZYNQ_UART0 },
  { ZYNQ_UART1 },
};

/* デバイス初期化 */
int serial_init(int index)
{
  return 0;
}

/* 送信可能か？ */
int serial_is_send_enable(int index)
{
  volatile struct zynq_uart *sci = regs[index].sci;
  return (!(sci->Channel_sts & ZYNQ_UART_ST_TXF));
}

/* １文字送信 */
int serial_send_byte(int index, unsigned char c)
{
  volatile struct zynq_uart *sci = regs[index].sci;

  
  /* 送信可能になるまで待つ */
  while (!serial_is_send_enable(index))
    ;
  sci->TX_RX_FIFO = c;

  return 0;
}

/* 受信可能か？ */
int serial_is_recv_enable(int index)
{
  volatile struct zynq_uart *sci = regs[index].sci;
  return (!(sci->Channel_sts & ZYNQ_UART_ST_RXE));
}

/* １文字受信 */
unsigned char serial_recv_byte(int index)
{
  volatile struct zynq_uart *sci = regs[index].sci;
  unsigned char c;

  /* 受信文字が来るまで待つ */
  while (!serial_is_recv_enable(index))
    ;
  c = sci-> TX_RX_FIFO;

  return c;
}

#include "defines.h"
#include "serial.h"

#define SERIAL_NUM 2

#define UART_LITE0 ((volatile struct uart_lite *)0x9a101000)
#define UART_LITE1 ((volatile struct uart_lite *)0x9a100000)

struct uart_lite {
  volatile uint32 RxDATA;
//      [7:0]  Rx Data
  volatile uint32 TxDATA;
//      [7:0]  Tx Data
  volatile uint32 STAT;
//      [0]    Rx Valid
//      [1]    Rx Full
//      [2]    Tx Valid
//      [3]    Tx Full
  volatile uint32 CTRL;
//      [0]    Rst Tx
//      [1]    Rst Rx
};

#define UART_LITE_ST_RXE   (1<<0)
#define UART_LITE_ST_TXF   (1<<3)

static struct {
  volatile struct uart_lite *sci;
} regs[SERIAL_NUM] = {
  { UART_LITE0 },
  { UART_LITE1 },
};

/* �ǥХ�������� */
int serial_init(int index)
{
  unsigned char dummy;
  volatile struct uart_lite *sci = regs[index].sci;

  sci->CTRL = 3;

  return 0;
}

/* ������ǽ���� */
int serial_is_send_enable(int index)
{
  volatile struct uart_lite *sci = regs[index].sci;
  return (!(sci->STAT & UART_LITE_ST_TXF));
}

/* ��ʸ������ */
int serial_send_byte(int index, unsigned char c)
{
  volatile struct uart_lite *sci = regs[index].sci;

  
  /* ������ǽ�ˤʤ�ޤ��Ԥ� */
  while (!serial_is_send_enable(index))
    ;
  sci->TxDATA = c;

  return 0;
}

/* ������ǽ���� */
int serial_is_recv_enable(int index)
{
  volatile struct uart_lite *sci = regs[index].sci;
  return (sci->STAT & UART_LITE_ST_RXE);
}

/* ��ʸ������ */
unsigned char serial_recv_byte(int index)
{
  volatile struct uart_lite *sci = regs[index].sci;
  unsigned char c;

  /* ����ʸ�������ޤ��Ԥ� */
  while (!serial_is_recv_enable(index))
    ;
  c = sci->RxDATA;

  return c;
}

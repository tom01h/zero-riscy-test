#include "defines.h"
#include "serial.h"
#include "xmodem.h"
#include "elf.h"
#include "lib.h"
#include "ff.h"

static int init(void)
{
  /* �ʲ��ϥ�󥫡�������ץȤ�������Ƥ��륷��ܥ� */
  extern int erodata, data_start, edata, bss_start, ebss;

  /*
   * �ǡ����ΰ��BSS�ΰ���������롥���ν����ʹߤǤʤ��ȡ�
   * �����Х��ѿ������������Ƥ��ʤ��Τ���ա�
   */
  //  memcpy(&data_start, &erodata, (long)&edata - (long)&data_start);
  memcpy(&data_start, &erodata, (long)&bss_start - (long)&data_start);
  memset(&bss_start, 0, (long)&ebss - (long)&bss_start);

  /* ���ꥢ��ν���� */
  serial_init(SERIAL_DEFAULT_DEVICE);

  return 0;
}

/* �����16�ʥ���׽��� */
static int dump(char *buf, long size)
{
  long i;

  if (size < 0) {
    puts("no data.\n");
    return -1;
  }
  for (i = 0; i < size; i++) {
    putxval(buf[i], 2);
    if ((i & 0xf) == 15) {
      puts("\n");
    } else {
      if ((i & 0xf) == 7) puts(" ");
      puts(" ");
    }
  }
  puts("\n");

  return 0;
}

static void wait()
{
  volatile long i;
//for (i = 0; i <  300000; i++)
#if SERIAL_DEFAULT_DEVICE
  for (i = 0; i < 30; i++)
#else
  for (i = 0; i < 3000000; i++)
#endif
    ;
}

int main(void)
{
  static char buf[16];
  static long size = -1;
  static unsigned char *loadbuf = NULL;
  char *entry_point;
  void (*f)(void);
  extern int buffer_start; /* ��󥫡�������ץȤ��������Ƥ���Хåե� */

  FIL fil;
  FATFS fatfs;
  FRESULT Res;
  TCHAR *Path = "0:/";
  unsigned char buff[512];
  UINT NumBytesRead;
  UINT FileSize = 512;

  init();

  puts("kzload (kozos boot loader) started.\n");

  while (1) {
    puts("kzload> "); /* �ץ��ץ�ɽ�� */
    gets(buf); /* ���ꥢ�뤫��Υ��ޥ�ɼ��� */

    if (!strcmp(buf, "load")) { /* XMODEM�ǤΥե�����Υ�������� */
      loadbuf = (char *)(&buffer_start);
      size = xmodem_recv(loadbuf);
      wait(); /* ž�����ץ꤬��λ��ü�����ץ�����椬���ޤ��Ԥ���碌�� */
      if (size < 0) {
	puts("\nXMODEM receive error!\n");
      } else {
	puts("\nXMODEM receive succeeded.\n");
      }
    } else if (!strcmp(buf, "dump")) { /* �����16�ʥ���׽��� */
      puts("size: ");
      putxval(size, 0);
      puts("\n");
      dump(loadbuf, size);
    } else if (!strncmp(buf, "run", 3)) { /* ELF�����ե�����μ¹� */
      if(buf[3]){
        Res = f_mount(&fatfs, Path, 0);
        if(!Res){
          Res = f_open(&fil, &buf[4], FA_READ);
        }else{
          puts("f_mount error ");putxval(Res, 2); puts("\n");
        }
        if(!Res){
          Res = f_read(&fil, buff, FileSize, &NumBytesRead);
        }else{
          puts("f_open error ");putxval(Res, 2); puts("\n");
        }
        if(!Res){
          entry_point = elf_load(buff, &fil); /* ������Ÿ��(����) */
        }else{
          puts("f_read error ");putxval(Res, 2); puts("\n");
        }
      }else{
        entry_point = elf_load(loadbuf, 0); /* ������Ÿ��(����) */
      }
      if (!entry_point) {
        puts("run error!\n");
      } else {
        puts("starting from entry point: ");
        putxval((unsigned long)entry_point, 0);
        puts("\n");
        f = (void (*)(void))entry_point;
        f(); /* �����ǡ����ɤ����ץ����˽������Ϥ� */
        //        dump(entry_point, 256); //TEMP//TEMP//
        /* �����ˤ��֤äƤ��ʤ� */
      }
    } else {
      puts("unknown.\n");
    }
  }

  return 0;
}

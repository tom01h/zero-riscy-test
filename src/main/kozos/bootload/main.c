#include "defines.h"
#include "serial.h"
#include "xmodem.h"
#include "elf.h"
#include "lib.h"
#include "ff.h"

static int init(void)
{
  /* 以下はリンカ・スクリプトで定義してあるシンボル */
  extern int erodata, data_start, edata, bss_start, ebss;

  /*
   * データ領域とBSS領域を初期化する．この処理以降でないと，
   * グローバル変数が初期化されていないので注意．
   */
  //  memcpy(&data_start, &erodata, (long)&edata - (long)&data_start);
  memcpy(&data_start, &erodata, (long)&bss_start - (long)&data_start);
  memset(&bss_start, 0, (long)&ebss - (long)&bss_start);

  /* シリアルの初期化 */
  serial_init(SERIAL_DEFAULT_DEVICE);

  return 0;
}

/* メモリの16進ダンプ出力 */
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
  extern int buffer_start; /* リンカ・スクリプトで定義されているバッファ */

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
    puts("kzload> "); /* プロンプト表示 */
    gets(buf); /* シリアルからのコマンド受信 */

    if (!strcmp(buf, "load")) { /* XMODEMでのファイルのダウンロード */
      loadbuf = (char *)(&buffer_start);
      size = xmodem_recv(loadbuf);
      wait(); /* 転送アプリが終了し端末アプリに制御が戻るまで待ち合わせる */
      if (size < 0) {
	puts("\nXMODEM receive error!\n");
      } else {
	puts("\nXMODEM receive succeeded.\n");
      }
    } else if (!strcmp(buf, "dump")) { /* メモリの16進ダンプ出力 */
      puts("size: ");
      putxval(size, 0);
      puts("\n");
      dump(loadbuf, size);
    } else if (!strncmp(buf, "run", 3)) { /* ELF形式ファイルの実行 */
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
          entry_point = elf_load(buff, &fil); /* メモリ上に展開(ロード) */
        }else{
          puts("f_read error ");putxval(Res, 2); puts("\n");
        }
      }else{
        entry_point = elf_load(loadbuf, 0); /* メモリ上に展開(ロード) */
      }
      if (!entry_point) {
        puts("run error!\n");
      } else {
        puts("starting from entry point: ");
        putxval((unsigned long)entry_point, 0);
        puts("\n");
        f = (void (*)(void))entry_point;
        f(); /* ここで，ロードしたプログラムに処理を渡す */
        //        dump(entry_point, 256); //TEMP//TEMP//
        /* ここには返ってこない */
      }
    } else {
      puts("unknown.\n");
    }
  }

  return 0;
}

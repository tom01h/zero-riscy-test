#include "ff.h"

static volatile unsigned char *SDFN = ((volatile unsigned char *)0x9a100120);
static volatile unsigned int  *SDBP = ((volatile unsigned int  *)0x9a100100);
static volatile unsigned int  *SDRS = ((volatile unsigned int  *)0x9a100104);
static volatile unsigned int  *SDSP = ((volatile unsigned int  *)0x9a100108);
static volatile unsigned int  *SDFP = ((volatile unsigned int  *)0x9a10010c);

FRESULT f_mount (FATFS* fs, const TCHAR* path, BYTE opt){
  return 0;
}

FRESULT f_open (FIL* fp, const TCHAR* path, BYTE mode){
  // f_open
  strcpy(SDFN,path);
  return 0;
}

FRESULT f_read (FIL* fp, void* buff, UINT btr, UINT* br){
  // f_read
  unsigned char buf[512];
  unsigned char *bufff=buff;
  int brn;

  if(((int)buf&0xfff00000)==((int)buff&0xfff00000)){
    *SDBP = buff;
    *SDSP = &brn;
    *SDRS = btr;
  }else{
    for(int p;p<btr;p+=512){
      *SDBP = buf;
      *SDSP = &brn;
      if(btr-p>512){
        *SDRS = 512;
      }else{
        *SDRS = btr-p;
      }
      for(int i=0;i<brn;i++){
        bufff[p+i]=buf[i];
      }
    }
  }
  return 0;
}


FRESULT f_lseek (FIL* fp, FSIZE_t ofs){
  // f_lseek
  *SDFP = ofs;
  return 0;
}

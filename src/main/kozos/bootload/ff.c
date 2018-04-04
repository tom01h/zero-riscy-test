#include "ff.h"

static volatile unsigned char *SDFN = ((volatile unsigned char *)0x9a101020);
static volatile unsigned int  *SDBP = ((volatile unsigned int  *)0x9a101000);
static volatile unsigned int  *SDRS = ((volatile unsigned int  *)0x9a101004);
static volatile unsigned int  *SDSP = ((volatile unsigned int  *)0x9a101008);
static volatile unsigned int  *SDFP = ((volatile unsigned int  *)0x9a10100c);

FRESULT f_mount (FATFS* fs, const TCHAR* path, BYTE opt){
}

FRESULT f_open (FIL* fp, const TCHAR* path, BYTE mode){
  // f_open
  strcpy(SDFN,path);
}

FRESULT f_read (FIL* fp, void* buff, UINT btr, UINT* br){
  // f_read
  unsigned char buf[512];
  unsigned char *bufff=buff;
  int brn;

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


FRESULT f_lseek (FIL* fp, FSIZE_t ofs){
  // f_lseek
  *SDFP = ofs;
}

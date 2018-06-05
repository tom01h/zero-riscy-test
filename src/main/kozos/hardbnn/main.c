#include "defines.h"
#include "serial.h"
#include "lib.h"
#include "ff.h"

#include "paramb.h"

extern int bnn_acc8(int *,int *,int *,int *);
volatile static int *INIT = 0x80181000;
volatile static int *POOL = 0x80181004;
volatile static int *ACTV = 0x8018100c;
volatile static int *SET  = 0x80181100;
volatile static int   *ACC  = 0x80180600;
volatile static short *NORM = 0x80180600;
volatile static char *NORM8 = 0x80180600;

void putx(unsigned int d)
{
  unsigned int rem = d;
  for(int i=7; i>=0; i--){
    unsigned int div = 1;
    for(int j=0; j<i; j++){
      div *=16;
    }
    int c = rem/div;
    if(c<10){
      putc('0'+c);
    }else{
      putc('a'+c-10);
    }
    rem = rem % div;
  }
}

void putd(int d)
{
  int rem;
  if(d<0){
    putc('-');
    rem = -d;
  }else{
    putc(' ');
    rem = d;
  }
  for(int i=6; i>=0; i--){
    int div=1;
    for(int j=0; j<i; j++){
      div *=10;
    }
    putc('0'+rem/div);
    rem = rem % div;
  }
}

void BinAffine(int xi,int ci, int in[xi], int f, int mean, signed char out[1][1][ci])
{
  int active;
  for(int c=0; c<ci/32; c++){
    *INIT = -1024;
    for(int x=0; x<xi; x++){
      ACC[f+x+c*xi] = in[x];
    }
    *POOL = -1024;
    NORM[(mean+c)*2] = 0;
    active = *ACTV;
    for(int cc=0; cc<32; cc++){
      if(active & (1<<cc)){
        out[0][0][c*32+cc] = -1;
      } else {
        out[0][0][c*32+cc] = 1;
      }
    }
  }
}

void Affine(int xi,int ci, signed char in[1][1][xi], int f[ci][xi], int out[ci])
{
  for(int c=0; c<ci; c++){
    out[c] = 0;
    for(int x=0; x<xi; x++){
      out[c] += f[c][x]*in[0][0][x];
    }
  }
}

void BinConv(int ci, int yi, int xi, int in[yi+2][xi+2][ci],
             int fci, int fyi, int fxi, int f, int mean,
             int pad, int out[yi/2+pad][xi/2+pad][fci])
{
  for(int c=0; c<fci; c++){
    for(int y=0; y<yi; y+=2){
      for(int x=0; x<xi; x+=2){
        *INIT = -288;
        for(int yy=0; yy<2; yy++){
          for(int xx=0; xx<2; xx++){
            for(int fc=0; fc<ci; fc++){
              for(int fy=0; fy<fyi; fy++){
                for(int fx=0; fx<fxi; fx++){
                  ACC[f+c*fyi*fxi+fy*fxi*ci+fx*ci+fc] = in[fy+(y+yy)][fx+(x+xx)][fc];
                }
              }
            }
            *POOL = -288;
          }
        }
        NORM[(mean+c)*2] = 0;
        out[(y+pad)/2][(x+pad)/2][c] = *ACTV;
      }
    }
  }
}

void Conv(int ci, int yi, int xi, int in[yi+2][xi+2],
          int fci, int fyi, int fxi, int f, int mean,
          int out[yi/2+2][xi/2+2][fci])
{
  for(int c=0; c<fci; c++){
    for(int y=0; y<yi; y+=2){
      for(int x=0; x<xi; x+=2){
        *INIT = 0;
        for(int yy=0; yy<2; yy++){
          for(int xx=0; xx<2; xx++){
            int* addr0 = &in[0+(y+yy)][0+(x+xx)];
            int* addr1 = &in[1+(y+yy)][0+(x+xx)];
            int* addr2 = &in[2+(y+yy)][0+(x+xx)];
            //for(int cc=0; cc<16; cc++){
            //SET[cc] = bnn_acc8(addr0, addr1, addr2, cc);
            //}
            bnn_acc8(addr0, addr1, addr2, SET);
            *POOL = 0;
          }
        }
        NORM8[(mean+c)*4] = 0;
        out[y/2+1][x/2+1][c] = *ACTV;
      }
    }
  }
}

int main(int argc,char *argv[])
{
  FIL fil;
  FATFS fatfs;
  FRESULT Res;
  TCHAR *Path = "0:/";
  unsigned char buff[32*32*3];
  UINT NumBytesRead;

  Res = f_mount(&fatfs, Path, 0);
  if(!Res){
    Res = f_open(&fil, "cifar10", FA_READ);
  }else{
    puts("f_mount error ");putxval(Res, 2); puts("\n");
  }

  unsigned char label;
  int pict[32+2][32+2];

  int activ1out[16+2][16+2][1]; // +2=padding

  int activ2out[8+2][8+2][1]; // +2=padding

  int activ3out[4][4][2];
  int layer4in[2*4*4];

  signed char activ4out[1][1][512];

  int affine5out[10];

  // padding
  for(int y=0; y<32+2; y++){
    for(int x=0; x<32+2; x++){
      if((x==0)|(x==33)|(y==0)|(y==33)){
        pict[y][x] = -2122219264;
      }
    }
  }
  for(int c=0; c<32/32; c++){
    for(int y=17; y>=0; y--){
      for(int x=17; x>=0; x--){
        if((x==0)|(x==17)|(y==0)|(y==17)){
          activ1out[y][x][c] = 0;
        }
      }
    }
  }
  for(int c=0; c<32/32; c++){
    for(int y=9; y>=0; y--){
      for(int x=9; x>=0; x--){
        if((x==0)|(x==9)|(y==0)|(y==9)){
          activ2out[y][x][c] = 0;
        }
      }
    }
  }

  // main loop
  int pass = 0;
  //for (int i=0;i<1000;i++){
  for (int i=0;i<1;i++){
    f_read(&fil, buff, 1, &NumBytesRead);
    label = buff[0];
    f_read(&fil, buff, 32*32*3, &NumBytesRead);
    for(int y=0; y<32; y++){
      for(int x=0; x<32; x++){
        pict[y+1][x+1]  = (((buff[y*32+x+0*32*32]*2-255)/2)&0x0ff)<<24;
        pict[y+1][x+1] |= (((buff[y*32+x+1*32*32]*2-255)/2)&0x0ff)<<16;
        pict[y+1][x+1] |= (((buff[y*32+x+2*32*32]*2-255)/2)&0x0ff)<<8;
      }
    }

    Conv(3,32,32,pict,32/32,3,3,0,539,activ1out);
    BinConv(32/32,16,16,activ1out,32/32,3,3,0,540,2,activ2out);
    BinConv(32/32,8,8,activ2out,64/32,3,3,9,541,0,activ3out);
    for(int c=0; c<64/32; c++){
      for(int y=0; y<4; y++){
        for(int x=0; x<4; x++){
          layer4in[y*2*4+x*2+c] = activ3out[y][x][c];
        }
      }
    }
    BinAffine(1024/32,512,layer4in,27,543,activ4out);

    Affine(512,10,activ4out,W5,affine5out);

    int result = 0;
    int max = affine5out[0];
    for(int x=0; x<10; x++){
      if(affine5out[x]>max){
        max = affine5out[x];
        result = x;
      }
    }
    if(result==label){
      pass++;
    }else{
      //printf ("No. %02d / Answer : %02d != Result : %02d\n",i,label,result);
      puts("No. ");
      putd(i);
      puts(" / Answer : ");
      putc('0'+label);
      puts(" != Result : ");
      putc('0'+result);
      puts("\n");
    }

  }
  //  printf ("== Pass Count : %04d ==\n",pass);
  puts("== Pass Count : ");
  putd(pass);
  puts(" ==\n");

  for(int x=0; x<10; x++){
    putd(affine5out[x]);
    puts(", ");
  }
  puts("\n");

  return 0;
}

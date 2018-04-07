#include "defines.h"
#include "serial.h"
#include "lib.h"
#include "ff.h"

#include "paramb.h"

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

void BinAffine(int xi,int ci, int in[xi], int f[ci][xi], int mean[ci], signed char out[ci])
{
  int acc;
  for(int c=0; c<ci; c++){
    acc = 0;
    for(int x=0; x<xi; x++){
      unsigned cnt = f[c][x] ^ in[x];
      cnt = cnt - ((cnt >> 1) & 0x55555555);
      cnt = (cnt & 0x33333333) + ((cnt >> 2) & 0x33333333);
      acc -= ((((cnt + (cnt >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24)*2;
      acc += 32;
    }
    if((acc*64-mean[c])>=0){
      out[c] = 1;
    } else {
      out[c] = -1;
    }
  }
}

void Affine(int xi,int ci, signed char in[xi], int f[ci][xi], int out[ci])
{
  for(int c=0; c<ci; c++){
    out[c] = 0;
    for(int x=0; x<xi; x++){
      out[c] += f[c][x]*in[x];
    }
  }
}

void BinConv(int ci, int yi, int xi, int in[yi+2][xi+2][ci],
             int fci, int fyi, int fxi, int f[fci][ci*fyi*fxi], int mean[ci],
             int pad, int out[yi/2+pad][xi/2+pad][fci])
{
  int acc;
  int pool;
  int act;
  for(int c=0; c<fci; c++){
    for(int y=0; y<yi; y+=2){
      for(int x=0; x<xi; x+=2){
        act = 0;
        for(int cc=0; cc<32; cc++){
          pool = 0x80000000;
          for(int yy=0; yy<2; yy++){
            for(int xx=0; xx<2; xx++){
              acc = 0;
              for(int fc=0; fc<ci; fc++){
                for(int fy=0; fy<fyi; fy++){
                  for(int fx=0; fx<fxi; fx++){
                    unsigned cnt = f[c*32+cc][fy*fxi*ci+fx*ci+fc] ^ in[fy+(y+yy)][fx+(x+xx)][fc];
                    cnt = cnt - ((cnt >> 1) & 0x55555555);
                    cnt = (cnt & 0x33333333) + ((cnt >> 2) & 0x33333333);
                    acc -= ((((cnt + (cnt >> 4)) & 0x0F0F0F0F) * 0x01010101) >> 24)*2;
                    acc += 32;
                  }
                }
              }
              if(acc>pool){
                pool=acc;
              }
            }
          }
          if((pool*64-mean[c*32+cc])<0){
            act |= (1<<cc);
          }
        }
        out[(y+pad)/2][(x+pad)/2][c] = act;
      }
    }
  }
}

void Conv(int ci, int yi, int xi, unsigned char in[yi+2][xi+2][ci],
          int fci, int fyi, int fxi, int f[fci*32][ci*fyi*fxi], int mean[fci*32],
          int out[yi/2+2][xi/2+2][fci])
{
  short acc;
  int pool;
  int act;
  for(int c=0; c<fci; c++){
    for(int y=0; y<yi; y+=2){
      for(int x=0; x<xi; x+=2){
        act = 0;
        for(int cc=0; cc<32; cc++){
          pool = 0x80000000;
          for(int yy=0; yy<2; yy++){
            for(int xx=0; xx<2; xx++){
              acc = 0;
              for(int fc=0; fc<ci; fc++){
                for(int fy=0; fy<fyi; fy++){
                  for(int fx=0; fx<fxi; fx++){
                    acc += f[c*32+cc][fy*fxi*ci+fx*ci+fc]*(in[fy+(y+yy)][fx+(x+xx)][fc]*2-255)/4;
                  }
                }
              }
              if(acc>pool){
                pool=acc;
              }
            }
          }
          if((pool-mean[c*32+cc])<0){
            act |= (1<<cc);
          }
        }
        out[y/2+1][x/2+1][c] = act;
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
  unsigned char buff[32];
  UINT NumBytesRead;

  Res = f_mount(&fatfs, Path, 0);
  if(!Res){
    Res = f_open(&fil, "cifar10", FA_READ);
  }else{
    puts("f_mount error ");putxval(Res, 2); puts("\n");
  }

  unsigned char label;
  unsigned char pict[32+2][32+2][3];

  int activ1out[16+2][16+2][1]; // +2=padding

  int activ2out[8+2][8+2][1]; // +2=padding

  int activ3out[4][4][2];
  int layer4in[2*4*4];

  signed char activ4out[512];

  int affine5out[10];

  // padding
  for(int c=0; c<3; c++){
    for(int y=0; y<32+2; y++){
      for(int x=0; x<32+2; x++){
        if((x==0)|(x==33)|(y==0)|(y==33)){
          pict[y][x][c] = 0;
        }
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
  for (int i=0;i<1000;i++){
  //for (int i=0;i<1;i++){
    f_read(&fil, buff, 1, &NumBytesRead);
    label = buff[0];
    for(int c=0; c<3; c++){
      for(int y=1; y<32+1; y++){
        f_read(&fil, buff, 32, &NumBytesRead);
        for(int x=1; x<32+1; x++){
          pict[y][x][c] = buff[x-1];
        }
      }
    }

    Conv(3,32,32,pict,32/32,3,3,W1,mean1,activ1out);
    BinConv(32/32,16,16,activ1out,32/32,3,3,W2,mean2,2,activ2out);
    BinConv(32/32,8,8,activ2out,64/32,3,3,W3,mean3,0,activ3out);
    for(int c=0; c<64/32; c++){
      for(int y=0; y<4; y++){
        for(int x=0; x<4; x++){
          layer4in[y*2*4+x*2+c] = activ3out[y][x][c];
        }
      }
    }
    BinAffine(1024/32,512,layer4in,W4,mean4,activ4out);

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

  return 0;
}

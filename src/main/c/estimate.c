#include "paramb.h"
#include "pict.h"
//#include "activ1.h"

volatile unsigned char *Data = ((volatile unsigned char *)0x9a100000);
volatile unsigned char *Endf = ((volatile unsigned char *)0x8017fffc);

extern int bnn_ini(int);
extern int bnn_acc(int,int);
extern int bnn_pool(int);
extern int bnn_norm(int);
extern int bnn_activ();

int putc(unsigned char c)
{
  if (c == '\n')
    *Data = '\r';
  *Data = c;
  return 0;
}

int puts(char *str)
{
  while (*str)
    putc(*(str++));
  return 0;
}

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
  for(int c=0; c<ci/32; c++){
    bnn_ini(-1024);
    for(int x=0; x<xi; x++){
      bnn_acc(f+x+c*xi,in[x]);
    }
    bnn_pool(-1024);
    bnn_norm(mean+c);
    int active = bnn_activ();
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
        bnn_ini(-288);
        for(int yy=0; yy<2; yy++){
          for(int xx=0; xx<2; xx++){
            for(int fc=0; fc<ci; fc++){
              for(int fy=0; fy<fyi; fy++){
                for(int fx=0; fx<fxi; fx++){
                  bnn_acc(f+c*fyi*fxi+fy*fxi*ci+fx*ci+fc,in[fy+(y+yy)][fx+(x+xx)][fc]);
                }
              }
            }
            bnn_pool(-288);
          }
        }
        bnn_norm(mean+c);
        out[(y+pad)/2][(x+pad)/2][c] = bnn_activ();
      }
    }
  }
}

void Conv(int ci, int yi, int xi, unsigned char in[yi+2][xi+2][ci],
          int fci, int fyi, int fxi, int f[fci][ci*fyi*fxi], int mean[ci],
          int out[yi/2+2][xi/2+2][fci])
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
                    acc += f[c*32+cc][fy*fxi*ci+fx*ci+fc]*(in[fy+(y+yy)][fx+(x+xx)][fc]*2-255);
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
  int activ1out[16+2][16+2][1]; // +2=padding

  int activ2out[8+2][8+2][1]; // +2=padding

  int activ3out[4][4][2];
  int layer4in[2*4*4];

  signed char activ4out[1][1][512];

  int affine5out[10];

  int pass = 0;

  // padding

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

  for (int i=0;i<1;i++){

    Conv(3,32,32,pict,32/32,3,3,W1,mean1,activ1out);
    puts("1st layer finished\n");

    BinConv(32/32,16,16,activ1out,32/32,3,3,0,539,2,activ2out);
    puts("2nd layer finished\n");

    BinConv(32/32,8,8,activ2out,64/32,3,3,9,540,0,activ3out);
    puts("3rd layer finished\n");

    for(int c=0; c<64/32; c++){
      for(int y=0; y<4; y++){
        for(int x=0; x<4; x++){
          layer4in[y*2*4+x*2+c] = activ3out[y][x][c];
        }
      }
    }
    BinAffine(1024/32,512,layer4in,27,542,activ4out);
    puts("4th layer finished\n");

    Affine(512,10,activ4out,W5,affine5out);
    puts("5th layer finished\n");

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

  for(int y=0; y<16; y++){
    for(int x=0; x<16; x++){
      putx(activ1out[y+1][x+1][0]);
      puts(", ");
    }
    puts("\n");
  }
  puts("\n");

  for(int y=0; y<8; y++){
    for(int x=0; x<8; x++){
      putx(activ2out[y+1][x+1][0]);
      puts(", ");
    }
    puts("\n");
  }
  puts("\n");

  for(int y=0; y<4; y++){
    for(int x=0; x<4; x++){
      putx(activ3out[y][x][0]);
      puts(", ");
      putx(activ3out[y][x][1]);
      puts(", ");
    }
    puts("\n");
  }
  puts("\n");

  for(int x=0; x<10; x++){
    putd(affine5out[x]);
    puts(", ");
  }
  puts("\n");

  *Endf = 1;
}

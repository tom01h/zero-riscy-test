volatile unsigned char *Data = ((volatile unsigned char *)0x9a100000);
volatile unsigned char *Endf = ((volatile unsigned char *)0x8017fffc);

int putc(unsigned char c)
{
  if (c == '\n')
    *Data = '\r';
  *Data = c;
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

int puts(char *str)
{
  while (*str)
    putc(*(str++));
  return 0;
}

/*
int add(int a, int b)
{
  return a+b;
}
*/

extern int add(int,int);

int main(void)
{
  puts("Hello !!\nzero riscy world\n");

  int a = 10;
  int b = 15;

  int rslt = add(a,b);

  putx(rslt);
  puts("\n");

  *Endf = 1;
  return 0;
}

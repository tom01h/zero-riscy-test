volatile unsigned char *Data = ((volatile unsigned char *)0x9a100000);
volatile unsigned char *Endf = ((volatile unsigned char *)0x8017fffc);

int putc(unsigned char c)
{
  if (c == '\n')
    *Data = '\r';
  *Data = c;
  return 0;
}

int puts(unsigned char *str)
{
  while (*str)
    putc(*(str++));
  return 0;
}

int main(void)
{
  puts("Hello !!\nzero riscy world\n");
  *Endf = 1;
  return 0;
}

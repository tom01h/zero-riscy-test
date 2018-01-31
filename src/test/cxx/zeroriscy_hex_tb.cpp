#include "unistd.h"
#include "getopt.h"
#include "Vzeroriscy_verilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"
//#include "conio.h" // Windows

#define VCD_PATH_LENGTH 256

vluint64_t main_time = 0;
vluint64_t vcdstart = 0;
vluint64_t vcdend = 0;

void eval(Vzeroriscy_verilator_top* verilator_top, VerilatedVcdC* tfp)
{
  verilator_top->clk = 0;
  verilator_top->eval();
  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);

  main_time += 50;

  verilator_top->clk = 1;
  verilator_top->eval();
  if((main_time>=vcdstart)&((main_time<vcdend)|(vcdend==0)))
    tfp->dump(main_time);

  main_time += 50;

  return;
}

void xmodem(Vzeroriscy_verilator_top* verilator_top, VerilatedVcdC* tfp)
{
  int block, check, num;
  char buf[128];
  FILE *fp;

  block = 1;
  num = 128;
  fp = fopen("xmodem.dat", "rb");

  //// wait NAK ////
  while(!((verilator_top->v__DOT__uart_sim__DOT__req_l)&&
          (verilator_top->v__DOT__uart_sim__DOT__we_l)&&
          (verilator_top->v__DOT__uart_sim__DOT__addr_l==2)&&
          (verilator_top->v__DOT__uart_sim__DOT__d_l==0x15))){
    eval(verilator_top, tfp);
  }
  while(num==128){
    //// send SOH ////
    while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
      eval(verilator_top, tfp);
    }
    verilator_top->v__DOT__uart_sim__DOT__dout_o = 0x01;
    verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
    //// send block ////
    while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
      eval(verilator_top, tfp);
    }
    verilator_top->v__DOT__uart_sim__DOT__dout_o = block;
    verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
    //// send ~block ////
    while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
      eval(verilator_top, tfp);
    }
    verilator_top->v__DOT__uart_sim__DOT__dout_o = ~block;
    verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
    num = fread(&buf, 1 ,128 ,fp);
    check = 0;
    //// send data ////
    for(int i=0; i<128; i++){
      while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
        eval(verilator_top, tfp);
      }
      if(i<num){
       verilator_top->v__DOT__uart_sim__DOT__dout_o = buf[i];
        check += buf[i];
      }else{
        verilator_top->v__DOT__uart_sim__DOT__dout_o = 0x1a;
        check += 0x1a;
      }
      verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
    }
    //// send check sum ////
    while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
      eval(verilator_top, tfp);
    }
    verilator_top->v__DOT__uart_sim__DOT__dout_o = check;
    verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
    //// wait ACK ////
    while(!((verilator_top->v__DOT__uart_sim__DOT__req_l)&
            (verilator_top->v__DOT__uart_sim__DOT__we_l)&
            (verilator_top->v__DOT__uart_sim__DOT__addr_l==2)&
            (verilator_top->v__DOT__uart_sim__DOT__d_l==0x06))){
      eval(verilator_top, tfp);
    }
    block++;
  }
  //// send EOT ////
  while(verilator_top->v__DOT__uart_sim__DOT__empty_o==0){
    eval(verilator_top, tfp);
  }
  verilator_top->v__DOT__uart_sim__DOT__dout_o = 0x04;
  verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
  verilator_top->v__DOT__uart_sim__DOT__cnt = 3;
  //// wait ACK ////
  while(!((verilator_top->v__DOT__uart_sim__DOT__req_l)&
          (verilator_top->v__DOT__uart_sim__DOT__we_l)&
          (verilator_top->v__DOT__uart_sim__DOT__addr_l==2)&
          (verilator_top->v__DOT__uart_sim__DOT__d_l==0x06))){
    eval(verilator_top, tfp);
  }

  return;
}

int main(int argc, char **argv, char **env) {
  
  int c;
  int digit_optind = 0;
  char vcdfile[VCD_PATH_LENGTH] = "";

  while (1) {
    int this_option_optind = optind ? optind : 1;
    int option_index = 0;
    static struct option long_options[] = {
      {"vcdfile" , required_argument, 0,  'f' },
      {"vcdstart", required_argument, 0,  's' },
      {"vcdend"  , required_argument, 0,  'e' },
      {0,          0,                 0,  0 }
    };

    c = getopt_long(argc, argv, "",
                    long_options, &option_index);
    if (c == -1)
      break;
    
    switch (c) {
    case 'f':
      if (optarg)
        strncpy(vcdfile,optarg,VCD_PATH_LENGTH);
      break;
    case 's':
      if (optarg)
        sscanf(optarg,"%d",&vcdstart);
      break;
    case 'e':
      if (optarg)
        sscanf(optarg,"%d",&vcdend);
      break;
    default:
      break;
    }
  }

  Verilated::commandArgs(argc, argv);
  Verilated::traceEverOn(true);
  VerilatedVcdC* tfp = new VerilatedVcdC;
  Vzeroriscy_verilator_top* verilator_top = new Vzeroriscy_verilator_top;
  verilator_top->trace(tfp, 99); // requires explicit max levels param
  tfp->open(vcdfile);

  FILE *fd;
  int  i;
  char str[256];
  char data[64];
  int  bytec, addr, base, rtype, op;

  fd = fopen("./loadmem.ihex","r");
  if( fd == NULL ){
    printf("ERROR!! loadmem.ihex not found\n");
    return -1;
  }

  base=0;
  while(fgets(str, sizeof(str), fd)){
    sscanf(str, ":%2x%4x%2x%s", &bytec, &addr, &rtype, data);
    if(rtype==0 &&
        (bytec == 16 || bytec == 12 || bytec == 8 || bytec == 4)){
      for(i=0; i<bytec/4; i = i+1){
        sscanf(data, "%8x%s", &op, data);
        if(base&0x100000){
          verilator_top->v__DOT__DUT__DOT__zeroriscy_d_sram__DOT__dmem[((base%0x40000)+addr)/4+i] =
            ((op&0x0ff)<<24)|(((op>>8)&0x0ff)<<16)|(((op>>16)&0x0ff)<<8)|((op>>24)&0x0ff);
        } else if(base&0x080000){
          verilator_top->v__DOT__DUT__DOT__zeroriscy_i_sram__DOT__imem[addr/4+i] =
            ((op&0x0ff)<<24)|(((op>>8)&0x0ff)<<16)|(((op>>16)&0x0ff)<<8)|((op>>24)&0x0ff);
        }else{
          verilator_top->v__DOT__DUT__DOT__zeroriscy_i_sram__DOT__bmem[addr/4+i] =
            ((op&0x0ff)<<24)|(((op>>8)&0x0ff)<<16)|(((op>>16)&0x0ff)<<8)|((op>>24)&0x0ff);
        }
      }
    }else if ((rtype==4)){
      sscanf(data, "%4x%s", &addr, data);
      base = (addr%0x20)*0x10000;
    }else if ((rtype==3)|(rtype==5)){
    }else if (rtype==1){
      printf("Running ...\n");
    }else{
      printf("ERROR!! Not support ihex format\n");
      printf("%s\n",str);
      return -1;
    }
  }

  int keyin, load;
  system("stty -echo -icanon min 1 time 0"); // Unix
  while (!Verilated::gotFinish()) {
    // reset
    verilator_top->reset = (main_time < 1000) ? 1 : 0;
    // if putc
    if((verilator_top->v__DOT__uart_sim__DOT__req_l)&
       (verilator_top->v__DOT__uart_sim__DOT__we_l)&
       (verilator_top->v__DOT__uart_sim__DOT__addr_l==2)){
      putc((char)verilator_top->v__DOT__uart_sim__DOT__d_l, stdout);
    }
    // if getc
    if((verilator_top->v__DOT__uart_sim__DOT__req_l)&
       (~verilator_top->v__DOT__uart_sim__DOT__we_l)&
       (verilator_top->v__DOT__uart_sim__DOT__cnt==0)&
       (verilator_top->v__DOT__uart_sim__DOT__addr_l==1)){
      keyin = getc(stdin);  // Unix
      //keyin = getch(); // Windows
      keyin = (keyin=='\n') ? '\r' : keyin;
      if(keyin=='q'){printf("q\n");break;} // finish
      verilator_top->v__DOT__uart_sim__DOT__dout_o = keyin;
      verilator_top->v__DOT__uart_sim__DOT__empty_o = 0;
      verilator_top->v__DOT__uart_sim__DOT__cnt = 3;
      if(keyin=='l'){load=1;}
      else if((keyin=='o') &(load==1)){load=2;}
      else if((keyin=='a') &(load==2)){load=3;}
      else if((keyin=='d') &(load==3)){load=4;}
      else if((keyin=='\r')&(load==4)){xmodem(verilator_top, tfp);load=0;}
      else {load=0;}
    }
    // @(negedge clk)
    eval(verilator_top, tfp);
  }
  delete verilator_top;
  tfp->close();
  system("stty echo -icanon min 1 time 0"); // Unix
  exit(0);
}

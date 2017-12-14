#include "unistd.h"
#include "getopt.h"
#include "Vzeroriscy_verilator_top.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

#define VCD_PATH_LENGTH 256

int main(int argc, char **argv, char **env) {
  
  int c;
  int digit_optind = 0;
  char vcdfile[VCD_PATH_LENGTH];

  strncpy(vcdfile,"tmp.vcd",VCD_PATH_LENGTH);


  while (1) {
    int this_option_optind = optind ? optind : 1;
    int option_index = 0;
    static struct option long_options[] = {
      {"vcdfile", required_argument, 0,  0 },
      {0,         0,                 0,  0 }
    };

    c = getopt_long(argc, argv, "",
                    long_options, &option_index);
    if (c == -1)
      break;
    
    switch (c) {
    case 0:
      if (optarg)
        strncpy(vcdfile,optarg,VCD_PATH_LENGTH);
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

  while(fgets(str, sizeof(str), fd)){
    sscanf(str, ":%2x%4x%2x%s", &bytec, &addr, &rtype, data);
    if(rtype==0 &&
        (bytec == 16 || bytec == 12 || bytec == 8 || bytec == 4)){
      for(i=0; i<bytec/4; i = i+1){
        sscanf(data, "%8x%s", &op, data);
        if(base>0x100000){
          verilator_top->v__DOT__DUT__DOT__zeroriscy_dp_sram__DOT__mem[((base%0x40000)+addr)/4+i] =
            ((op&0x0ff)<<24)|(((op>>8)&0x0ff)<<16)|(((op>>16)&0x0ff)<<8)|((op>>24)&0x0ff);
        }else{
          verilator_top->v__DOT__DUT__DOT__zeroriscy_dp_sram__DOT__imem[addr/4+i] =
            ((op&0x0ff)<<24)|(((op>>8)&0x0ff)<<16)|(((op>>16)&0x0ff)<<8)|((op>>24)&0x0ff);
        }
      }
    }else if ((rtype==4)){
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

  vluint64_t main_time = 0;
  while (!Verilated::gotFinish()) {
    verilator_top->reset = (main_time < 1000) ? 1 : 0;
    if (main_time % 100 == 0)
      verilator_top->clk = 0;
    if (main_time % 100 == 50)
      verilator_top->clk = 1;
    verilator_top->eval();
    tfp->dump(main_time);
    main_time += 50;
  }
  delete verilator_top;
  tfp->close();
  exit(0);
}

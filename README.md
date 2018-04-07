# zero-riscy test-env

## MEM MAP
| Address  | Real Size | Full Size | Area                 |
| :-       | :-        | :-        | :-                   |
| 00000000 | 0         | 2GB       | DRAM?                |
| 80000000 | 16KB      | 512KB     | Boot                 |
| 80080000 | 16KB      | 512KB     | Instruction          |
| 80100000 | 128KB     | 1M        | Data                 |
| 80200000 | 0         | ?         | ?                    |
|          |           |           |                      |
| 8017fffc | 1B        | 1B        | htif                 |
| 9a100004 | 1B        | 1B        | char out for sim     |
| 9a100100 | 16B       | 16B       | File Access for sim  |
| 9a101000 | 16B       | 16B       | UART Lite for ArtyA7 |
| 9a102000 | 28B       | 28B       | SD Card Controller   |
| e0000000 | 48B       | 48B       | PS UART for ArtyZ7   |

## Verilator sim option
for waveform
- --vcdfile=```FILENAME```
- --vcdstart=```STARTTIME```
- --vcdend=```ENDTIME```

If verilator 3.882 or earlier, remove "--l2-name v" option in Makefile

## run puts test @ ModelSim

In order to build and test "Hello world",
ModelSim must be installed and on the path.  
check ```OBJS  = startup.o main.o``` line in Makefile

```
cd ${zero-riscy-test}/src/main/c
make
cd ${zero-riscy-test}
make modelsim-sim
cp src/main/c/estimate.ihex loadmem.ihex
vsim.exe -c work.zeroriscy_hex_tb -lib work -do " \
        add wave -noupdate /zeroriscy_hex_tb/* -recursive; \
        add wave -noupdate /zeroriscy_hex_tb/DUT/zeroriscy_core/id_stage_i/registers_i/mem; \
        run 30ns; quit"
```
Result
```
# Hello !!
#
# zero riscy world
#
# *** PASSED *** after                  535 simulation cycles
```

## run estimate test @ Verilator

verilator 3.884 or lator must be installed and on the path.  
check ```OBJS  = startup.o estimate.o bnn.o``` line in Makefile

```
cd ${zero-riscy-test}/src/main/c
make
cd ${zero-riscy-test}
make verilator-sim
cp src/main/c/estimate.ihex loadmem.ihex
./sim/Vzeroriscy_verilator_top
```

Result

```
Approximate....
== Pass Count :  0000001 ==
Approximate....
-0557870, -0318241, -0370820,  1270316, -1070926,  0682038,  0757464, -0834358,  0524606,  0090144,
*** PASSED *** after              4071178 simulation cycles
```

## run kozos boot load test @ Verilator

verilator 3.884 or lator must be installed and on the path.  

```
cd ${zero-riscy-test}/src/main/kozos/bootload
make
cd ${zero-riscy-test}/src/main/kozos/os
make
cd ${zero-riscy-test}
make verilator-board-test
```

Result @ XMODEM

```
cp src/main/kozos/bootload/kzload.ihex loadmem.ihex
cp src/main/kozos/os/kozos xmodem.dat
sim/Vzeroriscy_verilator_top --vcdfile=board.vcd
Running ...
kzload (kozos boot loader) started.
kzload> load <- type
XMODEM receive succeeded.
kzload> run <- type
starting from entry point: 80080000
Hello World!
> echo aaa <- type
 aaa
> q
```

Result @ SD CARD

```
cp src/main/kozos/bootload/kzload.ihex loadmem.ihex
cp src/main/kozos/os/kozos sdcard/
sim/Vzeroriscy_verilator_top --vcdfile=board.vcd
Running ...
kzload (kozos boot loader) started.
kzload> run kozos <- type
starting from entry point: 80080000
Hello World!
> echo aaa <- type
 aaa
> q
```

## run kozos boot load test @ ARTY A7 FPGA

```
cd ${zero-riscy-test}/src/main/kozos/bootload
make UART=uartlite
cd ${zero-riscy-test}/src/main/kozos/os
make UART=uartlite
```

### convert rom data

```
cd ${zero-riscy-test}/src/fpga/verilog/
./ramcnv.pl ../../main/kozos/bootload/kzload.ihex
```

### Build, program FPGA

remove vivado work files ```git clean -xdf fpga/ARTYA7/project_2/```  
open ```fpga/ARTYA7/project_2/project_2.xpr``` by vivado, and ....

### set serial terminal

```
19200 bps
data 8bit
parity none
stop 1bit
flow none
```

## run kozos boot load test @ ARTY Z7 FPGA

```
cd ${zero-riscy-test}/src/main/kozos/bootload
make UART=ps7
cd ${zero-riscy-test}/src/main/kozos/os
make UART=ps7
```

### convert rom data

```
cd ${zero-riscy-test}/src/fpga/verilog/
./ramcnv.pl ../../main/kozos/bootload/kzload.ihex
```

### Build, ~~program~~ FPGA

remove vivado work files ```git clean -xdf fpga/ARTYZ7/project_1/```  
open ```fpga/ARTYZ7/project_1/project_1.xpr``` by vivado, and ....

### set serial terminal

```
19200 bps
data 8bit
parity none
stop 1bit
flow none
```

### init PS and program FPGA

```
cd ${zero-riscy-test}/fpga/ARTYZ7
c:\Xilinx\SDK\2017.4\bin\xsct.bat ps7_init.xsc
```

## run isa test
### @ ModelSim
In order to build and test zero-riscy using the supplied makefile,  
ModelSim must be installed and on the path.
```
cd ${zero-riscy-test}
make modelsim-sim
make modelsim-run-asm-tests
```

### @ verilator
or verilator 3.884 or lator must be installed and on the path.
```
cd ${zero-riscy-test}
make verilator-sim
make verilator-run-asm-tests
```

This simulation environment is based on v-scale.

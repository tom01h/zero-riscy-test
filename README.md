# zero-riscy test-env

## MEM MAP
| Address  | Size  | Area        |
| :-       | :-    | :-          |
| 80000000 | 16KB  | Boot        |
| 80080000 | 16KB  | Instruction |
| 80100000 | 128KB | Data        |
| 8017fffc | 1B    | htif        |
| 9a100000 | 1B    | char out    |

## run puts test

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
        add wave -noupdate /zeroriscy_hex_tb/DUT/zeroriscy_dp_sram/mem; \
        run 30ns; quit"
```
Result
```
abad1dea Hello !!
zero riscy world
*** PASSED *** after                 1489 simulation cycles
```

## run estimate test

verilator 3.884 or lator must be installed and on the path.  
check ```OBJS  = startup.o estimate.o``` line in Makefile

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
-0258598, -0555011, -0176046,  1085366, -1230738,  0751510,  0515738, -0362938,  0093014,  0206960,

== Pass Count :  0000001 ==
*** PASSED *** after             26725130 simulation cycles
```

## run isa test
In order to build and test zero-riscy using the supplied makefile,  
ModelSim must be installed and on the path.
```
cd ${zero-riscy-test}
make modelsim-sim
make modelsim-run-asm-tests
```

or verilator 3.884 or lator must be installed and on the path.
```
cd ${zero-riscy-test}
make verilator-sim
make verilator-run-asm-tests
```
If verilator 3.882 or earlier, remove "--l2-name v" option in Makefile

This simulation environment is based on v-scale.

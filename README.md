# zero-riscy test-env

## MEM MAP
| Address  | Size  | Area        |
| :-       | :-    | :-          |
| 80000000 | 16KB  | Instruction |
| 80100000 | 512KB | Data        |
| 8017fffc | 1B    | htif        |
| 9a100000 | 1B    | char out    |

## run puts test

In order to build and test "Hello world",
ModelSim must be installed and on the path.
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

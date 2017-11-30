# zero-riscy isa-test-env

In order to build and test zero-riscy using the supplied makefile,  
ModelSim must be installed and on the path.
```
cd vscale
make modelsim-sim
make modelsim-run-asm-tests
```
or verilator 3.884 or lator must be installed and on the path.
```
cd vscale
make verilator-sim
make verilator-run-asm-tests
```
If verilator 3.882 or earlier, remove "--l2-name v" option in Makefile

This simulation environment is based on v-scale.

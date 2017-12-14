SHELL = /bin/bash

include Makefrag

V_SRC_DIR = src/main/zero-riscy

V_TEST_DIR = src/test/verilog

CXX_TEST_DIR = src/test/cxx

SIM_DIR = sim

MEM_DIR = src/test/inputs

OUT_DIR = output

MODELSIM_DIR = work

VLOG = vlog.exe
VLOG_OPTS = +incdir+$(V_SRC_DIR)/include
VLIB = vlib.exe
VSIM = vsim.exe
VSIM_OPTS = -c work.zeroriscy_hex_tb -lib work -do " \
	add wave -noupdate /zeroriscy_hex_tb/* -recursive; \
	run 30ns; quit"

VERILATOR = verilator

VERILATOR_OPTS = \
	-Wall \
	-Wno-WIDTH \
	-Wno-UNUSED \
	-Wno-BLKSEQ \
	--cc \
	-I$(V_SRC_DIR)/include \
	-I$(V_TEST_DIR) \
	+1364-2001ext+v \
	-Wno-fatal \
	--Mdir sim \
	--trace \
	--l2-name v \

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

MAX_CYCLES = 10000

SIMV_OPTS = -k $(OUT_DIR)/ucli.key -q

DESIGN_SRCS = $(addprefix $(V_SRC_DIR)/, \
include/zeroriscy_defines.sv \
include/zeroriscy_tracer_defines.sv \
cluster_clock_gating.sv \
zeroriscy_alu.sv \
zeroriscy_compressed_decoder.sv \
zeroriscy_controller.sv \
zeroriscy_cs_registers.sv \
zeroriscy_debug_unit.sv \
zeroriscy_decoder.sv \
zeroriscy_int_controller.sv \
zeroriscy_ex_block.sv \
zeroriscy_id_stage.sv \
zeroriscy_if_stage.sv \
zeroriscy_load_store_unit.sv \
zeroriscy_multdiv_slow.sv \
zeroriscy_multdiv_fast.sv \
zeroriscy_prefetch_buffer.sv \
zeroriscy_register_file.sv \
zeroriscy_tracer.sv \
zeroriscy_fetch_fifo.sv \
zeroriscy_core.sv \
)

SIM_SRCS = $(addprefix $(V_TEST_DIR)/, \
zeroriscy_sim_top.sv \
zeroriscy_dp_sram.sv \
)

VERILATOR_CPP_TB = $(CXX_TEST_DIR)/zeroriscy_hex_tb.cpp

VERILATOR_TOP = $(V_TEST_DIR)/zeroriscy_verilator_top.sv

MODELSIM_TOP = $(V_TEST_DIR)/zeroriscy_hex_tb_modelsim.sv

HDRS = $(addprefix $(V_SRC_DIR)/include/, \
zeroriscy_config.sv \
)

VERILATOR_VCD_FILES = $(addprefix $(OUT_DIR)/,$(addsuffix .verilator.vcd,$(RV32_TESTS)))

MODELSIM_WLF_FILES = $(addprefix $(OUT_DIR)/,$(addsuffix .wlf,$(RV32_TESTS)))

default: modelsim-sim

verilator-sim: $(SIM_DIR)/Vzeroriscy_verilator_top

verilator-run-asm-tests: $(VERILATOR_VCD_FILES)

modelsim-sim: $(MODELSIM_DIR) $(MODELSIM_DIR)/_vmake

modelsim-run-asm-tests: $(MODELSIM_WLF_FILES)

$(OUT_DIR)/%.verilator.vcd: $(MEM_DIR)/%.ihex $(SIM_DIR)/Vzeroriscy_verilator_top
	mkdir -p output
	cp $< loadmem.ihex
	$(SIM_DIR)/Vzeroriscy_verilator_top +max-cycles=$(MAX_CYCLES) --vcdfile=$@ > log
	mv log $@.log
	mv trace.log $@.trc

$(OUT_DIR)/%.wlf: $(MEM_DIR)/%.ihex $(MODELSIM_DIR)/_vmake
	mkdir -p output
	cp $< loadmem.ihex
	$(VSIM) $(VSIM_OPTS)
	mv transcript $@.log
	mv vsim.wlf $@
	mv trace_core_00_0.log $@.trc

$(SIM_DIR)/Vzeroriscy_verilator_top: $(VERILATOR_TOP) $(SIM_SRCS) $(DESIGN_SRCS) $(HDRS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SIM_SRCS) $(DESIGN_SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vzeroriscy_verilator_top.mk Vzeroriscy_verilator_top__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vzeroriscy_verilator_top.mk Vzeroriscy_verilator_top

$(MODELSIM_DIR):
	$(VLIB) $(MODELSIM_DIR)

$(MODELSIM_DIR)/_vmake: $(MODELSIM_TOP) $(SIM_SRCS) $(DESIGN_SRCES) $(HDRS) $(MODELSIM_DIR)
	$(VLOG) $(VLOG_OPTS) $(MODELSIM_TOP) $(SIM_SRCS) $(DESIGN_SRCS)

clean:
	rm -rf $(SIM_DIR)/* $(OUT_DIR)/* $(MODELSIM_DIR) wlft*

.PHONY: clean run-asm-tests verilator-run-asm-tests

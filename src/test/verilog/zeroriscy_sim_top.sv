
module zeroriscy_sim_top
  (
   input clk,
   input reset
   );

   // Instruction memory interface
   logic        instr_req;
   logic        instr_gnt;
   logic        instr_rvalid;
   logic [31:0] instr_addr;
   logic [31:0] instr_rdata;

   // Data memory interface
   logic        data_req;
   logic        data_gnt;
   logic        data_rvalid;
   logic        data_we;
   logic [3:0]  data_be;
   logic [31:0] data_addr;
   logic [31:0] data_wdata;
   logic [31:0] data_rdata;
   logic        data_err;

   zeroriscy_core
     #(
       .N_EXT_PERF_COUNTERS(0),
       .RV32E(0),
       .RV32M(1)
       )
   zeroriscy_core
     (
      // Clock and Reset
      .clk_i(clk),
      .rst_ni(~reset),

      .clock_en_i(1'b1),    // enable clock, otherwise it is gated
      .test_en_i(1'b0),     // enable all clock gates for testing

      // Core ID, Cluster ID and boot address are considered more or less static
      .core_id_i(4'h0),//[ 3:0]
      .cluster_id_i(6'h00),//[ 5:0]
      .boot_addr_i(32'h80000000),//[31:0]

      // Instruction memory interface
      .instr_req_o(instr_req),
      .instr_gnt_i(instr_gnt),
      .instr_rvalid_i(instr_rvalid),
      .instr_addr_o(instr_addr[31:0]),
      .instr_rdata_i(instr_rdata[31:0]),

      // Data memory interface
      .data_req_o(data_req),
      .data_gnt_i(data_gnt),
      .data_rvalid_i(data_rvalid),
      .data_we_o(data_we),
      .data_be_o(data_be[3:0]),
      .data_addr_o(data_addr[31:0]),
      .data_wdata_o(data_wdata[31:0]),
      .data_rdata_i(data_rdata[31:0]),
      .data_err_i(data_err),

      // Interrupt inputs
      .irq_i(1'b0),                 // level sensitive IR lines
      .irq_id_i(5'h00),//[4:0]
      .irq_ack_o(),             // irq ack
      .irq_id_o(),//[4:0]

      // Debug Interface
      .debug_req_i(1'b0),
      .debug_gnt_o(),
      .debug_rvalid_o(),
      .debug_addr_i(0),//[14:0]
      .debug_we_i(1'b0),
      .debug_wdata_i(0),//[31:0]
      .debug_rdata_o(),//[31:0]
      .debug_halted_o(),
      .debug_halt_i(1'b0),
      .debug_resume_i(1'b0),

      // CPU Control Signals
      .fetch_enable_i(1'b1),
      .core_busy_o(),

      .ext_perf_counters_i(0)//[N_EXT_PERF_COUNTERS-1:0]
      );


   zeroriscy_dp_sram zeroriscy_dp_sram
     (
      .clk(clk),
      .rst_n(~reset),

      .p0_req(data_req),
      .p0_we(data_we),
      .p0_be(data_be[3:0]),
      .p0_addr(data_addr[31:0]),
      .p0_wdata(data_wdata[31:0]),
      .p0_rdata(data_rdata[31:0]),
      .p0_gnt(data_gnt),
      .p0_rvalid(data_rvalid),
      .p0_err(data_err),

      .p1_req(instr_req),
      .p1_we(1'b0),
      .p1_be(4'h0),
      .p1_addr(instr_addr[31:0]),
      .p1_wdata(32'h0),
      .p1_rdata(instr_rdata[31:0]),
      .p1_gnt(instr_gnt),
      .p1_rvalid(instr_rvalid),
      .p1_err()
   );

endmodule

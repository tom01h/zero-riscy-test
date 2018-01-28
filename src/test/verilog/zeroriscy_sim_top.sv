
module zeroriscy_sim_top
  (
   input logic         clk,
   input logic         reset,

   output logic        ss_req,
   output logic        ss_we,
   output logic [3:0]  ss_be,
   output logic [31:0] ss_addr,
   output logic [31:0] ss_wdata,
   input logic [31:0]  ss_rdata
   );

   // Instruction memory interface
   logic        instr_req;
   logic [31:0] instr_addr;
   logic [31:0] instr_rdata;
   logic        instr_rvalid;

   // Data memory interface
   logic        data_req;
   logic        data_we;
   logic [3:0]  data_be;
   logic [31:0] data_addr;
   logic [31:0] data_wdata;
   logic [31:0] data_rdata;
   logic        data_rvalid;

   // Instruction memory interface
   logic        is_req;
   logic        is_we;
   logic [3:0]  is_be;
   logic [31:0] is_addr;
   logic [31:0] is_wdata;
   logic [31:0] is_rdata;

   // Data memory interface
   logic        ds_req;
   logic        ds_we;
   logic [3:0]  ds_be;
   logic [31:0] ds_addr;
   logic [31:0] ds_wdata;
   logic [31:0] ds_rdata;

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
      .debug_addr_i(15'h0),//[14:0]
      .debug_we_i(1'b0),
      .debug_wdata_i(0),//[31:0]
      .debug_rdata_o(),//[31:0]
      .debug_halted_o(),
      .debug_halt_i(1'b0),
      .debug_resume_i(1'b0),

      // CPU Control Signals
      .fetch_enable_i(1'b1),
      .core_busy_o(),

      .ext_perf_counters_i(2'b00)//[N_EXT_PERF_COUNTERS-1:0]
      );


   zeroriscy_xbar zeroriscy_xbar
     (
      .clk(clk),
      .resetn(~reset),

      .im_req(instr_req),
      .im_gnt(instr_gnt),
      .im_rvalid(instr_rvalid),
      .im_addr(instr_addr[31:0]),
      .im_rdata(instr_rdata[31:0]),
      .im_err(),

      .dm_req(data_req),
      .dm_gnt(data_gnt),
      .dm_rvalid(data_rvalid),
      .dm_we(data_we),
      .dm_be(data_be[3:0]),
      .dm_addr(data_addr[31:0]),
      .dm_wdata(data_wdata[31:0]),
      .dm_rdata(data_rdata[31:0]),
      .dm_err(data_err),

      .is_req(is_req),
      .is_we(is_we),
      .is_be(is_be),
      .is_addr(is_addr[31:0]),
      .is_wdata(is_wdata),
      .is_rdata(is_rdata[31:0]),
      .is_err(1'b0),

      .ds_req(ds_req),
      .ds_we(ds_we),
      .ds_be(ds_be[3:0]),
      .ds_addr(ds_addr[31:0]),
      .ds_wdata(ds_wdata[31:0]),
      .ds_rdata(ds_rdata[31:0]),
      .ds_err(1'b0),

      .ss_req(ss_req),
      .ss_we(ss_we),
      .ss_be(ss_be[3:0]),
      .ss_addr(ss_addr[31:0]),
      .ss_wdata(ss_wdata[31:0]),
      .ss_rdata(ss_rdata[31:0]),
      .ss_err(1'b0)
   );

   zeroriscy_d_sram zeroriscy_d_sram
     (
      .clk(clk),
      .rst_n(~reset),

      .p_req(ds_req),
      .p_we(ds_we),
      .p_be(ds_be[3:0]),
      .p_addr(ds_addr[31:0]),
      .p_wdata(ds_wdata[31:0]),
      .p_rdata(ds_rdata[31:0]),
      .p_gnt(),
      .p_rvalid(),
      .p_err()
   );

   zeroriscy_i_sram zeroriscy_i_sram
     (
      .clk(clk),
      .rst_n(~reset),

      .p_req(is_req),
      .p_we(is_we),
      .p_be(is_be[3:0]),
      .p_addr(is_addr[31:0]),
      .p_wdata(is_wdata),
      .p_rdata(is_rdata[31:0]),
      .p_gnt(),
      .p_rvalid(),
      .p_err()
   );

endmodule


module zeroriscy_sim_top
  (
   input logic        clk,
   input logic        reset,

   ////////////////////////////////////////////////////////////////////////////
   // Master Interface Write Address
   output wire [31:0] M_AXI_AWADDR,
   output wire [7:0]  M_AXI_AWLEN,
   output wire [2:0]  M_AXI_AWSIZE,
   output wire [1:0]  M_AXI_AWBURST,
   output wire [3:0]  M_AXI_AWCACHE,

   output wire        M_AXI_AWVALID,
   input wire         M_AXI_AWREADY,

   ////////////////////////////////////////////////////////////////////////////
   // Master Interface Write Data
   output wire [31:0] M_AXI_WDATA,
   output wire [3:0]  M_AXI_WSTRB,
   output wire        M_AXI_WLAST,
   output wire        M_AXI_WVALID,
   input wire         M_AXI_WREADY,

   ////////////////////////////////////////////////////////////////////////////
   // Master Interface Write Response
   input wire [1:0]   M_AXI_BRESP,
   input wire         M_AXI_BVALID,
   output wire        M_AXI_BREADY,

   ////////////////////////////////////////////////////////////////////////////
   // Master Interface Read Address
   output wire [31:0] M_AXI_ARADDR,
   output wire [7:0]  M_AXI_ARLEN,
   output wire [2:0]  M_AXI_ARSIZE,
   output wire [1:0]  M_AXI_ARBURST,
   output wire [3:0]  M_AXI_ARCACHE,

   output wire        M_AXI_ARVALID,
   input wire         M_AXI_ARREADY,

   ////////////////////////////////////////////////////////////////////////////
   // Master Interface Read Data
   input wire [31:0]  M_AXI_RDATA,
   input wire [1:0]   M_AXI_RRESP,
   input wire         M_AXI_RLAST,
   input wire         M_AXI_RVALID,
   output wire        M_AXI_RREADY
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

   // System interface
   logic        ss_req;
   logic        ss_we;
   logic [3:0]  ss_be;
   logic [31:0] ss_addr;
   logic [31:0] ss_wdata;
   logic [31:0] ss_rdata;
   logic        ss_gnt;
   logic        ss_rvalid;

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
      .ss_gnt(ss_gnt),
      .ss_rvalid(ss_rvalid),
      .ss_err(1'b0)
   );

//TEMP//TEMP//
   wire [31:0] ds_rdata_d, ds_rdata_bn;
   reg         ds_reql_d;
   always @ (posedge clk)begin
      ds_reql_d  <= ds_req&({ds_addr[31:19],3'h0}==16'h8010);
   end
   assign ds_rdata = (ds_reql_d) ? ds_rdata_d : ds_rdata_bn ;
   zeroriscy_d_sram zeroriscy_d_sram
     (
      .clk(clk),
      .rst_n(~reset),

      .p_req(ds_req&({ds_addr[31:19],3'h0}==16'h8010)),//TEMP//TEMP//
      .p_we(ds_we),
      .p_be(ds_be[3:0]),
      .p_addr(ds_addr[31:0]),
      .p_wdata(ds_wdata[31:0]),
      .p_rdata(ds_rdata_d[31:0]),
      .p_gnt(),
      .p_rvalid(),
      .p_err()
   );

   zeroriscy_mem_bnn zeroriscy_mem_bnn
     (
      .clk(clk),
      .rst_n(~reset),

      .p_req(ds_req&({ds_addr[31:19],3'h0}==16'h8018)),//TEMP//TEMP//
      .p_we(ds_we),
      .p_be(ds_be[3:0]),
      .p_addr(ds_addr[31:0]),
      .p_wdata(ds_wdata[31:0]),
      .p_rdata(ds_rdata_bn[31:0]),
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

   core2axi
     #(
       .AXI4_ADDRESS_WIDTH(32),
       .AXI4_RDATA_WIDTH(32),
       .AXI4_WDATA_WIDTH(32),
       .AXI4_ID_WIDTH(1),
       .AXI4_USER_WIDTH(1),
       .REGISTERED_GRANT("TRUE") // "TRUE"|"FALSE"
       )
   core2axi
     (
      // Clock and Reset
      .clk_i(clk),
      .rst_ni(~reset),

      .data_req_i(ss_req),
      .data_gnt_o(ss_gnt),
      .data_rvalid_o(ss_rvalid),
      .data_addr_i(ss_addr[31:0]),
      .data_we_i(ss_we),
      .data_be_i(ss_be[3:0]),
      .data_rdata_o(ss_rdata[31:0]),
      .data_wdata_i(ss_wdata[31:0]),

      // -----------------------------------
      // AXI TARG Port Declarations --------
      // -----------------------------------
      //AXI write address bus --------------
      .aw_id_o(),
      .aw_addr_o(M_AXI_AWADDR[31:0]),
      .aw_len_o(M_AXI_AWLEN[7:0]),
      .aw_size_o(M_AXI_AWSIZE[2:0]),
      .aw_burst_o(M_AXI_AWBURST[1:0]),
      .aw_lock_o(),
      .aw_cache_o(M_AXI_AWCACHE[3:0]),
      .aw_prot_o(),
      .aw_region_o(),
      .aw_user_o(),
      .aw_qos_o(),
      .aw_valid_o(M_AXI_AWVALID),
      .aw_ready_i(M_AXI_AWREADY),
      // -----------------------------------

      //AXI write data bus -----------------
      .w_data_o(M_AXI_WDATA[31:0]),
      .w_strb_o(M_AXI_WSTRB[3:0]),
      .w_last_o(M_AXI_WLAST),
      .w_user_o(),
      .w_valid_o(M_AXI_WVALID),
      .w_ready_i(M_AXI_WREADY),
      // -----------------------------------

      //AXI write response bus -------------
      .b_id_i(),
      .b_resp_i(M_AXI_BRESP[1:0]),
      .b_valid_i(M_AXI_BVALID),
      .b_user_i(),
      .b_ready_o(M_AXI_BREADY),
      // -----------------------------------

      //AXI read address bus ---------------
      .ar_id_o(),
      .ar_addr_o(M_AXI_ARADDR[31:0]),
      .ar_len_o(M_AXI_ARLEN[7:0]),
      .ar_size_o(M_AXI_ARSIZE[2:0]),
      .ar_burst_o(M_AXI_ARBURST[1:0]),
      .ar_lock_o(),
      .ar_cache_o(M_AXI_ARCACHE[3:0]),
      .ar_prot_o(),
      .ar_region_o(),
      .ar_user_o(),
      .ar_qos_o(),
      .ar_valid_o(M_AXI_ARVALID),
      .ar_ready_i(M_AXI_ARREADY),
      // -----------------------------------

      //AXI read data bus ------------------
      .r_id_i(),
      .r_data_i(M_AXI_RDATA[31:0]),
      .r_resp_i(M_AXI_RRESP[1:0]),
      .r_last_i(M_AXI_RLAST),
      .r_user_i(),
      .r_valid_i(M_AXI_RVALID),
      .r_ready_o(M_AXI_RREADY)
      // ---------------------------------------------------------
      );

endmodule

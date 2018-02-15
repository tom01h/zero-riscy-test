
module zeroriscy_fpga_top
  (
   input  clk,
   input  rstn,
   input  RXD,
   output TXD
   );

   wire   reset = ~rstn;

   logic         ss_req;
   logic         ss_we;
   logic [3:0]   ss_be = 4'b0001;
   logic [31:0]  ss_addr;
   logic [31:0]  ss_wdata;
   logic [31:0]  ss_rdata;

   logic         rreq;
   logic         wreq;
   logic         rvalid;
   logic         bvalid;

   always @ (posedge clk)begin
      rvalid <= rreq;
      bvalid <= wreq;
   end

   logic [31:0]  raddr;
   logic [31:0]  waddr;

   assign ss_addr = (ss_we) ? waddr : raddr;
   assign ss_req  = rreq|wreq;
   assign ss_we   =      wreq;

   zeroriscy_sim_top DUT
     (
      .clk(clk),
      .reset(reset),
      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Address
      .M_AXI_AWADDR(waddr),
      .M_AXI_AWLEN(),
      .M_AXI_AWSIZE(),
      .M_AXI_AWBURST(),
      .M_AXI_AWCACHE(),
      .M_AXI_AWVALID(wreq),
      .M_AXI_AWREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Data
      .M_AXI_WDATA(ss_wdata),
      .M_AXI_WSTRB(),
      .M_AXI_WLAST(),
      .M_AXI_WVALID(),
      .M_AXI_WREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Response
      .M_AXI_BRESP(2'b00),
      .M_AXI_BVALID(bvalid),
      .M_AXI_BREADY(),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Read Address
      .M_AXI_ARADDR(raddr),
      .M_AXI_ARLEN(),
      .M_AXI_ARSIZE(),
      .M_AXI_ARBURST(),
      .M_AXI_ARCACHE(),
      .M_AXI_ARVALID(rreq),
      .M_AXI_ARREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Read Data
      .M_AXI_RDATA(ss_rdata),
      .M_AXI_RRESP(),
      .M_AXI_RLAST(),
      .M_AXI_RVALID(rvalid),
      .M_AXI_RREADY()
      );

   uart uart
     (
      .clk(clk),
      .resetn(~reset),

      .req(ss_req & (ss_addr[31:4]==28'h9a10_001)),
      .addr(ss_addr[31:0]),
      .we(ss_we),
      .be(ss_be[3:0]),
      .wdata(ss_wdata),
      .rdata(ss_rdata[31:0]),
      .gnt(),
      .rvalid(),
      .err(),
      .RXD(RXD),
      .TXD(TXD)
   );

endmodule

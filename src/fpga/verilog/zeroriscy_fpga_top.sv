
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
   logic [3:0]   ss_be;
   logic [31:0]  ss_addr;
   logic [31:0]  ss_wdata;
   logic [31:0]  ss_rdata;

   zeroriscy_sim_top DUT
     (
      .clk(clk),
      .reset(reset),
      .ss_req(ss_req),
      .ss_addr(ss_addr[31:0]),
      .ss_we(ss_we),
      .ss_be(ss_be[3:0]),
      .ss_wdata(ss_wdata),
      .ss_rdata(ss_rdata[31:0])
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

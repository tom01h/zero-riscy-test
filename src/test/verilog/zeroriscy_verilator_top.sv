
module zeroriscy_verilator_top
  (
   input clk,
   input reset
   );

   logic [255:0] reason = 0;
   logic [63:0]  trace_count = 0;

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

   uart_sim uart_sim
     (
      .clk(clk),
      .resetn(~reset),

      .req(ss_req & (ss_addr[31:4]==28'h9a10_000)),
      .addr(ss_addr[31:0]),
      .we(ss_we),
      .be(ss_be[3:0]),
      .wdata(ss_wdata),
      .rdata(ss_rdata[31:0]),
      .gnt(),
      .rvalid(),
      .err()
   );

   initial begin
      reason = 0;
      trace_count = 0;
   end // initial begin

   reg htif_pcr_resp_valid;
   reg [31:0] htif_pcr_resp_data;

   always @(posedge clk)begin
      htif_pcr_resp_valid <= DUT.zeroriscy_core.data_req_o & DUT.zeroriscy_core.data_we_o &
                             ((DUT.zeroriscy_core.data_addr_o == 32'h80001000)|
                              (DUT.zeroriscy_core.data_addr_o == 32'h80003000)|
                              (DUT.zeroriscy_core.data_addr_o == 32'h8017fffc));
      htif_pcr_resp_data <= DUT.zeroriscy_core.data_wdata_o;
   end

   always @(posedge clk) begin
      trace_count = trace_count + 1;

      if (!reset) begin
         if (htif_pcr_resp_valid && htif_pcr_resp_data != 0) begin
            if (htif_pcr_resp_data == 1) begin
               $display("*** PASSED *** after %d simulation cycles", trace_count);
               $finish;
            end else begin
               $sformat(reason, "tohost = %d", htif_pcr_resp_data >> 1);
            end
         end
      end


      if (reason) begin
         $display("*** FAILED *** (%s) after %d simulation cycles", reason, trace_count);
         $finish;
      end
   end

endmodule

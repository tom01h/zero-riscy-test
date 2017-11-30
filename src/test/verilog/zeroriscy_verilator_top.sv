
module zeroriscy_verilator_top(
                            input                        clk,
                            input                        reset
                            );

   localparam hexfile_words = 8192;

   reg [  63:0]               max_cycles;
   reg [  63:0]               trace_count;
   reg [255:0]                reason;
   reg [1023:0]               loadmem;
   integer                    stderr = 32'h80000002;

   reg [127:0]                hexfile [hexfile_words-1:0];

   zeroriscy_sim_top DUT(
                         .clk(clk),
                         .reset(reset)
                         );

   reg                        dmy;
   
   initial begin
      reason = 0;
      max_cycles = 0;
      trace_count = 0;
      dmy = $value$plusargs("max-cycles=%d", max_cycles);
   end // initial begin

   reg htif_pcr_resp_valid;
   reg [31:0] htif_pcr_resp_data;

   always @(posedge clk)begin
      htif_pcr_resp_valid <= DUT.zeroriscy_core.data_req_o & DUT.zeroriscy_core.data_we_o &
                             ((DUT.zeroriscy_core.data_addr_o == 32'h80001000)|
                              (DUT.zeroriscy_core.data_addr_o == 32'h80003000));
      htif_pcr_resp_data <= DUT.zeroriscy_core.data_wdata_o;
   end

   always @(posedge clk) begin
      trace_count = trace_count + 1;

      if (max_cycles > 0 && trace_count > max_cycles)
        reason = "timeout";

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

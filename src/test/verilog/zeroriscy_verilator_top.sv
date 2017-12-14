
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

   wire [31:0]                   instr = DUT.zeroriscy_core.id_stage_i.instr_rdata_i;
   wire [31:0]                   PC = DUT.zeroriscy_core.id_stage_i.pc_id_i;
   wire signed [12:0]            bimm = {instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
   wire signed [11:0]            immhl = {instr[31:25],instr[11:7]};
   wire signed [11:0]            imm12 = {instr[31:20]};
   wire signed [11:0]            imm20 = {instr[31:12]};
   wire signed [11:0]            jimm20 = {instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
   wire [4:0]                    rs1 = {instr[19:15]};
   wire [4:0]                    rs2 = {instr[24:20]};
   wire [4:0]                    rs3 = {instr[31:27]};
   wire [4:0]                    rd = {instr[11:7]};
   wire                          id_en = DUT.zeroriscy_core.id_stage_i.id_valid_o & DUT.zeroriscy_core.id_stage_i.instr_valid_i;

   integer                       F_HANDLE;
   initial F_HANDLE = $fopen("trace.log","w");
   always @ (posedge clk) begin
      if(id_en)begin
         $fwrite(F_HANDLE,"(%04d): PC = %08x, inst = %08x", trace_count, PC, instr);
`include "zeroriscy_trace.v"
         $fdisplay(F_HANDLE,"");
      end
   end
endmodule

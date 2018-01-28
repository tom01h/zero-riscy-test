
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

   wire [31:0]        instr = DUT.zeroriscy_core.id_stage_i.instr_rdata_i;
   wire [31:0]        PC = DUT.zeroriscy_core.id_stage_i.pc_id_i;
   wire signed [12:0] bimm = {instr[31],instr[7],instr[30:25],instr[11:8],1'b0};
   wire signed [11:0] immhl = {instr[31:25],instr[11:7]};
   wire signed [11:0] imm12 = {instr[31:20]};
   wire signed [11:0] imm20 = {instr[31:12]};
   wire signed [11:0] jimm20 = {instr[31],instr[19:12],instr[20],instr[30:21],1'b0};
   wire [4:0]         rs1 = {instr[19:15]};
   wire [4:0]         rs2 = {instr[24:20]};
   wire [4:0]         rs3 = {instr[31:27]};
   wire [4:0]         rd = {instr[11:7]};
   wire               id_en = DUT.zeroriscy_core.id_stage_i.id_valid_o & DUT.zeroriscy_core.id_stage_i.instr_valid_i;
   wire [31:0]        rs1d = DUT.zeroriscy_core.id_stage_i.registers_i.mem[rs1];
   wire [31:0]        rs2d = DUT.zeroriscy_core.id_stage_i.registers_i.mem[rs2];

   integer            F_HANDLE;
   initial F_HANDLE = $fopen("trace.log","w");
   always @ (posedge clk) begin
      if(id_en)begin
         $fwrite(F_HANDLE,"(%04d): PC = %08x, inst = %08x", trace_count, PC, instr);
`include "zeroriscy_trace.v"
         $fdisplay(F_HANDLE,"");
      end
   end

   wire                          we = DUT.zeroriscy_core.id_stage_i.registers_i.we_a_i;
   wire [4:0]                    wa = DUT.zeroriscy_core.id_stage_i.registers_i.waddr_a_i;
   wire [31:0]                   wd = DUT.zeroriscy_core.id_stage_i.registers_i.wdata_a_i;

   integer                       W_HANDLE;
   initial W_HANDLE = $fopen("wb.log","w");
   always @ (posedge clk) begin
      if(we)begin
         $fwrite(W_HANDLE,"(%04d): x%02d <= %08x", trace_count, wa, wd);
         $fdisplay(W_HANDLE,"");
      end
   end
endmodule

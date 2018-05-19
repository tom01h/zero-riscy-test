module zeroriscy_d_sram
  (
   input         clk,
   input         rst_n,//

   input         p_req,
   input         p_we,
   input [3:0]   p_be,
   input [31:0]  p_addr,
   input [31:0]  p_wdata,
   output [31:0] p_rdata,
   output        p_gnt,//
   output        p_rvalid,//
   output        p_err//
   );

   v_rams_d ram0 (.clk(clk),
                  .we(p_req&p_we&p_be[0]),
                  .addr(p_addr[16:2]),
                  .din(p_wdata[7:0]),
                  .dout(p_rdata[7:0]));

   v_rams_d ram1 (.clk(clk),
                  .we(p_req&p_we&p_be[1]),
                  .addr(p_addr[16:2]),
                  .din(p_wdata[15:8]),
                  .dout(p_rdata[15:8]));

   v_rams_d ram2 (.clk(clk),
                  .we(p_req&p_we&p_be[2]),
                  .addr(p_addr[16:2]),
                  .din(p_wdata[23:16]),
                  .dout(p_rdata[23:16]));

   v_rams_d ram3 (.clk(clk),
                  .we(p_req&p_we&p_be[3]),
                  .addr(p_addr[16:2]),
                  .din(p_wdata[31:24]),
                  .dout(p_rdata[31:24]));

   reg           p_reg_req;//
   always_ff @(posedge clk) begin//
      p_reg_req <= p_req;//
   end//

   assign p_gnt = 1'b1;//
   assign p_rvalid = p_reg_req;//
   assign p_err = 1'b0;//

endmodule

module v_rams_d (clk, we, addr, din, dout);
   input clk;
   input we;
   input [14:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:32*1024-1];
   reg [7:0]    dout;
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

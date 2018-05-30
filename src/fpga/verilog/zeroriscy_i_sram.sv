module zeroriscy_i_sram
  (
   input         clk,
   input         rst_n,

   input         p_req,
   input         p_we,
   input [3:0]   p_be,
   input [31:0]  p_addr,
   input [31:0]  p_wdata,
   output [31:0] p_rdata,
   output        p_gnt,
   output        p_rvalid,
   output        p_err
   );

   v_rams_i ram (.clk(clk),
                 .en(p_req),
                 .we({4{p_req&p_we}}&p_be),
                 .addr({p_addr[19],p_addr[13:2]}),
                 .din(p_wdata[31:0]),
                 .dout(p_rdata[31:0]));

   reg           p_reg_req;
   always_ff @(posedge clk) begin
      p_reg_req <= p_req;
   end

   assign p_gnt = 1'b1;
   assign p_rvalid = p_reg_req;
   assign p_err = 1'b0;

endmodule

module v_rams_i (clk, en, we, addr, din, dout);
   input clk;
   input en;
   input [3:0] we;
   input [12:0] addr;
   input [31:0] din;
   output [31:0] dout;

   reg [31:0]    dout;

   `include "ram.v"

   always @(posedge clk)
     if (en) begin
        dout <= ram[addr];
     end

   generate
      genvar i;
      for (i = 0; i < 4 ; i = i+1) begin: byte_write
         always @(posedge clk)
           if (en)
             if (we[i])
               ram[addr][(i+1)*8-1:i*8] <= din[(i+1)*8-1:i*8];
      end
   endgenerate
endmodule

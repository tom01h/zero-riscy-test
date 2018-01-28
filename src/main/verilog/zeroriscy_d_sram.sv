
module zeroriscy_d_sram
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

   parameter nwords = 32*1024;  //128KB Data

   logic [31:0]  dmem [nwords-1:0];

   wire [31:0]    p_wmask = {{8{p_be[3]}},{8{p_be[2]}},{8{p_be[1]}},{8{p_be[0]}}};

   wire [14:0]    p_raddr = p_addr[16:2];
   reg [14:0]     p_reg_raddr;
   reg            p_reg_req;

   always_ff @(posedge clk) begin
      p_reg_raddr <= p_raddr;
      p_reg_req <= p_req;
      if (p_req&p_we) begin
         dmem[p_raddr] <= (dmem[p_raddr] & ~p_wmask) | (p_wdata & p_wmask);
      end
   end

   assign p_rdata = dmem[p_reg_raddr];
   assign p_gnt = 1'b1;
   assign p_rvalid = p_reg_req;
   assign p_err = 1'b0;

endmodule

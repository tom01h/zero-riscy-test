
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

   parameter bwords = 4*1024;   // 16KB Boot Rom
   parameter iwords = 4*1024;   // 16KB Instruction

   logic [31:0]  bmem [bwords-1:0];
   logic [31:0]  imem [iwords-1:0];

   wire [31:0]    p_wmask = {{8{p_be[3]}},{8{p_be[2]}},{8{p_be[1]}},{8{p_be[0]}}};

   wire           p_bmem = (p_addr[19]==1'b0);
   wire           p_imem = (p_addr[19]==1'b1);
   wire [14:0]    p_raddr = p_addr[16:2];
   reg [14:0]     p_reg_raddr;
   reg            p_reg_req;
   reg            p_reg_bmem;
   reg            p_reg_imem;

   always_ff @(posedge clk) begin
      p_reg_raddr <= p_raddr;
      p_reg_req <= p_req;
      p_reg_bmem <= p_bmem;
      p_reg_imem <= p_imem;
      if (p_req&p_we) begin
         if(p_bmem)begin
            bmem[p_raddr] <= (bmem[p_raddr] & ~p_wmask) | (p_wdata & p_wmask);
         end else if(p_imem)begin
            imem[p_raddr] <= (imem[p_raddr] & ~p_wmask) | (p_wdata & p_wmask);
         end
      end
   end

   assign p_rdata = (p_reg_bmem) ? bmem[p_reg_raddr] :
                    (p_reg_imem) ? imem[p_reg_raddr] : 32'hxxxxxxxx;
   assign p_gnt = 1'b1;
   assign p_rvalid = p_reg_req;
   assign p_err = 1'b0;

endmodule

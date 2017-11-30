
module zeroriscy_dp_sram
  (
   input         clk,
   input         rst_n,

   input         p0_req,
   input         p0_we,
   input [3:0]   p0_be,
   input [31:0]  p0_addr,
   input [31:0]  p0_wdata,
   output [31:0] p0_rdata,
   output        p0_gnt,
   output        p0_rvalid,
   output        p0_err,

   input         p1_req,
   input         p1_we,
   input [3:0]   p1_be,
   input [31:0]  p1_addr,
   input [31:0]  p1_wdata,
   output [31:0] p1_rdata,
   output        p1_gnt,
   output        p1_rvalid,
   output        p1_err
   );

   parameter nwords = 65536;

   logic [31:0]    mem [nwords-1:0];

   // p0

   // flops
   wire [31:0]    p0_wmask = {{8{p0_be[3]}},{8{p0_be[2]}},{8{p0_be[1]}},{8{p0_be[0]}}};

   wire [28:0]    p0_raddr = p0_addr >> 2;
   reg [31:0]     p0_reg_raddr;
   reg [31:0]     p0_reg_req;

   always_ff @(posedge clk) begin
      p0_reg_raddr <= p0_raddr;
      p0_reg_req <= p0_req;
      if (p0_req&p0_we) begin
         mem[p0_raddr] <= (mem[p0_raddr] & ~p0_wmask) | (p0_wdata & p0_wmask);
      end
   end

   assign p0_rdata = mem[p0_reg_raddr];
   assign p0_gnt = 1'b1;
   assign p0_rvalid = p0_reg_req;
   assign p0_err = 1'b0;

   // p1

   wire [28:0]    p1_raddr = p1_addr >> 2;
   reg [31:0]     p1_reg_raddr;
   reg [31:0]     p1_reg_req;

   always_ff @(posedge clk) begin
      p1_reg_raddr <= p1_raddr;
      p1_reg_req <= p1_req;
   end

   assign p1_rdata = mem[p1_reg_raddr];
   assign p1_gnt = 1'b1;
   assign p1_rvalid = p1_reg_req;
   assign p1_resp = 1'b0;

endmodule

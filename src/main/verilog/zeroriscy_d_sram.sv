
module zeroriscy_d_sram
  (
   input logic          clk,
   input logic [11:0]   addr,
   output logic [255:0] dout,
   input logic [7:0]    cs,
   input logic          we,
   input logic [3:0]    be,
   input logic [31:0]   din
   );

   parameter nwords = 32*1024;  //128KB Data

   logic [31:0]          mem [nwords-1:0];

   wire [31:0]           wmask = {{8{be[3]}},{8{be[2]}},{8{be[1]}},{8{be[0]}}};

   logic [2:0]           oaddr;
   assign oaddr[2] = (|cs[7:4]);
   assign oaddr[1] = (|cs[7:6])|(|cs[3:2]);
   assign oaddr[0] = cs[7]|cs[5]|cs[3]|cs[1];

   wire [14:0]           waddr = {addr[11:0],oaddr[2:0]};
   always_ff @(posedge clk) begin
      if ((|cs)&we) begin
         mem[waddr] <= (mem[waddr] & ~wmask) | (din & wmask);
      end
   end

   always_ff @(posedge clk)
     begin
        if(cs[0]) dout[32*7+31:32*7+0] <= mem[{addr,3'd0}];
        if(cs[1]) dout[32*6+31:32*6+0] <= mem[{addr,3'd1}];
        if(cs[2]) dout[32*5+31:32*5+0] <= mem[{addr,3'd2}];
        if(cs[3]) dout[32*4+31:32*4+0] <= mem[{addr,3'd3}];
        if(cs[4]) dout[32*3+31:32*3+0] <= mem[{addr,3'd4}];
        if(cs[5]) dout[32*2+31:32*2+0] <= mem[{addr,3'd5}];
        if(cs[6]) dout[32*1+31:32*1+0] <= mem[{addr,3'd6}];
        if(cs[7]) dout[32*0+31:32*0+0] <= mem[{addr,3'd7}];
     end
endmodule

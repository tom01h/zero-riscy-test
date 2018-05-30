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

   genvar              i;
   generate begin
      for(i=0;i<8;i=i+1) begin : ram_block
         v_rams_d ram (.clk(clk),
                       .en(cs[i]),
                       .we({4{cs[i]&we}}&be),
                       .addr(addr[11:0]),
                       .din(din[31:0]),
                       .dout(dout[31+32*(7-i):0+32*(7-i)]));
      end : ram_block
   end
   endgenerate

endmodule

module v_rams_d (clk, en, we, addr, din, dout);
   input clk;
   input en;
   input [3:0] we;
   input [11:0] addr;
   input [31:0] din;
   output [31:0] dout;

   reg [31:0]    ram [0:4*1024-1];
   reg [31:0]    dout;

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

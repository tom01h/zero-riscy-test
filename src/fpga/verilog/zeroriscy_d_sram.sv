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
         v_rams_d ram0 (.clk(clk),
                        .we(cs[i]&we&be[0]),
                        .addr(addr[11:0]),
                        .din(din[7:0]),
                        .dout(dout[7+32*(7-i):0+32*(7-i)]));

         v_rams_d ram1 (.clk(clk),
                        .we(cs[i]&we&be[1]),
                        .addr(addr[11:0]),
                        .din(din[15:8]),
                        .dout(dout[15+32*(7-i):8+32*(7-i)]));

         v_rams_d ram2 (.clk(clk),
                        .we(cs[i]&we&be[2]),
                        .addr(addr[11:0]),
                        .din(din[23:16]),
                        .dout(dout[23+32*(7-i):16+32*(7-i)]));

         v_rams_d ram3 (.clk(clk),
                        .we(cs[i]&we&be[3]),
                        .addr(addr[11:0]),
                        .din(din[31:24]),
                        .dout(dout[31+32*(7-i):24+32*(7-i)]));
      end : ram_block
   end
   endgenerate

endmodule

module v_rams_d (clk, we, addr, din, dout);
   input clk;
   input we;
   input [11:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:4*1024-1];
   reg [7:0]    dout;
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

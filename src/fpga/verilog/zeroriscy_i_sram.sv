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

   v_rams_i0 ram0 (.clk(clk),
                   .we(p_req&p_we&p_be[0]),
                   .addr({p_addr[19],p_addr[13:2]}),
                   .din(p_wdata[7:0]),
                   .dout(p_rdata[7:0]));

   v_rams_i1 ram1 (.clk(clk),
                   .we(p_req&p_we&p_be[1]),
                   .addr({p_addr[19],p_addr[13:2]}),
                   .din(p_wdata[15:8]),
                   .dout(p_rdata[15:8]));

   v_rams_i2 ram2 (.clk(clk),
                   .we(p_req&p_we&p_be[2]),
                   .addr({p_addr[19],p_addr[13:2]}),
                   .din(p_wdata[23:16]),
                   .dout(p_rdata[23:16]));

   v_rams_i3 ram3 (.clk(clk),
                   .we(p_req&p_we&p_be[3]),
                   .addr({p_addr[19],p_addr[13:2]}),
                   .din(p_wdata[31:24]),
                   .dout(p_rdata[31:24]));

   reg           p_reg_req;
   always_ff @(posedge clk) begin
      p_reg_req <= p_req;
   end

   assign p_gnt = 1'b1;
   assign p_rvalid = p_reg_req;
   assign p_err = 1'b0;

endmodule

module v_rams_i0 (clk, we, addr, din, dout);
   input clk;
   input we;
   input [12:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:8*1024-1];
   reg [7:0]    dout;
   initial
     begin
        $readmemh("ram.data0",ram);
     end
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

module v_rams_i1 (clk, we, addr, din, dout);
   input clk;
   input we;
   input [12:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:8*1024-1];
   reg [7:0]    dout;
   initial
     begin
        $readmemh("ram.data1",ram);
     end
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

module v_rams_i2 (clk, we, addr, din, dout);
   input clk;
   input we;
   input [12:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:8*1024-1];
   reg [7:0]    dout;
   initial
     begin
        $readmemh("ram.data2",ram);
     end
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

module v_rams_i3 (clk, we, addr, din, dout);
   input clk;
   input we;
   input [12:0] addr;
   input [7:0] din;
   output [7:0] dout;
   reg [7:0]    ram [0:8*1024-1];
   reg [7:0]    dout;
   initial
     begin
        $readmemh("ram.data3",ram);
     end
   always @(posedge clk)
     begin
        if (we)
          ram[addr] <= din;
        dout <= ram[addr];
     end
endmodule

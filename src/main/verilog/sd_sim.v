module sd_sim
  (
   input             clk,
   input             resetn,
   input [31:0]      addr,
   input             req,
   input             we,
   input [3:0]       be,
   input [31:0]      wdata,
   output reg [31:0] rdata,
   output            gnt,
   output            rvalid,
   output            err
   );

   reg               req_l;
   reg [7:0]         addr_l;
   reg [3:0]         be_l;
   reg [31:0]        d_l;
   reg               we_l;

   always @(posedge clk) begin
      req_l   <= req;
      addr_l[7:0]  <= addr[7:0];
      be_l    <= be;
      we_l    <= we&req;
      if(addr[5]==1'b0)begin
         d_l     <= wdata;
      end else begin
         d_l[31:8] <= 0;
         case(addr[1:0])
           2'b00: d_l[7:0] <= wdata[7:0];
           2'b01: d_l[7:0] <= wdata[15:8];
           2'b10: d_l[7:0] <= wdata[23:16];
           2'b11: d_l[7:0] <= wdata[31:24];
         endcase
      end
   end

   // 00      => data buf address
   // 04      => Number of bytes to read
   // 08      => pointer to Number of bytes read
   // 20 - 3f => read size buf address

   always @(*) begin
      rdata = {32{1'b0}};
   end

endmodule

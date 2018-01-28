
module uart_sim
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
   reg [3:2]         addr_l;
   reg [3:0]         be_l;
   reg [31:0]        d_l;
   reg               we_l;

   reg [1:0]         cnt;

   always @(posedge clk) begin
      if(req)
        if((addr[3:2]==2'b01) & ~we)
          if(cnt!=0)
            cnt <= cnt-1;
          else
            cnt <= 0;
        else
          cnt <= 3;
      req_l   <= req;
      addr_l  <= addr[3:2];
      be_l    <= be;
      we_l    <= we&req;
      d_l     <= wdata;
   end

   reg [7:0] div0, div1, din_i;
   reg [7:0] dout_o;
   wire      full_o = 1'b0;
   reg       empty_o;
   
   always @(posedge clk) begin
      if (~resetn)
        div0[7:0] <= 8'h00;
      else if (req_l & we_l & be_l[0] & addr_l[3:2] == 2'b00)
        div0[7:0] <= d_l[7:0];

      if (~resetn)
        div1[7:0] <= 8'h00;
      else if (req_l & we_l & be_l[1] & addr_l[3:2] == 2'b00)
        div1[7:0] <= d_l[15:8];

      if (~resetn) begin
         empty_o = 1'b1;
         dout_o = 8'h00;
      end else if (req_l & we_l & be_l[0] & addr_l[3:2] == 2'b11) begin //DUMMY//DUMMY//
         empty_o = 1'b0;
         dout_o = d_l[7:0];
      end else if (req_l &~we_l & be_l[0] & addr_l[3:2] == 2'b10) begin
         empty_o = 1'b1;
      end
   end
   always @(*) begin
      din_i[7:0] <= d_l[7:0];
   end
   always @(*) begin
      case(addr_l[3:2])
        2'b00 : rdata = {{16{1'b0}},div1,div0};
        2'b01 : rdata = {{24{1'b0}},6'h00,full_o,empty_o};
        2'b10 : rdata = {{24{1'b0}},dout_o};
        default : rdata = {32{1'bx}};
      endcase
   end   

endmodule

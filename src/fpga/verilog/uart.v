// 4'h0 Baud Rate
//      [15:8] div1
//      [7:0]  div0
//      9600bps @ 50MHz
//      50MHz/9600/4 = 1302 = 20*65 = (div0+2) * div1
//      div1=65, div0=18
// 4'h4 Status
//      [1] TXF (TX Full)
//      [0] RXE (RX Empty)
// 4'h8 Data
//      [7:0] Data

module uart
  (
   input             clk,
   input             resetn,
   input             req,
   input [31:0]      addr,
   input             we,
   input [3:0]       be,
   input [31:0]      wdata,
   output reg [31:0] rdata,
   output            gnt,
   output            rvalid,
   output            err,
   input             RXD,
   output            TXD
   );

   reg               req_l;
   reg [3:2]         addr_l;
   reg [3:0]         be_l;
   reg [31:0]        d_l;
   reg               we_l;

   assign gnt = 1'b1;
   assign rvalid = 1'b0;
   assign err = 1'b0;

   always @(posedge clk) begin
      req_l  <= req;
      addr_l <= addr[3:2];
      be_l   <= be;
      we_l   <= we&req;
      d_l    <= wdata;
   end

   reg [7:0] div0, div1, din_i;
   wire [7:0] dout_o;
   wire      full_o,empty_o;
   
   always @(posedge clk) begin
      if (~resetn)
        div0[7:0] <= 8'h00;
      else if (req_l & we_l & be_l[0] & addr_l[3:2] == 2'b00)
        div0[7:0] <= d_l[7:0];

      if (~resetn)
        div1[7:0] <= 8'h00;
      else if (req_l & we_l & be_l[1] & addr_l[3:2] == 2'b00)
        div1[7:0] <= d_l[15:8];

//      if (~resetn)
//        din_i[7:0] <= 8'h00;
//      else if (req_l & we_l & be_l[1] & addr_l[3:2] == 2'b00)
//        din_i[7:0] <= d_l[7:0];
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

   wire re_i = req_l & ~we_l & (addr_l[3:2] == 2'b10);
   wire we_i = req_l &  we_l & (addr_l[3:2] == 2'b10) & be_l[0];
   
// sasc from cpen core
   wire sio_ce, sio_ce_x4;
   
   sasc_top top
     (
      .clk(clk),
      .rst(resetn),
      .rxd_i(RXD),
      .txd_o(TXD),
      .cts_i(1'b0),
      .rts_o(),
      .sio_ce(sio_ce),
      .sio_ce_x4(sio_ce_x4),
      .din_i(din_i),
      .dout_o(dout_o),
      .re_i(re_i),
      .we_i(we_i),
      .full_o(full_o),
      .empty_o(empty_o)
      );

   sasc_brg brg
     (
      .clk(clk),
      .rst(resetn),
      .div0(div0),
      .div1(div1),
      .sio_ce(sio_ce),
      .sio_ce_x4(sio_ce_x4)
      );
endmodule

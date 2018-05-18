
module zeroriscy_xbar
  (
   input         clk,
   input         resetn,

   input         im_req,
   input [31:0]  im_addr,
   output [31:0] im_rdata,
   output        im_gnt,
   output        im_rvalid,
   output        im_err,

   input         dm_req,
   input         dm_we,
   input [3:0]   dm_be,
   input [31:0]  dm_addr,
   input [31:0]  dm_wdata,
   output [31:0] dm_rdata,
   output        dm_gnt,
   output        dm_rvalid,
   output        dm_err,

   output        is_req,
   output        is_we,
   output [3:0]  is_be,
   output [31:0] is_addr,
   output [31:0] is_wdata,
   input [31:0]  is_rdata,
   input         is_err,

   output        ds_req,
   output        ds_we,
   output [3:0]  ds_be,
   output [31:0] ds_addr,
   output [31:0] ds_wdata,
   input [31:0]  ds_rdata,
   input         ds_gnt,
   input         ds_rvalid,
   input         ds_err,

   output        ss_req,
   output        ss_we,
   output [3:0]  ss_be,
   output [31:0] ss_addr,
   output [31:0] ss_wdata,
   input [31:0]  ss_rdata,
   input         ss_gnt,
   input         ss_rvalid,
   input         ss_err
   );

   wire [2:0] im_reqi = ((~im_req)                 ? 3'b000 :
                         (im_addr[31:20]==12'h800) ? 3'b001 :   // [0] inst
                         (im_addr[31:20]==12'h801) ? 3'b010 :   // [1] data
                                                     3'b100  ); // [2] system
   wire [2:0] dm_reqi = ((~dm_req)                 ? 3'b000 :
                         (dm_addr[31:20]==12'h800) ? 3'b001 :   // [0] inst
                         (dm_addr[31:20]==12'h801) ? 3'b010 :   // [1] data
                                                     3'b100  ); // [2] system

   assign is_req = im_reqi[0]|dm_reqi[0];
   assign ds_req = im_reqi[1]|dm_reqi[1];
   assign ss_req = im_reqi[2]|dm_reqi[2];
  
   reg [2:0]  im_req_l, dm_req_l, sm_req_l;

   always @ (posedge clk)
     if(~resetn) im_req_l <= 3'b000;
     else if(im_gnt&((im_req_l==3'b000)|im_rvalid)) im_req_l <= im_reqi;
   always @ (posedge clk)
     if(~resetn) dm_req_l <= 3'b000;
     else if(dm_gnt&((dm_req_l==3'b000)|dm_rvalid)) dm_req_l <= dm_reqi;

   assign is_we       = (~dm_reqi[0]) ? 1'b0    : dm_we;
   assign is_be       = (~dm_reqi[0]) ? 4'h0    : dm_be;
   assign is_addr     = (~dm_reqi[0]) ? im_addr : dm_addr;
   assign is_wdata    = (~dm_reqi[0]) ? 32'h0   : dm_wdata;
   
   assign ds_we       = (~dm_reqi[1]) ? 1'b0    : dm_we;
   assign ds_be       = (~dm_reqi[1]) ? 4'h0    : dm_be;
   assign ds_addr     = (~dm_reqi[1]) ? im_addr : dm_addr;
   assign ds_wdata    = (~dm_reqi[1]) ? 32'h0   : dm_wdata;
   
   assign ss_we       = (~dm_reqi[2]) ? 1'b0    : dm_we;
   assign ss_be       = (~dm_reqi[2]) ? 4'h0    : dm_be;
   assign ss_addr     = (~dm_reqi[2]) ? im_addr : dm_addr;
   assign ss_wdata    = (~dm_reqi[2]) ? 32'h0   : dm_wdata;
   
   assign im_rdata  = ((im_req_l[2]) ? ss_rdata :
                       (im_req_l[1]) ? ds_rdata : is_rdata);
   assign im_gnt    = ((im_reqi[2]) ? (ss_gnt&~dm_reqi[2]) :
                       (im_reqi[1]) ? (ds_gnt&~dm_reqi[1]) :
                       (im_reqi[0]) ?         ~dm_reqi[0]  : 1'b1);
   assign im_rvalid =  im_req_l[2]&~dm_req_l[2]&ss_rvalid|
                       im_req_l[1]&~dm_req_l[1]&ds_rvalid|
                       im_req_l[0]&~dm_req_l[0];
   assign im_err    = (im_req_l[2]) ? ss_err   : (im_req_l[1]) ? ds_err   : is_err;

   assign dm_rdata  = ((dm_req_l[2]) ? ss_rdata :
                       (dm_req_l[1]) ? ds_rdata : is_rdata);
   assign dm_gnt    = ((dm_reqi[2]) ? ss_gnt :
                       (dm_reqi[1]) ? ds_gnt : 1'b1);
   assign dm_rvalid =  dm_req_l[2]&ss_rvalid|
                       dm_req_l[1]&ds_rvalid|
                       dm_req_l[0];
   assign dm_err    = (dm_req_l[2]) ? ss_err   : (dm_req_l[1]) ? ds_err   : is_err;
   
endmodule

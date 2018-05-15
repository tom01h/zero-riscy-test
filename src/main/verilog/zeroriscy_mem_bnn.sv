// Copyright 2018 tom01h
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module zeroriscy_mem_bnn
  (
   input logic         clk,
   input logic         rst_n,

   input logic         b_req,
   input logic         p_req,
   input logic         p_we,
   input logic [3:0]   p_be,
   input logic [31:0]  p_addr,
   input logic [31:0]  p_wdata,
   output logic [31:0] p_rdata,
   output logic        p_gnt,
   output logic        p_rvalid,
   output logic        p_err
   );

   logic [31:0]        b_rdata;
   logic [1023:0]      rdata;
   logic [31:0]        cs_1;
   always @(*)begin
      if(bnn_en_1)
        p_rdata[31:0] = b_rdata;
      else
        p_rdata[31:0] = ({32{cs_1[0]}}  & rdata[32*31+31:32*31+0])|
                        ({32{cs_1[1]}}  & rdata[32*30+31:32*30+0])|
                        ({32{cs_1[2]}}  & rdata[32*29+31:32*29+0])|
                        ({32{cs_1[3]}}  & rdata[32*28+31:32*28+0])|
                        ({32{cs_1[4]}}  & rdata[32*27+31:32*27+0])|
                        ({32{cs_1[5]}}  & rdata[32*26+31:32*26+0])|
                        ({32{cs_1[6]}}  & rdata[32*25+31:32*25+0])|
                        ({32{cs_1[7]}}  & rdata[32*24+31:32*24+0])|
                        ({32{cs_1[8]}}  & rdata[32*23+31:32*23+0])|
                        ({32{cs_1[9]}}  & rdata[32*22+31:32*22+0])|
                        ({32{cs_1[10]}} & rdata[32*21+31:32*21+0])|
                        ({32{cs_1[11]}} & rdata[32*20+31:32*20+0])|
                        ({32{cs_1[12]}} & rdata[32*19+31:32*19+0])|
                        ({32{cs_1[13]}} & rdata[32*18+31:32*18+0])|
                        ({32{cs_1[14]}} & rdata[32*17+31:32*17+0])|
                        ({32{cs_1[15]}} & rdata[32*16+31:32*16+0])|
                        ({32{cs_1[16]}} & rdata[32*15+31:32*15+0])|
                        ({32{cs_1[17]}} & rdata[32*14+31:32*14+0])|
                        ({32{cs_1[18]}} & rdata[32*13+31:32*13+0])|
                        ({32{cs_1[19]}} & rdata[32*12+31:32*12+0])|
                        ({32{cs_1[20]}} & rdata[32*11+31:32*11+0])|
                        ({32{cs_1[21]}} & rdata[32*10+31:32*10+0])|
                        ({32{cs_1[22]}} & rdata[32*9 +31:32*9+0])|
                        ({32{cs_1[23]}} & rdata[32*8 +31:32*8+0])|
                        ({32{cs_1[24]}} & rdata[32*7 +31:32*7+0])|
                        ({32{cs_1[25]}} & rdata[32*6 +31:32*6+0])|
                        ({32{cs_1[26]}} & rdata[32*5 +31:32*5+0])|
                        ({32{cs_1[27]}} & rdata[32*4 +31:32*4+0])|
                        ({32{cs_1[28]}} & rdata[32*3 +31:32*3+0])|
                        ({32{cs_1[29]}} & rdata[32*2 +31:32*2+0])|
                        ({32{cs_1[30]}} & rdata[32*1 +31:32*1+0])|
                        ({32{cs_1[31]}} & rdata[32*0 +31:32*0+0]);
   end

   logic [9:0]         ram_addr;
   logic [31:0]        cs;
   integer             i;

   assign p_gnt = 1'b1;//TEMP//TEMP//
   //output logic        p_rvalid,

   always @(p_addr)begin
      if(p_req)begin
         ram_addr = p_addr[16:7];
      end else if (b_req) begin
         ram_addr = p_addr[11:2];
      end else begin
         ram_addr = 10'hxx;
      end
      if(~p_gnt)begin
         cs=32'h00000000;
      end else if(p_req)begin
         for(i=0;i<32;i=i+1)begin
            cs[i]=(i==p_addr[6:2]);
         end
      end else if(b_req&(p_addr[12]==0))begin
         cs=32'hffffffff;
      end else begin
         cs=32'h00000000;
      end
   end

   bnn_ram ram0
     (.clk(clk),
      .addr(ram_addr),
      .dout(rdata),
      .cs(cs),
      .we(p_we&p_req),
      .be(p_be),
      .din(p_wdata));

   logic               bnn_en_1;
   logic [2:0]         com_1;
   logic [4:0]         addr_1;
   logic [31:0]        data_1;
   wire                bnn_en = b_req&p_gnt;

// input stage
   always_ff @(posedge clk)begin
      if(bnn_en)begin
         bnn_en_1 <= 1'b1;
         data_1[31:0] <= p_wdata;
         if(~p_addr[12])begin
            com_1[2:0] <= {~p_be[1],~p_be[2],1'b1};
         end else if(~p_addr[8])begin
            com_1[2:0] <= {p_addr[3:2],1'b0};
         end else begin
            com_1[2:0] <= 3'h4;
            addr_1[3:0] <= p_addr[5:2];
         end
      end else begin
         bnn_en_1 <= 1'b0;
         com_1[2:0] <= 3'b101;
         if(p_req)begin
            addr_1[4:0] <= p_addr[6:2];
            cs_1[31:0] <= cs[31:0];
         end
      end
   end

   genvar               g;
   generate begin
      for(g=0;g<32;g=g+1) begin : estimate_block
         bnn_core core
            (.clk(clk), .com_1(com_1[2:0]), .seten_1({(g=={addr_1[3:0],1'b0}),(g=={addr_1[3:0],1'b1})}),
             .data_1(data_1[31:0]), .param(rdata[32*(31-g)+31:32*(31-g)+0]),
             .activ(b_rdata[g])
             );
      end : estimate_block
   end
   endgenerate

endmodule

module bnn_core
  (
   input wire        clk,
   input wire [2:0]  com_1,
   input wire [1:0]  seten_1,
   input wire [31:0] data_1,
   input wire [31:0] param,
   output wire       activ
   );

   integer           i;

   reg signed [15:0] acc;
   reg signed [15:0] pool;

   reg [2:0]         com_2;
   reg [31:0]        data_2;
   reg [1:0]         seten_2;

// 1st stage
   always_ff @(posedge clk)begin
      com_2[2:0] <= com_1;
      case(com_1)
        3'd0 : begin //ini
           data_2 <= data_1;
        end
        3'd1 : begin //acc
           data_2 <= ~(data_1^param);
        end
        3'd2 : begin //pool
           data_2 <= data_1;
        end
        3'd3 : begin //norm
           data_2 <= param;
        end
        3'd4 : begin //seten
           seten_2 <= seten_1;
           data_2 <= data_1;
        end
        3'd7 : begin //norm8
           data_2 <= param;
        end
      endcase
   end
// 2nd stage
   reg [15:0] sum;
   always_comb begin
      sum = 0;
      for(i=0; i<32;i=i+1)begin
         sum = sum + {1'b0,data_2[i],1'b0};
      end
   end
   always_ff @(posedge clk)begin
      case(com_2)
        3'd0 : begin //ini
           acc[15:0] <= data_2[15:0];
           pool[15:0] <= 16'h8000;
        end
        3'd1 : begin //acc
           acc <= acc + sum;
        end
        3'd2 : begin //pool
           if(acc>pool)begin
              pool[15:0] <= acc[15:0];
           end
           acc[15:0] <= data_2[15:0];
        end
        3'd3 : begin //norm
           pool[15:0] <= {pool[15:0],3'h0} - data_2[15:0];
        end
        3'd4 : begin //seten
           if(seten_2==2'b10)
             acc[15:0] <= data_2[31:16];
           if(seten_2==2'b01)
             acc[15:0] <= data_2[15:0];
           if(seten_2==2'b11)
             acc[15:0] <= 16'hxxxx;
        end
//        3'd6 : begin //activ
//           activ <= pool[15];
//        end
        3'd7 : begin //norm8
           pool[15:0] <= pool[15:0] - data_2[15:0];
        end
      endcase
   end
   assign activ = pool[15];
endmodule

module bnn_ram
  (
   input logic           clk,
   input logic [9:0]     addr,
   output logic [1023:0] dout,
   input logic [31:0]    cs,
   input logic           we,
   input logic [3:0]     be,
   input logic [31:0]    din
   );

   parameter nwords = 32*1024;  //128KB Data

   logic [31:0]          mem [nwords-1:0];

   wire [31:0]           wmask = {{8{be[3]}},{8{be[2]}},{8{be[1]}},{8{be[0]}}};

   logic [4:0]           oaddr;
   assign oaddr[4] = (|cs[31:16]);
   assign oaddr[3] = (|cs[31:24])|(|cs[15:8]);
   assign oaddr[2] = (|cs[31:28])|(|cs[23:20])|(|cs[15:12])|(|cs[7:4]);
   assign oaddr[1] = (|cs[31:30])|(|cs[27:26])|(|cs[23:22])|(|cs[19:18])|
                     (|cs[15:14])|(|cs[11:10])|(|cs[7:6])  |(|cs[3:2]);
   assign oaddr[0] = cs[31]|cs[29]|cs[27]|cs[25]|cs[23]|cs[21]|cs[19]|cs[17]|
                     cs[15]|cs[13]|cs[11]|cs[9] |cs[7] |cs[5] |cs[3] |cs[1];

   wire [14:0]           waddr = {addr[9:0],oaddr[4:0]};
   always_ff @(posedge clk) begin
      if ((|cs)&we) begin
         mem[waddr] <= (mem[waddr] & ~wmask) | (din & wmask);
      end
   end

   always @(posedge clk)
     begin
        dout[32*31+31:32*31+0] <= mem[{addr,5'd0}];
        dout[32*30+31:32*30+0] <= mem[{addr,5'd1}];
        dout[32*29+31:32*29+0] <= mem[{addr,5'd2}];
        dout[32*28+31:32*28+0] <= mem[{addr,5'd3}];
        dout[32*27+31:32*27+0] <= mem[{addr,5'd4}];
        dout[32*26+31:32*26+0] <= mem[{addr,5'd5}];
        dout[32*25+31:32*25+0] <= mem[{addr,5'd6}];
        dout[32*24+31:32*24+0] <= mem[{addr,5'd7}];
        dout[32*23+31:32*23+0] <= mem[{addr,5'd8}];
        dout[32*22+31:32*22+0] <= mem[{addr,5'd9}];
        dout[32*21+31:32*21+0] <= mem[{addr,5'd10}];
        dout[32*20+31:32*20+0] <= mem[{addr,5'd11}];
        dout[32*19+31:32*19+0] <= mem[{addr,5'd12}];
        dout[32*18+31:32*18+0] <= mem[{addr,5'd13}];
        dout[32*17+31:32*17+0] <= mem[{addr,5'd14}];
        dout[32*16+31:32*16+0] <= mem[{addr,5'd15}];
        dout[32*15+31:32*15+0] <= mem[{addr,5'd16}];
        dout[32*14+31:32*14+0] <= mem[{addr,5'd17}];
        dout[32*13+31:32*13+0] <= mem[{addr,5'd18}];
        dout[32*12+31:32*12+0] <= mem[{addr,5'd19}];
        dout[32*11+31:32*11+0] <= mem[{addr,5'd20}];
        dout[32*10+31:32*10+0] <= mem[{addr,5'd21}];
        dout[32*9 +31:32*9 +0] <= mem[{addr,5'd22}];
        dout[32*8 +31:32*8 +0] <= mem[{addr,5'd23}];
        dout[32*7 +31:32*7 +0] <= mem[{addr,5'd24}];
        dout[32*6 +31:32*6 +0] <= mem[{addr,5'd25}];
        dout[32*5 +31:32*5 +0] <= mem[{addr,5'd26}];
        dout[32*4 +31:32*4 +0] <= mem[{addr,5'd27}];
        dout[32*3 +31:32*3 +0] <= mem[{addr,5'd28}];
        dout[32*2 +31:32*2 +0] <= mem[{addr,5'd29}];
        dout[32*1 +31:32*1 +0] <= mem[{addr,5'd30}];
        dout[32*0 +31:32*0 +0] <= mem[{addr,5'd31}];
     end
endmodule

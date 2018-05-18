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

   logic               bnn_en_1;
   logic [2:0]         com_1;
   logic [1:0]         bs_1;
   logic [9:0]         addr_1;
   logic [31:0]        data_1;
   wire                bnn_en = (b_req&p_gnt)|((com_1==3'd6)&~p_gnt);

   logic [31:0]        b_rdata;
   logic [255:0]       rdata;
   logic [7:0]         cs_1;
   always_comb begin
      if(bnn_en_1)
        p_rdata[31:0] = b_rdata;
      else
        p_rdata[31:0] = (({32{cs_1[0]}}  & rdata[32*7+31:32*7+0])|
                         ({32{cs_1[1]}}  & rdata[32*6+31:32*6+0])|
                         ({32{cs_1[2]}}  & rdata[32*5+31:32*5+0])|
                         ({32{cs_1[3]}}  & rdata[32*4+31:32*4+0])|
                         ({32{cs_1[4]}}  & rdata[32*3+31:32*3+0])|
                         ({32{cs_1[5]}}  & rdata[32*2+31:32*2+0])|
                         ({32{cs_1[6]}}  & rdata[32*1+31:32*1+0])|
                         ({32{cs_1[7]}}  & rdata[32*0+31:32*0+0]) );
   end

   logic [11:0]        ram_addr;
   logic [7:0]         cs;
   integer             i;

   logic [1:0]         cnt;
   always_ff @(posedge clk)begin
      if(rst_n==1'b0)begin
         cnt<=2'd0;
         p_gnt<=1'b1;
         p_rvalid <= 0;
      end else if(p_req&p_gnt)begin
         p_rvalid <= 1;
      end else if(b_req&p_gnt)begin
         if(~(p_addr[12]&(p_addr[8]|(p_addr[3:2]!=2'b01))))begin // multi cycle ~(ini:seten:activ)
            p_rvalid <= 1;
            cnt<=2'd1;
            p_gnt<=1'b0;
         end else if(p_addr[12]&~p_addr[8]&(p_addr[3:2]==2'b11))begin // activ 1st
            p_rvalid <= 0;
            p_gnt <= 0;
         end else begin // ini:seten
            p_rvalid <= 1;
         end
      end else if((com_1==3'd6)&~p_gnt)begin // activ 2nd
         p_rvalid <= 1;
         p_gnt <= 1;
      end else if(cnt!=2'd0)begin
         p_rvalid <= 0;
         cnt<=cnt+1;
         if(cnt==2'd3)begin
            p_gnt<=1'b1;
         end
      end else begin
         p_rvalid <= 0;
      end
   end

   always_comb begin
      if(p_req&p_gnt)begin
         ram_addr = p_addr[16:5];
      end else if(b_req&p_gnt)begin
         ram_addr = {p_addr[11:2],2'b00};
      end else if(cnt!=0)begin
         ram_addr = {addr_1[9:0],cnt[1:0]};
      end else begin
         ram_addr = 10'hxx;
      end

      if(~p_gnt)begin
         cs=8'h00;
      end else if(p_req)begin
         for(i=0;i<8;i=i+1)begin
            cs[i]=(i==p_addr[4:2]);
         end
      end else if(b_req&(p_addr[12]==0))begin
         cs=8'hff;
      end else begin
         cs=8'h00;
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

// input stage
   always_ff @(posedge clk)begin
      if(cnt!=0)begin
         bs_1 <= cnt;
      end else if(bnn_en)begin
         bnn_en_1 <= 1'b1;
         bs_1 <= cnt;
         data_1[31:0] <= p_wdata;
         if(~p_addr[12])begin
            com_1[2:0] <= {~p_be[1],~p_be[2],1'b1};
            addr_1[9:0] <= p_addr[11:2];
         end else if(~p_addr[8])begin
            com_1[2:0] <= {p_addr[3:2],1'b0};
         end else begin
            com_1[2:0] <= 3'h4;
            addr_1[1:0] <= p_addr[3:2];
            bs_1[1:0] <= p_addr[5:4];
         end
      end else begin
         bnn_en_1 <= 1'b0;
         com_1[2:0] <= 3'b101;
         if(p_req)begin
            cs_1[7:0] <= cs[7:0];
         end else begin
            cs_1[7:0] <= 8'h00;
         end
      end
   end

   genvar              g;
   generate begin
      for(g=0;g<8;g=g+1) begin : estimate_block
         bnn_core core
            (.clk(clk), .com_1(com_1[2:0]), .bs_1(bs_1),
             .seten_1({(g=={addr_1[1:0],1'b0}),(g=={addr_1[1:0],1'b1})}),
             .data_1(data_1[31:0]), .param(rdata[32*(7-g)+31:32*(7-g)+0]),
             .activ({b_rdata[g+24],b_rdata[g+16],b_rdata[g+8],b_rdata[g]})
             );
      end : estimate_block
   end
   endgenerate

endmodule

module bnn_core
  (
   input logic        clk,
   input logic [2:0]  com_1,
   input logic [1:0]  bs_1,
   input logic [1:0]  seten_1,
   input logic [31:0] data_1,
   input logic [31:0] param,
   output logic [3:0] activ
   );

   integer            i;

   logic signed [0:3] [15:0] acc;
   logic signed [0:3] [15:0] pool;

   logic [2:0]               com_2;
   logic [1:0]               bs_2;
   logic [31:0]              data_2;
   logic [1:0]               seten_2;

// 1st stage
   always_ff @(posedge clk)begin
      com_2[2:0] <= com_1;
      bs_2[1:0]  <= bs_1;
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
           acc[0][15:0] <= data_2[15:0];
           acc[1][15:0] <= data_2[15:0];
           acc[2][15:0] <= data_2[15:0];
           acc[3][15:0] <= data_2[15:0];
           pool[0][15:0] <= 16'h8000;
           pool[1][15:0] <= 16'h8000;
           pool[2][15:0] <= 16'h8000;
           pool[3][15:0] <= 16'h8000;
        end
        3'd1 : begin //acc
           acc[bs_2][15:0] <= acc[bs_2][15:0] + sum[15:0];
        end
        3'd2 : begin //pool
           if($signed(acc[bs_2][15:0])>$signed(pool[bs_2][15:0]))begin
              pool[bs_2][15:0] <= acc[bs_2][15:0];
           end
           acc[bs_2][15:0] <= data_2[15:0];
        end
        3'd3 : begin //norm
           pool[bs_2][15:0] <= {pool[bs_2][12:0],3'h0} - data_2[15:0];
        end
        3'd4 : begin //seten
           if(seten_2==2'b10)
             acc[bs_2][15:0] <= data_2[31:16];
           if(seten_2==2'b01)
             acc[bs_2][15:0] <= data_2[15:0];
           if(seten_2==2'b11)
             acc[bs_2][15:0] <= 16'hxxxx;
        end
//        3'd6 : begin //activ
//           activ <= pool[15];
//        end
        3'd7 : begin //norm8
           pool[bs_2][15:0] <= pool[bs_2][15:0] - data_2[15:0];
        end
      endcase
   end
   assign activ[0] = pool[0][15];
   assign activ[1] = pool[1][15];
   assign activ[2] = pool[2][15];
   assign activ[3] = pool[3][15];
endmodule

module bnn_ram
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
        dout[32*7+31:32*7+0] <= mem[{addr,3'd0}];
        dout[32*6+31:32*6+0] <= mem[{addr,3'd1}];
        dout[32*5+31:32*5+0] <= mem[{addr,3'd2}];
        dout[32*4+31:32*4+0] <= mem[{addr,3'd3}];
        dout[32*3+31:32*3+0] <= mem[{addr,3'd4}];
        dout[32*2+31:32*2+0] <= mem[{addr,3'd5}];
        dout[32*1+31:32*1+0] <= mem[{addr,3'd6}];
        dout[32*0+31:32*0+0] <= mem[{addr,3'd7}];
     end
endmodule

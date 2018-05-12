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

   reg [1023:0]        param;

   bnn_ram ram0 (clk, p_addr[11:2], param); // en = (p_addr[12]==0)&bnn_en

   reg                 bnn_en_1;
   reg [2:0]           com_1;
   reg [3:0]           addr_1;
   reg [31:0]          data_1;
   reg                 busy=1'b0; //TEMP//TEMP// (p_addr!=100c)|(bnn_en==0)&(_1)&(_2)
   wire                bnn_en = p_req&~busy;

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
      end
   end

   genvar               g;
   generate begin
      for(g=0;g<32;g=g+1) begin : estimate_block
         bnn_core core
            (.clk(clk), .com_1(com_1[2:0]), .seten_1({(g=={addr_1,1'b0}),(g=={addr_1,1'b1})}),
             .data_1(data_1[31:0]), .param(param[32*(31-g)+31:32*(31-g)+0]),
             .activ(p_rdata[g])
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

module bnn_ram (clk, addr, dout);
   input clk;
   input [9:0] addr;
   output [1023:0] dout;
`include "param_bnn.v"
   reg [1023:0]    dout;

   always @(posedge clk)
     begin
        dout <= mem[addr];
     end
endmodule

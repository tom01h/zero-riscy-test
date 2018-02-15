
module zeroriscy_hex_tb();

   logic clk;
   logic reset;

   logic [255:0] reason = 0;
   logic [63:0]  trace_count = 0;

   logic         ss_req;
   logic         ss_we;
   logic [3:0]   ss_be = 4'b0001;
   logic [31:0]  ss_addr;
   logic [31:0]  ss_wdata;
   logic [31:0]  ss_rdata;

   logic         rreq;
   logic         wreq;
   logic         rvalid;
   logic         bvalid;

   always @ (posedge clk)begin
      rvalid <= rreq;
      bvalid <= wreq;
   end

   logic [31:0]  raddr;
   logic [31:0]  waddr;

   assign ss_addr = (ss_we) ? waddr : raddr;
   assign ss_req  = rreq|wreq;
   assign ss_we   =      wreq;

   zeroriscy_sim_top DUT
     (
      .clk(clk),
      .reset(reset),
      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Address
      .M_AXI_AWADDR(waddr),
      .M_AXI_AWLEN(),
      .M_AXI_AWSIZE(),
      .M_AXI_AWBURST(),
      .M_AXI_AWCACHE(),
      .M_AXI_AWVALID(wreq),
      .M_AXI_AWREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Data
      .M_AXI_WDATA(ss_wdata),
      .M_AXI_WSTRB(),
      .M_AXI_WLAST(),
      .M_AXI_WVALID(),
      .M_AXI_WREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Write Response
      .M_AXI_BRESP(2'b00),
      .M_AXI_BVALID(bvalid),
      .M_AXI_BREADY(),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Read Address
      .M_AXI_ARADDR(raddr),
      .M_AXI_ARLEN(),
      .M_AXI_ARSIZE(),
      .M_AXI_ARBURST(),
      .M_AXI_ARCACHE(),
      .M_AXI_ARVALID(rreq),
      .M_AXI_ARREADY(1'b1),

      ////////////////////////////////////////////////////////////////////////////
      // Master Interface Read Data
      .M_AXI_RDATA(ss_rdata),
      .M_AXI_RRESP(),
      .M_AXI_RLAST(),
      .M_AXI_RVALID(rvalid),
      .M_AXI_RREADY()
      );

   uart_sim uart_sim
     (
      .clk(clk),
      .resetn(~reset),

      .req(ss_req & (ss_addr[31:4]==28'h9a10_000)),
      .addr(ss_addr[31:0]),
      .we(ss_we),
      .be(ss_be[3:0]),
      .wdata(ss_wdata),
      .rdata(ss_rdata[31:0]),
      .gnt(),
      .rvalid(),
      .err()
   );

   initial begin
      clk = 0;
      reset = 1;
   end

   always #5 clk = !clk;

   int            fd, i;
   string         str, data;
   int            bytec, rtype;
   logic [17:0]   addr;
   logic [20:0]   base;
   logic [31:0]   op;

   initial begin
      base = 21'h00000;
      fd = $fopen("loadmem.ihex","r");
      if(fd==0) begin
         $display("ERROR!! loadmem.ihex not found");
         $stop;
      end
      $display("Loading Program");
      while($fgets(str, fd)) begin
         void'($sscanf(str, ":%02h%04h%02h%s", bytec, addr, rtype, data));
         if (rtype==0 &&
             (bytec == 16 || bytec == 12 || bytec == 8 || bytec == 4)) begin
            for (i=0; i<bytec/4; i = i+1) begin
               void'($sscanf(data, "%08h%s", op, str));
               if(base[20:19]==2'b00)begin
                 DUT.zeroriscy_i_sram.bmem[addr/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
               end else if(base[20:19]==2'b01)begin
                 DUT.zeroriscy_i_sram.imem[addr/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
               end else begin
                 DUT.zeroriscy_d_sram.dmem[(base[16:0]+addr)/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
               end
               data = str;
            end
         end else if (rtype==4) begin
            void'($sscanf(data, "%04h%02h", addr, data));
            base = {addr[4:0],16'h0};
         end else if ((rtype==3)|(rtype==5)) begin
         end else if (rtype==1) begin
            $display("Running ...");
         end else begin
            $display("ERROR!! Not support ihex format");
            $display(str);
            $stop;
         end
      end
      #100 reset = 0;
   end

   reg htif_pcr_resp_valid;
   reg [31:0] htif_pcr_resp_data;

   always @(posedge clk)begin
      htif_pcr_resp_valid <= DUT.zeroriscy_core.data_req_o & DUT.zeroriscy_core.data_we_o &
                             ((DUT.zeroriscy_core.data_addr_o == 32'h80001000)|
                              (DUT.zeroriscy_core.data_addr_o == 32'h80003000)|
                              (DUT.zeroriscy_core.data_addr_o == 32'h8017fffc));
      htif_pcr_resp_data <= DUT.zeroriscy_core.data_wdata_o;
   end

   always @(posedge clk)begin
      if(DUT.zeroriscy_core.data_req_o & DUT.zeroriscy_core.data_we_o & DUT.zeroriscy_core.data_gnt_i &
         (DUT.zeroriscy_core.data_addr_o == 32'h9a100004))
        $write("%s",DUT.zeroriscy_core.data_wdata_o[7:0]);
   end

   always @(posedge clk) begin
      trace_count = trace_count + 1;

      if (!reset) begin
         if (htif_pcr_resp_valid && htif_pcr_resp_data != 0) begin
            if (htif_pcr_resp_data == 1) begin
               $display("*** PASSED *** after %d simulation cycles", trace_count);
               $finish;
            end else begin
               $sformat(reason, "tohost = %d", htif_pcr_resp_data >> 1);
            end
         end
      end


      if (reason) begin
         $display("*** FAILED *** (%s) after %d simulation cycles", reason, trace_count);
         $finish;
      end
   end

endmodule


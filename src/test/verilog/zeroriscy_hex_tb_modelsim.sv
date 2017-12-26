
module zeroriscy_hex_tb();

//   wire start = (DUT.vscale.pipeline.PCmux.PC_DX==32'h00001a60);
//   wire stop  = (DUT.vscale.pipeline.PCmux.PC_DX==32'h00001a70);

   localparam hexfile_words = 8192;

   reg clk;
   reg reset;

   reg [255:0]                reason = 0;
   reg [1023:0]               loadmem = 0;
   reg [1023:0]               vpdfile = 0;
   reg [  63:0]               max_cycles = 0;
   reg [  63:0]               trace_count = 0;
   integer                    stderr = 32'h80000002;

   reg [127:0]                hexfile [hexfile_words-1:0];

   zeroriscy_sim_top DUT
     (
      .clk(clk),
      .reset(reset)
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
                 DUT.zeroriscy_dp_sram.bmem[addr/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
               end else if(base[20:19]==2'b01)begin
                 DUT.zeroriscy_dp_sram.imem[addr/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
               end else begin
                 DUT.zeroriscy_dp_sram.dmem[(base[16:0]+addr)/4+i] = {op[7:0],op[15:8],op[23:16],op[31:24]};
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
      if(DUT.zeroriscy_core.data_req_o & DUT.zeroriscy_core.data_we_o & (DUT.zeroriscy_core.data_addr_o == 32'h9a100000))
        $write("%s",DUT.zeroriscy_core.data_wdata_o[7:0]);
   end

   always @(posedge clk) begin
      trace_count = trace_count + 1;

      if (max_cycles > 0 && trace_count > max_cycles)
        reason = "timeout";

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


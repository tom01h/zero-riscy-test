
module zeroriscy_tb_fpga();

   logic clk;
   logic reset;

   design_1_wrapper top
     (
      .sys_clock(clk),
      .reset(~reset)
      );

   initial begin
      clk = 0;
      reset = 1;
   end

   always #5 clk = !clk;

   initial begin
      #100 reset = 0;
   end

endmodule


//Copyright 1986-2018 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2018.1 (win64) Build 2188600 Wed Apr  4 18:40:38 MDT 2018
//Date        : Sun May 20 10:33:34 2018
//Host        : DESKTOP-OLMGF8H running 64-bit major release  (build 9200)
//Command     : generate_target design_1_wrapper.bd
//Design      : design_1_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module design_1_wrapper
   (SDIO_CLK,
    SDIO_CMD,
    SDIO_DATA,
    SDIO_NODISK,
    reset,
    sys_clock,
    usb_uart_rxd,
    usb_uart_txd);
  output SDIO_CLK;
  inout SDIO_CMD;
  inout [3:0]SDIO_DATA;
  input SDIO_NODISK;
  input reset;
  input sys_clock;
  input usb_uart_rxd;
  output usb_uart_txd;

  wire SDIO_CLK;
  wire SDIO_CMD;
  wire [3:0]SDIO_DATA;
  wire SDIO_NODISK;
  wire reset;
  wire sys_clock;
  wire usb_uart_rxd;
  wire usb_uart_txd;

  design_1 design_1_i
       (.SDIO_CLK(SDIO_CLK),
        .SDIO_CMD(SDIO_CMD),
        .SDIO_DATA(SDIO_DATA),
        .SDIO_NODISK(SDIO_NODISK),
        .reset(reset),
        .sys_clock(sys_clock),
        .usb_uart_rxd(usb_uart_rxd),
        .usb_uart_txd(usb_uart_txd));
endmodule

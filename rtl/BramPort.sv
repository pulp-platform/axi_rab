`ifndef BRAM_PORT_SV
`define BRAM_PORT_SV

`include "log2.sv"

interface BramPort
  #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 32
  );

  logic                            Clk_C;
  logic                            Rst_R;
  logic                            En_S;
  logic  [ADDR_WIDTH-1:0]          Addr_S;
  logic  [DATA_WIDTH-1:0]          Rd_D;
  logic  [DATA_WIDTH-1:0]          Wr_D;
  logic  [(DATA_WIDTH/8)-1:0]      WrEn_S;

  modport Slave (
    input  Clk_C, Rst_R, En_S, Addr_S, Wr_D, WrEn_S,
    output Rd_D
  );

  modport Master (
    input  Rd_D,
    output Clk_C, Rst_R, En_S, Addr_S, Wr_D, WrEn_S
  );

endinterface

`endif // BRAM_PORT_SV

// vim: ts=2 sw=2 sts=2 et tw=100

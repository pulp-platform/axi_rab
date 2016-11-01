/**
 * BRAM Data Width Converter
 */

// `ifndef BRAM_DWC_SV
// `define BRAM_DWC_SV

//`include "BramPort.sv"
`include "log2.sv"

//module BramDwc
//
//  // Parameters {{{
//  #(
//    parameter BRAM_DATA_BITW  = 96,   // must be an integer multiple of EXT_DATA_BITW
//    parameter EXT_DATA_BITW   = 32
//  )
//  // }}}
//
//  // Ports {{{
//  (
//    BramPort.Master   Bram_PM,
//    BramPort.Slave    Ext_PS
//  );
//  // }}}
//
//  // Module-Wide Constants {{{
//  localparam integer ADDR_BITW        = 32;
//  localparam integer NUM_PAR_BRAMS    = BRAM_DATA_BITW / EXT_DATA_BITW;
//  localparam integer PAR_IDX_BITW     = log2(NUM_PAR_BRAMS);
//  localparam integer BRAM_DATA_BYTEW  = BRAM_DATA_BITW / 8;
//  // }}}
//
//  // Signal Declarations {{{
//  logic [EXT_DATA_BITW-1:0]   Rd_D;
//  logic [EXT_DATA_BITW-1:0]   Wr_D;
//  logic [ADDR_BITW-1:0]       WordAddr_S;
//  logic [ADDR_BITW-1:0]       ParWordIdx_S;
//  logic [PAR_IDX_BITW-1:0]    ParIdx_S;
//  logic [ADDR_BITW-1:0]       BramAddr_S;
//  logic [BRAM_DATA_BYTEW-1:0] WrEn_S;
//  // }}}
//
//  // BRAM Interface Connection {{{
//  //TODO: stale code, clean up on time
//  //BramPort #(
//  //    .DATA_WIDTH(BRAM_DATA_BITW),
//  //    .ADDR_WIDTH(ADDR_BITW)
//  //  ) Bram_P(Bram_PM);
//
//  assign Bram_PM.Clk_C  = Ext_PS.Clk_C;
//  assign Bram_PM.Rst_R  = Ext_PS.Rst_R;
//  assign Bram_PM.En_S   = Ext_PS.En_S;
//  // }}}
//
//  //assign Bram_PM.Addr_S = '0;
//  //assign Bram_PM.Wr_D   = '0;
//  //assign Bram_PM.WrEn_S = '0;
//
//  //assign Ext_PS.Rd_D = '0;
//
//  // Address Resolution {{{
//  assign WordAddr_S     = Ext_PS.Addr_S >> 2;
//  assign ParWordIdx_S   = WordAddr_S / NUM_PAR_BRAMS;
//  assign BramAddr_S     = (ParWordIdx_S << 2) + Ext_PS.Addr_S[1:0];
//  assign Bram_PM.Addr_S = BramAddr_S;
//
//  assign ParIdx_S       = WordAddr_S % NUM_PAR_BRAMS;
//  // }}}
//
//  // Data and Write Enable Resolution {{{
//  shortint BramBitLow    = EXT_DATA_BITW * ParIdx_S;
//  shortint BramBitHigh   = BramBitLow + EXT_DATA_BITW - 1;
//  shortint BramByteLow   = BramBitLow / 8;
//  shortint BramByteHigh  = BramBitHigh / 8;
//
//  assign Ext_PS.Rd_D  = Bram_PM.Rd_D[BramBitHigh:BramBitLow];
//
//  always_comb begin
//    Bram_PM.WrEn_S = '0;
//    Bram_PM.WrEn_S[BramByteHigh:BramByteLow] = Ext_PS.WrEn_S;
//
//    Bram_PM.Wr_D = '0;
//    Bram_PM.Wr_D[BramBitHigh:BramBitLow] = Wr_D;
//  end
//  // }}}
//
//endmodule

// `endif // BRAM_DWC_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker

/**
 * BRAM Data Width Converter
 *
 * This module performs data width conversion between a narrow master and a wide slave interface.
 *
 * Port Description:
 *  FromMaster_PS   Slave BRAM Port interface through which master control signals go to the BRAM.
 *  ToSlave_PM      Master BRAM Port interface at which the BRAM is connected.
 *
 * The master interface must be narrower than the slave interface.  The reverse situation would
 * require handshaking and buffering and is not supported by the simple BRAM Port interface.
 *
 * Copyright (c) 2016 Integrated Systems Laboratory, ETH Zurich.  This is free software under the
 * terms of the GNU General Public License as published by the Free Software Foundation, either
 * version 3 of the License, or (at your option) any later version.  This software is distributed
 * without any warranty; without even the implied warranty of merchantability or fitness for
 * a particular purpose.
 *
 * Current Maintainers:
 * - Andreas Kurth  <andkurt@ee.ethz.ch>
 * - Pirmin Vogel   <vogelpi@iis.ee.ethz.ch>
 */

`ifndef BRAM_DWC_SV
`define BRAM_DWC_SV

`include "BramPort.sv"

import CfMath::ceil_div, CfMath::log2;

module BramDwc

  // Ports {{{
  (
    BramPort.Slave    FromMaster_PS,
    BramPort.Master   ToSlave_PM
  );
  // }}}

  // Module-Wide Constants {{{
  localparam integer  FROM_DATA_BITW      = $size(FromMaster_PS.Wr_D);
  localparam integer  FROM_DATA_BYTEW     = FROM_DATA_BITW/8;
  localparam integer  FROM_ADDR_WORD_BITO = log2(FROM_DATA_BYTEW);
  localparam integer  FROM_ADDR_WORD_BITW = $size(FromMaster_PS.Addr_S) - FROM_ADDR_WORD_BITO;

  localparam integer  TO_DATA_BITW        = $size(ToSlave_PM.Wr_D);
  localparam integer  TO_DATA_BYTEW       = TO_DATA_BITW/8;
  localparam integer  TO_ADDR_WORD_BITO   = log2(TO_DATA_BYTEW);
  localparam integer  TO_ADDR_WORD_BITW   = $size(ToSlave_PM.Addr_S) - TO_ADDR_WORD_BITO;

  localparam integer  PAR_IDX_MAX_VAL     = ceil_div(TO_DATA_BITW, FROM_DATA_BITW) - 1;
  localparam integer  PAR_IDX_BITW        = log2(PAR_IDX_MAX_VAL+1);
  // }}}

  // Initial Assertions {{{
  initial begin
    assert (TO_DATA_BITW >= FROM_DATA_BITW)
      else $fatal(1, "Downconversion of the data bitwidth from master to slave is not possible!");
  end
  // }}}

  // Pass clock, reset, and enable through. {{{
  assign ToSlave_PM.Clk_C = FromMaster_PS.Clk_C;
  assign ToSlave_PM.Rst_R = FromMaster_PS.Rst_R;
  assign ToSlave_PM.En_S  = FromMaster_PS.En_S;
  // }}}

  // Data Width Conversion {{{

  logic [FROM_ADDR_WORD_BITW-1:0] FromWordAddr_S;
  assign FromWordAddr_S
      = FromMaster_PS.Addr_S[(FROM_ADDR_WORD_BITW-1)+FROM_ADDR_WORD_BITO:FROM_ADDR_WORD_BITO];

  logic [TO_ADDR_WORD_BITW-1:0] ToWordAddr_S;
  assign ToWordAddr_S = FromWordAddr_S / (PAR_IDX_MAX_VAL+1);

  always_comb begin
    ToSlave_PM.Addr_S = '0;
    ToSlave_PM.Addr_S[(TO_ADDR_WORD_BITW-1)+TO_ADDR_WORD_BITO:TO_ADDR_WORD_BITO] = ToWordAddr_S;
  end

  logic [PAR_IDX_BITW-1:0] ParIdx_S;
  assign ParIdx_S = FromWordAddr_S % (PAR_IDX_MAX_VAL+1);

  logic [PAR_IDX_MAX_VAL:0] [FROM_DATA_BITW-1:0]  Rd_D;
  genvar p;
  for (p = 0; p <= PAR_IDX_MAX_VAL; p++) begin
    localparam integer TO_BYTE_LOW  = FROM_DATA_BYTEW*p;
    localparam integer TO_BYTE_HIGH = TO_BYTE_LOW + (FROM_DATA_BYTEW-1);
    localparam integer TO_BIT_LOW   = FROM_DATA_BITW*p;
    localparam integer TO_BIT_HIGH  = TO_BIT_LOW + (FROM_DATA_BITW-1);
    always_comb begin
      if (ParIdx_S == p) begin
        ToSlave_PM.WrEn_S[TO_BYTE_HIGH:TO_BYTE_LOW] = FromMaster_PS.WrEn_S;
      end else begin
        ToSlave_PM.WrEn_S[TO_BYTE_HIGH:TO_BYTE_LOW] = '0;
      end
    end
    assign Rd_D[p] = ToSlave_PM.Rd_D[TO_BIT_HIGH:TO_BIT_LOW];
    assign ToSlave_PM.Wr_D[TO_BIT_HIGH:TO_BIT_LOW] = FromMaster_PS.Wr_D;
  end
  assign FromMaster_PS.Rd_D = Rd_D[ParIdx_S];

  // }}}

endmodule

`endif // BRAM_DWC_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker tw=100

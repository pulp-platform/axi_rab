/**
 * True Dual-Port BRAM Array
 *
 * This module contains a two-dimensional array of True Dual-Port BRAM cells.  The array is
 * `NUM_PAR_BRAMS` wide and `NUM_SER_BRAMS` deep.  Each BRAM cell is 32 bit wide and 1024 entries
 * deep.  Thus, the data ports exposed by this module are `32*NUM_PAR_BRAMS` bit wide, and the total
 * number of addressable entries is `1024*NUM_SER_BRAMS`.  Both ports can be operated independently
 * and asynchronously; the behavior on access collisions is specified in the Xilinx Block Memory
 * Generator Product Guide (PG058).
 */

`ifndef TDP_BRAM_ARRAY_SV
`define TDP_BRAM_ARRAY_SV

`include "BramPort.sv"
`include "log2.sv"

module TdpBramArray

  // Parameters {{{
  #(
    parameter NUM_PAR_BRAMS = 3,
    parameter NUM_SER_BRAMS = 8
  )
  // }}}

  // Ports {{{
  (
    BramPort.Slave  A_PS,
    BramPort.Slave  B_PS
  );
  // }}}

  // Module-Wide Constants {{{
  localparam integer BRAM_BITW      = 32;
  localparam integer BRAM_BYTEW     = BRAM_BITW / 8;
  localparam integer NUM_BRAM_WORDS = 1024;

  localparam integer ARR_BITW       = BRAM_BITW  * NUM_PAR_BRAMS;
  localparam integer ARR_BYTEW      = BRAM_BYTEW * NUM_PAR_BRAMS;

  localparam integer WORD_IDX_BITW  = log2(NUM_BRAM_WORDS);
  // }}}

  // Signal Declarations {{{
  logic [NUM_SER_BRAMS-1:0] [ARR_BITW-1:0]        ARd_D, BRd_D;

  logic                     [30-1:0]              WordAddrA_S,    WordAddrB_S;
  logic                     [30-1:0]              SerIdxA_S,      SerIdxB_S;
  logic                     [WORD_IDX_BITW-1:0]   WordIdxA_S,     WordIdxB_S;
  // }}}

  // Resolve (Linear) Address to Serial (BRAM), Word Index and Address of RAMs {{{
  always_comb begin
    WordAddrA_S       = '0;
    WordAddrB_S       = '0;
    WordAddrA_S[13:0] = A_PS.Addr_S[15:2];
    WordAddrB_S[13:0] = B_PS.Addr_S[15:2];
  end

  assign SerIdxA_S = WordAddrA_S / NUM_BRAM_WORDS;
  assign SerIdxB_S = WordAddrB_S / NUM_BRAM_WORDS;

  assign WordIdxA_S = WordAddrA_S % NUM_BRAM_WORDS;
  assign WordIdxB_S = WordAddrB_S % NUM_BRAM_WORDS;

  always @ (posedge A_PS.Clk_C) begin
    assert (SerIdxA_S < NUM_SER_BRAMS) else $error("Serial index on port A out of bounds!");
    assert (WordIdxA_S < NUM_BRAM_WORDS) else $error("Word index on port A out of bounds!");
  end
  always @ (posedge B_PS.Clk_C) begin
    assert (SerIdxB_S < NUM_SER_BRAMS) else $error("Serial index on port B out of bounds!");
    assert (WordIdxB_S < NUM_BRAM_WORDS) else $error("Word index on port B out of bounds!");
  end

  // }}}

  // BRAM Instantiation, Signal Resolution, and Port Assignment {{{
  genvar s, p;
  for (s = 0; s < NUM_SER_BRAMS; s++) begin
    for (p = 0; p < NUM_PAR_BRAMS; p++) begin

      // Instance-Specific Constants {{{
      localparam integer WORD_BIT_LOW   = BRAM_BITW *p;
      localparam integer WORD_BIT_HIGH  = WORD_BIT_LOW  + (BRAM_BITW -1);
      localparam integer WORD_BYTE_LOW  = BRAM_BYTEW*p;
      localparam integer WORD_BYTE_HIGH = WORD_BYTE_LOW + (BRAM_BYTEW-1);
      // }}}

      // Write-Enable Resolution {{{
      logic [  BRAM_BYTEW-1:0]  WrEnA_S;
      logic [2*BRAM_BYTEW-1:0]  WrEnB_S;
      always_comb begin
        WrEnA_S = '0;
        WrEnB_S = '0;
        if (SerIdxA_S == s) begin
          WrEnA_S = A_PS.WrEn_S[WORD_BYTE_HIGH:WORD_BYTE_LOW];
        end
        if (SerIdxB_S == s) begin
          WrEnB_S[3:0] = B_PS.WrEn_S[WORD_BYTE_HIGH:WORD_BYTE_LOW];
        end
      end
      // }}}

      // BRAM_TDP_MACRO Declaration {{{
      // BRAM_TDP_MACRO: True Dual Port RAM
      //                 Virtex-7
      // Xilinx HDL Language Template, version 2016.1
      BRAM_TDP_MACRO #(
        .BRAM_SIZE("36Kb"), // Target BRAM: "18Kb" or "36Kb"
        .DEVICE("7SERIES"), // Target device: "7SERIES"
        .DOA_REG(0),        // Optional port A output register (0 or 1)
        .DOB_REG(0),        // Optional port B output register (0 or 1)
        .INIT_A(36'h000000000), // Initial values on port A output port
        .INIT_B(36'h000000000), // Initial values on port B output port
        .INIT_FILE ("NONE"),
        .READ_WIDTH_A (32),   // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
        .READ_WIDTH_B (32),   // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
        .SIM_COLLISION_CHECK ("ALL"), // Collision check enable "ALL", "WARNING_ONLY",
                                      //   "GENERATE_X_ONLY" or "NONE"
        .SRVAL_A(36'h00000000), // Set/Reset value for port A output
        .SRVAL_B(36'h00000000), // Set/Reset value for port B output
        .WRITE_MODE_A("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
        .WRITE_MODE_B("WRITE_FIRST"), // "WRITE_FIRST", "READ_FIRST", or "NO_CHANGE"
        .WRITE_WIDTH_A(32), // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
        .WRITE_WIDTH_B(32), // Valid values are 1-36 (19-36 only valid when BRAM_SIZE="36Kb")
        .INIT_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_10(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_11(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_12(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_13(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_14(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_15(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_16(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_17(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_18(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_19(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_1F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_20(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_21(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_22(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_23(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_24(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_25(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_26(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_27(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_28(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_29(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_2F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_30(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_31(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_32(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_33(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_34(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_35(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_36(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_37(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_38(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_39(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_3F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // The next set of INIT_xx are valid when configured as 36Kb
        .INIT_40(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_41(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_42(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_43(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_44(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_45(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_46(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_47(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_48(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_49(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_4F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_50(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_51(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_52(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_53(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_54(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_55(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_56(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_57(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_58(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_59(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_5F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_60(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_61(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_62(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_63(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_64(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_65(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_66(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_67(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_68(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_69(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_6F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_70(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_71(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_72(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_73(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_74(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_75(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_76(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_77(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_78(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_79(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INIT_7F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // The next set of INITP_xx are for the parity bits
        .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // The next set of INITP_xx are valid when configured as 36Kb
        .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000)
      )
      // }}}

      // BRAM_TDP_MACRO Instantation {{{
      BRAM_TDP_MACRO_inst (

        // Port A {{{
        .CLKA(A_PS.Clk_C),                            //  1-bit inp: clock
        .RSTA(A_PS.Rst_R),                            //  1-bit inp: reset (active high)
        .ENA(A_PS.En_S),                              //  1-bit inp: enable
        .REGCEA(1'b0),                                //  1-bit inp: output register enable
        .ADDRA(WordIdxA_S),                           // 10-bit inp: word-wise address
        .DOA(ARd_D[s][WORD_BIT_HIGH:WORD_BIT_LOW]),   // 32-bit oup: data output
        .DIA(A_PS.Wr_D[WORD_BIT_HIGH:WORD_BIT_LOW]),  // 32-bit inp: data input
        .WEA(WrEnA_S),                                //  4-bit inp: byte-wise write enable
        // }}}

        // Port B {{{
        .CLKB(B_PS.Clk_C),                            //  1-bit inp: clock
        .RSTB(B_PS.Rst_R),                            //  1-bit inp: reset (active high)
        .ENB(B_PS.En_S),                              //  1-bit inp: enable
        .REGCEB(1'b0),                                //  1-bit inp: output register enable
        .ADDRB(WordIdxB_S),                           // 10-bit inp: word-wise address
        .DOB(BRd_D[s][WORD_BIT_HIGH:WORD_BIT_LOW]),   // 32-bit oup: data output
        .DIB(B_PS.Wr_D[WORD_BIT_HIGH:WORD_BIT_LOW]),  // 32-bit inp: data input
        .WEB(WrEnB_S)                                 //  4-bit inp: byte-wise write enable
        // }}}

      );
      // }}}

    end
  end
  // }}}

  // Output Multiplexer {{{
  assign A_PS.Rd_D = ARd_D[SerIdxA_S];
  assign B_PS.Rd_D = BRd_D[SerIdxB_S];
  // }}}

endmodule

`endif // TDP_BRAM_ARRAY_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker tw=100

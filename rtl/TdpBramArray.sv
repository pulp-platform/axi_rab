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
    parameter NUM_SER_BRAMS = 12
  )
  // }}}

  // Ports {{{
  (
    BramPort.Slave  A_PS,
    BramPort.Slave  B_PS
  );
  // }}}

  // Module-Wide Constants {{{
  localparam integer BRAM_BIT_WIDTH     = 32;
  localparam integer BRAM_BYTE_WIDTH    = BRAM_BIT_WIDTH / 8;
  localparam integer NUM_BRAM_WORDS     = 1024;

  localparam integer ARR_BIT_WIDTH      = BRAM_BIT_WIDTH  * NUM_PAR_BRAMS;
  localparam integer ARR_BYTE_WIDTH     = BRAM_BYTE_WIDTH * NUM_PAR_BRAMS;

  localparam integer PAR_BRAM_IDX_WIDTH = log2(NUM_PAR_BRAMS);
  localparam integer WORD_IDX_WIDTH     = log2(NUM_BRAM_WORDS);
  // }}}

  // Signal Declarations {{{
  logic [NUM_SER_BRAMS-1:0] [ARR_BIT_WIDTH-1:0]       ARd_D, BRd_D;

  logic                     [30-1:0]                  WordAddrA_S,    WordAddrB_S;
  logic                     [30-1:0]                  ParWordIdxA_S,  ParWordIdxB_S;
  logic                     [30-1:0]                  SerIdxA_S,      SerIdxB_S;
  logic                     [WORD_IDX_WIDTH-1:0]      WordIdxA_S,     WordIdxB_S;
  // }}}

  // Resolve (Linear) Address to Serial (BRAM) and Word Index {{{
  assign WordAddrA_S = A_PS.Addr_S >> 2;
  assign WordAddrB_S = B_PS.Addr_S >> 2;

  assign ParWordIdxA_S = WordAddrA_S / NUM_PAR_BRAMS;
  assign ParWordIdxB_S = WordAddrB_S / NUM_PAR_BRAMS;

  assign SerIdxA_S = ParWordIdxA_S / NUM_BRAM_WORDS;
  assign SerIdxB_S = ParWordIdxB_S / NUM_BRAM_WORDS;

  assign WordIdxA_S = ParWordIdxA_S % NUM_BRAM_WORDS;
  assign WordIdxB_S = ParWordIdxB_S % NUM_BRAM_WORDS;

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
      localparam integer WORD_BIT_HIGH  = ARR_BIT_WIDTH   - BRAM_BIT_WIDTH*p  - 1;
      localparam integer WORD_BIT_LOW   = WORD_BIT_HIGH   - BRAM_BIT_WIDTH-1;
      localparam integer WORD_BYTE_HIGH = ARR_BYTE_WIDTH  - BRAM_BYTE_WIDTH*p - 1;
      localparam integer WORD_BYTE_LOW  = WORD_BYTE_HIGH  - BRAM_BYTE_WIDTH-1;
      // }}}

      // Write-Enable Resolution {{{
      logic [BRAM_BYTE_WIDTH-1:0] WrEnA_S, WrEnB_S;
      always_comb begin
        WrEnA_S = 0;
        WrEnB_S = 0;
        if (SerIdxA_S == s) begin
          WrEnA_S = A_PS.WrEn_S[WORD_BYTE_HIGH:WORD_BYTE_LOW];
        end
        if (SerIdxB_S == s) begin
          WrEnB_S = B_PS.WrEn_S[WORD_BYTE_HIGH:WORD_BYTE_LOW];
        end
      end
      // }}}

      // Address Resolution {{{
      logic [16-1:0] AddrA_S, AddrB_S;
      assign AddrA_S = (WordIdxA_S << 2) + A_PS.Addr_S[1:0];
      assign AddrB_S = (WordIdxB_S << 2) + B_PS.Addr_S[1:0];
      // }}}

      // RAMB36E1 Declaration {{{
      // RAMB36E1: 36K-bit Configurable Synchronous Block RAM
      //           Virtex-7
      // Xilinx HDL Language Template, version 2015.1
      RAMB36E1 #(
        // Address Collision Mode: "PERFORMANCE" or "DELAYED_WRITE"
        .RDADDR_COLLISION_HWCONFIG("DELAYED_WRITE"),
        // Collision check: Values ("ALL", "WARNING_ONLY", "GENERATE_X_ONLY" or "NONE")
        .SIM_COLLISION_CHECK("ALL"),
        // DOA_REG, DOB_REG: Optional output register (0 or 1)
        .DOA_REG(0),
        .DOB_REG(0),
        // Enable ECC decoder
        .EN_ECC_READ("FALSE"),
        // Enable ECC encoder
        .EN_ECC_WRITE("FALSE"),
        // INITP_00 to INITP_0F: Initial contents of the parity memory array
        .INITP_00(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_01(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_02(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_03(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_04(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_05(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_06(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_07(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_08(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_09(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0A(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0B(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0C(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0D(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0E(256'h0000000000000000000000000000000000000000000000000000000000000000),
        .INITP_0F(256'h0000000000000000000000000000000000000000000000000000000000000000),
        // INIT_00 to INIT_7F: Initial contents of the data memory array
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
        // INIT_A, INIT_B: Initial values on output ports
        .INIT_A(36'h000000000),
        .INIT_B(36'h000000000),
        // Initialization File: RAM initialization file
        .INIT_FILE("NONE"),
        // RAM Mode: "SDP" or "TDP"
        .RAM_MODE("TDP"),
        // RAM_EXTENSION_A, RAM_EXTENSION_B: Selects cascade mode ("UPPER", "LOWER", or "NONE")
        .RAM_EXTENSION_A("NONE"),
        .RAM_EXTENSION_B("NONE"),
        // READ_WIDTH_A/B, WRITE_WIDTH_A/B: Read/write width per port
        .READ_WIDTH_A(32),  // 0-72
        .READ_WIDTH_B(32),  // 0-36
        .WRITE_WIDTH_A(32), // 0-36
        .WRITE_WIDTH_B(32), // 0-72
        // RSTREG_PRIORITY_A, RSTREG_PRIORITY_B: Reset or enable priority ("RSTREG" or "REGCE")
        .RSTREG_PRIORITY_A("RSTREG"),
        .RSTREG_PRIORITY_B("RSTREG"),
        // SRVAL_A, SRVAL_B: Set/reset value for output
        .SRVAL_A(36'h000000000),
        .SRVAL_B(36'h000000000),
        // Simulation Device: Must be set to "7SERIES" for simulation behavior
        .SIM_DEVICE("7SERIES"),
        // WriteMode: Value on output upon a write ("WRITE_FIRST", "READ_FIRST", or "NO_CHANGE")
        .WRITE_MODE_A("WRITE_FIRST"),
        .WRITE_MODE_B("WRITE_FIRST")
      )
      // }}}

      // RAMB36E1 Instantiation {{{
      RAMB36E1_inst (

        // Cascade Ports (to create 64kx1) {{{
        .CASCADEINA(1'b0),    //  1-bit inp: A port cascade
        .CASCADEOUTA(),       //  1-bit oup: A port cascade
        .CASCADEINB(1'b0),    //  1-bit inp: B port cascade
        .CASCADEOUTB(),       //  1-bit oup: B port cascade
        // }}}

        // ECC Ports {{{
        .DBITERR(),           //  1-bit oup: double bit error status
        .ECCPARITY(),         //  8-bit oup: generated error correction parity
        .RDADDRECC(),         //  9-bit oup: ECC read address
        .SBITERR(),           //  1-bit oup: single bit error status
        .INJECTDBITERR(1'b0), //  1-bit inp: inject a double bit error
        .INJECTSBITERR(1'b0), //  1-bit inp: inject a single bit error
        // }}}

        // BRAM Port A {{{
        .CLKARDCLK(A_PS.Clk_C),                         //  1-bit inp: clock
        .RSTRAMARSTRAM(A_PS.Rst_R),                     //  1-bit inp: reset (active high)
        .RSTREGARSTREG(A_PS.Rst_R),                     //  1-bit inp: register reset (active high)
        .ENARDEN(A_PS.En_S),                            //  1-bit inp: enable
        .REGCEAREGCE(A_PS.En_S),                        //  1-bit inp: register enable
        .WEA(WrEnA_S),                                  //  4-bit inp: byte-wise write enable
        .ADDRARDADDR(AddrA_S),                          // 16-bit inp: address
        .DIADI(A_PS.Wr_D[WORD_BIT_HIGH:WORD_BIT_LOW]),  // 32-bit inp: data
        .DIPADIP(4'b0000),                              //  4-bit inp: parity
        .DOADO(ARd_D[s][WORD_BIT_HIGH:WORD_BIT_LOW]),   // 32-bit oup: data
        .DOPADOP(),                                     //  4-bit oup: parity
        // }}}

        // BRAM Port B {{{
        .CLKBWRCLK(B_PS.Clk_C),                         //  1-bit inp: clock
        .RSTRAMB(B_PS.Rst_R),                           //  1-bit inp: reset (active high)
        .RSTREGB(B_PS.Rst_R),                           //  1-bit inp: register reset (active high)
        .ENBWREN(B_PS.En_S),                            //  1-bit inp: enable
        .REGCEB(B_PS.En_S),                             //  1-bit inp: register enable
        .WEBWE(WrEnB_S),                                //  4-bit inp: byte-wise write enable
        .ADDRBWRADDR(AddrB_S),                          // 16-bit inp: address
        .DIBDI(B_PS.Wr_D[WORD_BIT_HIGH:WORD_BIT_LOW]),  // 32-bit inp: data
        .DIPBDIP(4'b0000),                              //  4-bit inp: parity
        .DOBDO(BRd_D[s][WORD_BIT_HIGH:WORD_BIT_LOW]),   // 32-bit oup: data
        .DOPBDOP()                                      //  4-bit oup: parity
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

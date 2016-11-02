/**
 * AXI BRAM Logger
 *
 * TODO:
 * - module description
 */

`ifndef AXI_BRAM_LOGGER_SV
`define AXI_BRAM_LOGGER_SV

`include "BramPort.sv"
`include "TdpBramArray.sv"

module AxiBramLogger

  // Parameters {{{
  #(
    parameter AXI_ADDR_BITW     = 32,
    parameter AXI_ID_BITW       = 8,
    parameter AXI_LEN_BITW      = 8,

    parameter TIMESTAMP_BITW    = 32,

    parameter LOGGING_DATA_BITW = 96,
    parameter NUM_PAR_BRAMS     = 3,    // must equal ceil(LOGGING_DATA_BITW/32)

    parameter NUM_SER_BRAMS     = 12
  )
  // }}}

  // Ports {{{
  (
    input  logic                        Clk_CI,
    input  logic                        Rst_RBI,

    // AXI Input
    input  logic                        AxiValid_SI,
    input  logic                        AxiReady_SI,
    input  logic  [AXI_ID_BITW-1:0]     AxiId_DI,
    input  logic  [AXI_ADDR_BITW-1:0]   AxiAddr_DI,
    input  logic  [AXI_LEN_BITW-1:0]    AxiLen_DI,

    // Control Input
    input  logic                        Clear_SI,

    // Status Output
    output logic                        Full_SO,

    // Interface to Internal BRAM
    BramPort.Slave                      Bram_PS
  );
  // }}}

  // Module-Wide Constants {{{
  localparam integer LOGGING_DATA_BYTEW = LOGGING_DATA_BITW / 8;
  localparam integer LOGGING_ADDR_BITW  = log2(1024*NUM_SER_BRAMS) + 2; // +2 for words
  localparam integer LOGGING_CNT_MAX    = 1024*NUM_SER_BRAMS - 1;
  localparam integer AXI_ID_LOW         = 64;
  localparam integer AXI_ID_HIGH        = AXI_ID_LOW  + AXI_ID_BITW   - 1;
  localparam integer AXI_LEN_LOW        = AXI_ID_HIGH + 1;
  localparam integer AXI_LEN_HIGH       = AXI_LEN_LOW + AXI_LEN_BITW  - 1;
  // }}}

  // Signal Declarations {{{
  logic                           Rst_R;

  enum reg [1:0]  {READY, CLEARING, FULL}
                                  State_SP,     State_SN;

  reg   [LOGGING_ADDR_BITW-3:0]   WrCntA_SP,    WrCntA_SN;
  logic [LOGGING_DATA_BITW-1:0]   WrA_D;
  logic [LOGGING_DATA_BYTEW-1:0]  WrEnA_S;

  reg   [TIMESTAMP_BITW-1:0]      Timestamp_SP, Timestamp_SN;
  // }}}

  assign Rst_R = ~Rst_RBI;

  // Internal BRAM Interfaces {{{
  BramPort #(
      .DATA_WIDTH(LOGGING_DATA_BITW),
      .ADDR_WIDTH(LOGGING_ADDR_BITW)
    ) BramLog_P ();
  assign BramLog_P.Clk_C  = Clk_CI;
  assign BramLog_P.Rst_R  = Rst_R;
  assign BramLog_P.En_S   = WrEnA_S;
  always_comb begin
    BramLog_P.Addr_S = '0;
    BramLog_P.Addr_S[LOGGING_ADDR_BITW-1:0] = (WrCntA_SP << 2);
  end
  assign BramLog_P.Wr_D   = WrA_D;
  assign BramLog_P.WrEn_S = WrEnA_S;

  BramPort #(
      .DATA_WIDTH(LOGGING_DATA_BITW),
      .ADDR_WIDTH(32)
    ) BramDwc_P ();
  assign BramDwc_P.Clk_C   = Bram_PS.Clk_C;
  assign BramDwc_P.Rst_R   = Bram_PS.Rst_R;
  assign BramDwc_P.En_S    = Bram_PS.En_S;
  // }}}

  // Instantiation of True Dual-Port BRAM Array {{{
  TdpBramArray #(
      .NUM_PAR_BRAMS(NUM_PAR_BRAMS),
      .NUM_SER_BRAMS(NUM_SER_BRAMS)
    ) bramArr (
      .A_PS(BramLog_P),
      .B_PS(BramDwc_P)
    );
  // }}}

  // Data Width Conversion {{{
  localparam integer          EXT_DATA_BITW   = 32;
  localparam integer          EXT_DATA_BYTEW  = EXT_DATA_BITW/8;
  localparam integer          ADDR_BITW       = 32;
  localparam integer          PAR_IDX_BITW    = log2(NUM_PAR_BRAMS);
  logic [ADDR_BITW-1:0]       WordAddr_S;
  always_comb begin
    WordAddr_S = '0;
    WordAddr_S[17:0] = Bram_PS.Addr_S[19:2];
  end
  logic [ADDR_BITW-1:0]       ParWordIdx_S;
  assign ParWordIdx_S = WordAddr_S / NUM_PAR_BRAMS;
  logic [PAR_IDX_BITW-1:0]    ParIdx_S;
  assign ParIdx_S = WordAddr_S % NUM_PAR_BRAMS;
  logic [ADDR_BITW-1:0]       BramAddr_S;
  assign BramAddr_S = (ParWordIdx_S << 2) + Bram_PS.Addr_S[1:0];
  logic [NUM_PAR_BRAMS-1:0] [EXT_DATA_BITW-1:0] Rd_D;
  assign BramDwc_P.Addr_S = BramAddr_S;
  genvar p;
  for (p = 0; p < NUM_PAR_BRAMS; p++) begin
    localparam integer BRAM_BYTE_LOW  = EXT_DATA_BYTEW*p;
    localparam integer BRAM_BYTE_HIGH = BRAM_BYTE_LOW + (EXT_DATA_BYTEW-1);
    localparam integer BRAM_BIT_LOW   = EXT_DATA_BITW*p;
    localparam integer BRAM_BIT_HIGH  = BRAM_BIT_LOW  + (EXT_DATA_BITW-1);
    always_comb begin
      if (ParIdx_S == p) begin
        BramDwc_P.WrEn_S[BRAM_BYTE_HIGH:BRAM_BYTE_LOW] = Bram_PS.WrEn_S;
      end else begin
        BramDwc_P.WrEn_S[BRAM_BYTE_HIGH:BRAM_BYTE_LOW] = '0;
      end
    end
    assign Rd_D[p] = BramDwc_P.Rd_D[BRAM_BIT_HIGH:BRAM_BIT_LOW];
    assign BramDwc_P.Wr_D[BRAM_BIT_HIGH:BRAM_BIT_LOW] = Bram_PS.Wr_D;
  end
  assign Bram_PS.Rd_D = Rd_D[ParIdx_S];
  // }}}

  // Instantiation of BRAM Data Width Converter {{{
  // TODO: Remove this section if you decide to keep the current data width conversion
  // implementation.  In this case, also remove `BramDwc.sv`.
  //BramDwc #(
  //    .BRAM_DATA_BITW(LOGGING_DATA_BITW),
  //    .EXT_DATA_BITW(32)
  //  ) bramDwc (
  //    .Bram_PM(BramDwc_P),
  //    .Ext_PS(Bram_PS)
  //  );
  //assign BramDwc_P.Clk_C  = Bram_PS.Clk_C;
  //assign BramDwc_P.Rst_R  = Bram_PS.Rst_R;
  //assign BramDwc_P.En_S   = Bram_PS.En_S;
  //assign BramDwc_P.Addr_S = '0;
  //assign BramDwc_P.Wr_D   = '0;
  //assign BramDwc_P.WrEn_S = '0;
  //assign Bram_PS.Rd_D     = '0;
  // }}}

  // Control FSM {{{

  always_comb begin
    // Default Assignments
    Full_SO   = 0;
    WrCntA_SN = WrCntA_SP;
    WrEnA_S   = '0;
    State_SN  = State_SP;

    case (State_SP)

      READY: begin
        if (AxiValid_SI && AxiReady_SI && ~Clear_SI) begin
          WrCntA_SN = WrCntA_SP + 1;
          WrEnA_S   = '1;
        end
        // Raise "Full" output if BRAMs are nearly full (i.e., 1024 entries earlier).
        if (WrCntA_SP >= (LOGGING_CNT_MAX-1024)) begin
          Full_SO = 1;
        end
        if (WrCntA_SP == LOGGING_CNT_MAX) begin
          State_SN = FULL;
        end
        if (Clear_SI && WrCntA_SP != 0) begin
          WrCntA_SN = 0;
          State_SN  = CLEARING;
        end
      end

      CLEARING: begin
        WrCntA_SN = WrCntA_SP + 1;
        WrEnA_S   = '1;
        if (WrCntA_SP == LOGGING_CNT_MAX) begin
          WrCntA_SN = 0;
          State_SN  = READY;
        end
      end

      FULL: begin
        Full_SO = 1;
        if (Clear_SI) begin
          WrCntA_SN = 0;
          State_SN  = CLEARING;
        end
      end

    endcase
  end

  // }}}

  // Log Data Formatting {{{
  always_comb begin
    WrA_D = '0;
    if (State_SP != CLEARING) begin
      WrA_D[TIMESTAMP_BITW-1: 0]          = Timestamp_SP;
      WrA_D[64-1            :32]          = AxiAddr_DI;
      WrA_D[AXI_ID_HIGH     :AXI_ID_LOW]  = AxiId_DI;
      WrA_D[AXI_LEN_HIGH    :AXI_LEN_LOW] = AxiLen_DI;
    end
  end
  // }}}

  // Timestamp Counter {{{
  always_comb
  begin
    Timestamp_SN = Timestamp_SP + 1;
    if (Timestamp_SP == {TIMESTAMP_BITW{1'b1}} || State_SP == CLEARING || Clear_SI) begin
      Timestamp_SN = 0;
    end
  end
  // }}}

  // Flip-Flops {{{
  always_ff @ (posedge Clk_CI)
  begin
    State_SP      <= READY;
    Timestamp_SP  <= 0;
    WrCntA_SP     <= 0;
    if (Rst_RBI) begin
      State_SP      <= State_SN;
      Timestamp_SP  <= Timestamp_SN;
      WrCntA_SP     <= WrCntA_SN;
    end
  end
  // }}}

endmodule

`endif // AXI_BRAM_LOGGER_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker

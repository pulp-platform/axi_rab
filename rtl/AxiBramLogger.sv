/**
 * AXI BRAM Logger
 *
 * TODO:
 * - module description
 */

`ifndef AXI_BRAM_LOGGER_SV
`define AXI_BRAM_LOGGER_SV

`include "ceil_div.sv"
`include "log2.sv"

`include "BramPort.sv"
`include "TdpBramArray.sv"

module AxiBramLogger

  // Parameters {{{
  #(

    // Width (in bits) of the logged AXI ID.  Value must be in [1, 24].
    parameter AXI_ID_BITW     =     8,

    // Width (in bits) of the logged AXI address.  Value must be either 32 or 64.
    parameter AXI_ADDR_BITW   =    32,

    // Number of entries in the log.  Value must be >= 1024, should be a multiple of 1024, and is
    // upper-bound by the available memory.
    parameter NUM_LOG_ENTRIES = 16384,

    // The following "parameters" must not be changed from their given value.  They are solely
    // declared here because they define the width of some of the ports.
    parameter AXI_LEN_BITW    =     8

  )
  // }}}

  // Ports {{{
  (
    input  logic                        Clk_CI,
    input  logic                        Rst_RBI,

    // AXI Input
    input  logic                        AxiValid_SI,
    input  logic                        AxiReady_SI,
    input  logic  [AXI_ID_BITW  -1:0]   AxiId_DI,
    input  logic  [AXI_ADDR_BITW-1:0]   AxiAddr_DI,
    input  logic  [AXI_LEN_BITW -1:0]   AxiLen_DI,

    // Control Input
    input  logic                        Clear_SI,

    // Status Output
    output logic                        Full_SO,

    // Interface to Internal BRAM
    BramPort.Slave                      Bram_PS
  );
  // }}}

  // Module-Wide Constants {{{

  // Properties of the data entries in the log
  localparam integer TIMESTAMP_BITW         = 32;
  localparam integer META_BITW              = 32;
  localparam integer LOGGING_DATA_BITW      = ceil_div(TIMESTAMP_BITW+META_BITW+AXI_ADDR_BITW, 32)
                                                    * 32;
  localparam integer LOGGING_DATA_BYTEW     = LOGGING_DATA_BITW / 8;
  localparam integer AXI_LEN_LOW            = TIMESTAMP_BITW;
  localparam integer AXI_LEN_HIGH           = AXI_LEN_LOW + AXI_LEN_BITW - 1;
  localparam integer AXI_ID_LOW             = AXI_LEN_HIGH + 1;
  localparam integer AXI_ID_HIGH            = AXI_ID_LOW + AXI_ID_BITW - 1;
  localparam integer AXI_ADDR_LOW           = TIMESTAMP_BITW + META_BITW;
  localparam integer AXI_ADDR_HIGH          = AXI_ADDR_LOW + AXI_ADDR_BITW - 1;

  // Properties used when addressing the BRAM array
  localparam integer LOGGING_CNT_BITW       = log2(NUM_LOG_ENTRIES);
  localparam integer LOGGING_CNT_MAX        = NUM_LOG_ENTRIES-1;
  localparam integer LOGGING_ADDR_WORD_BITO = log2(LOGGING_DATA_BYTEW);
  localparam integer LOGGING_ADDR_BITW      = LOGGING_CNT_BITW + LOGGING_ADDR_WORD_BITO;

  // }}}

  // Signal Declarations {{{
  logic                           Rst_R;

  enum reg [1:0]  {READY, CLEARING, FULL}
                                  State_SP,     State_SN;

  reg   [LOGGING_CNT_BITW   -1:0] WrCntA_SP,    WrCntA_SN;
  logic [LOGGING_DATA_BITW  -1:0] WrA_D;
  logic [LOGGING_DATA_BYTEW -1:0] WrEnA_S;

  reg   [TIMESTAMP_BITW-1:0]      Timestamp_SP, Timestamp_SN;
  // }}}

  assign Rst_R = ~Rst_RBI;

  // Internal BRAM Interfaces {{{
  BramPort #(
      .DATA_BITW(LOGGING_DATA_BITW),
      .ADDR_BITW(LOGGING_ADDR_BITW)
    ) BramLog_P ();
  assign BramLog_P.Clk_C  = Clk_CI;
  assign BramLog_P.Rst_R  = Rst_R;
  assign BramLog_P.En_S   = WrEnA_S;
  always_comb begin
    BramLog_P.Addr_S = '0;
    BramLog_P.Addr_S[LOGGING_ADDR_BITW-1:0] = (WrCntA_SP << LOGGING_ADDR_WORD_BITO);
  end
  assign BramLog_P.Wr_D   = WrA_D;
  assign BramLog_P.WrEn_S = WrEnA_S;

  BramPort #(
      .DATA_BITW(LOGGING_DATA_BITW),
      .ADDR_BITW(LOGGING_ADDR_BITW)
    ) BramDwc_P ();
  // }}}

  // Instantiation of True Dual-Port BRAM Array {{{
  TdpBramArray #(
      .DATA_BITW(LOGGING_DATA_BITW),
      .NUM_ENTRIES(NUM_LOG_ENTRIES)
    ) bramArr (
      .A_PS(BramLog_P),
      .B_PS(BramDwc_P)
    );
  // }}}

  // Instantiation of Data Width Converter {{{
  BramDwc bramDwc (
      .FromMaster_PS(Bram_PS),
      .ToSlave_PM   (BramDwc_P)
    );
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
      WrA_D[TIMESTAMP_BITW-1  : 0]            = Timestamp_SP;
      WrA_D[AXI_LEN_HIGH      :AXI_LEN_LOW]   = AxiLen_DI;
      WrA_D[AXI_ID_HIGH       :AXI_ID_LOW]    = AxiId_DI;
      WrA_D[AXI_ADDR_HIGH     :AXI_ADDR_LOW]  = AxiAddr_DI;
    end
  end
  // }}}

  // Timestamp Counter {{{
  always_comb
  begin
    Timestamp_SN = Timestamp_SP + 1;
    if (Timestamp_SP == {TIMESTAMP_BITW{1'b1}}) begin
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

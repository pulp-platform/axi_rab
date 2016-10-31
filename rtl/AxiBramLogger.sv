/**
 * AXI BRAM Logger
 *
 * NOTE: `Clear_SI` does NOT clear the content of the RAMs!  It just resets the address and
 * timestamp counters.
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
  localparam integer AXI_ID_LOW         = 0;
  localparam integer AXI_ID_HIGH        = AXI_ID_LOW  + AXI_ID_BITW   - 1;
  localparam integer AXI_LEN_LOW        = AXI_ID_HIGH + 1;
  localparam integer AXI_LEN_HIGH       = AXI_LEN_LOW + AXI_LEN_BITW  - 1;
  // }}}

  // Signal Declarations {{{
  logic                           Rst_R;

  logic [LOGGING_ADDR_BITW-1:0]   LogAddr_S;
  reg   [LOGGING_ADDR_BITW-3:0]   LogCnt_SP, LogCnt_SN;
  logic [LOGGING_DATA_BITW-1:0]   LogData_D;
  logic [LOGGING_DATA_BYTEW-1:0]  LogEn_S;

  reg                             Full_SP, Full_SN;
  reg   [TIMESTAMP_BITW-1:0]      Timestamp_SP, Timestamp_SN;
  // }}}

  assign Rst_R = ~Rst_RBI; // TODO: is the polarity of this reset suitable for the BRAM?

  // Internal BRAM Interfaces {{{
  BramPort #(
      .DATA_WIDTH(LOGGING_DATA_BITW),
      .ADDR_WIDTH(LOGGING_ADDR_BITW)
    ) BramLog_P (
      .Clk_C(Clk_CI),
      .Rst_R(Rst_R),
      .En_S(1'b1),
      .Addr_S(LogAddr_S),
      .Rd_D(),
      .Wr_D(LogData_D),
      .WrEn_S(LogEn_S)
    );
  BramPort #(
      .DATA_WIDTH(LOGGING_DATA_BITW),
      .ADDR_WIDTH(32)
    ) BramDwc_P ();
  // }}}

  // Instantiation of True Dual-Port BRAM Array {{{
  TdpBramArray #(
      .NUM_PAR_BRAMS(NUM_PAR_BRAMS),
      .NUM_SER_BRAMS(NUM_SER_BRAMS)
    ) bramArr (
      .A_PS(BramLog_P.Slave),
      .B_PS(BramDwc_P.Slave)
    );
  // }}}

  // Instantiation of BRAM Data Width Converter {{{
  BramDwc #(
      .BRAM_DATA_BITW(LOGGING_DATA_BITW),
      .EXT_DATA_BITW(32)
    ) bramDwc (
      .Bram_PM(BramDwc_P.Master),
      .Ext_PS(Bram_PS)
    );
  // }}}

  // Control Logic {{{

  // Determine if BRAMs are full.
  always_comb
  begin
    Full_SN = Full_SP;
    if (Clear_SI) begin
      Full_SN = 0;
    end else if (LogCnt_SP == LOGGING_CNT_MAX) begin
      Full_SN = 1;
    end
  end

  // Log if AXI signals are valid, BRAMs are not full, and clear signal is not asserted.
  always_comb begin
    LogEn_S = '{default: '0};
    if (AxiValid_SI && AxiReady_SI && ~Full_SP && ~Clear_SI) begin
      LogEn_S = '{default: '1};
    end
  end

  // }}}

  // Log Data Formatting {{{
  always_comb begin
    LogData_D = '0;
    LogData_D[96-1        :64]          = Timestamp_SP;
    LogData_D[64-1        :32]          = AxiAddr_DI;
    LogData_D[AXI_ID_HIGH :AXI_ID_LOW ] = AxiId_DI;
    LogData_D[AXI_LEN_HIGH:AXI_LEN_LOW] = AxiLen_DI;
  end
  // }}}

  // Logging Address Counter {{{
  assign LogAddr_S = LogCnt_SP << 2;
  always_comb
  begin
    LogCnt_SN = LogCnt_SP;
    if (LogEn_S) begin
      LogCnt_SN = LogCnt_SP + 1;
      if (LogCnt_SP == LOGGING_CNT_MAX || Clear_SI) begin
        LogCnt_SN = 0;
      end
    end
  end
  // }}}

  // Timestamp Counter {{{
  always_comb
  begin
    Timestamp_SN = Timestamp_SP + 1;
    if (Timestamp_SP == {TIMESTAMP_BITW{1'b1}} || Clear_SI) begin
      Timestamp_SN = 0;
    end
  end
  // }}}

  // Flip-Flops {{{
  always_ff @ (posedge Clk_CI)
  begin
    Full_SP       <= 0;
    LogCnt_SP     <= 0;
    Timestamp_SP  <= 0;
    if (Rst_RBI) begin
      Full_SP       <= Full_SN;
      LogCnt_SP     <= LogCnt_SN;
      Timestamp_SP  <= Timestamp_SN;
    end
  end
  // }}}

  assign Full_SO = Full_SP;

endmodule

`endif // AXI_BRAM_LOGGER_SV

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker

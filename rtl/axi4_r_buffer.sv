/* Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * This code is under development and not yet released to the public.
 * Until it is released, the code is under the copyright of ETH Zurich and
 * the University of Bologna, and may contain confidential and/or unpublished
 * work. Any reuse/redistribution is strictly forbidden without written
 * permission from ETH Zurich.
 *
 * Bug fixes and contributions will eventually be released under the
 * SolderPad open hardware license in the context of the PULP platform
 * (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
 * University of Bologna.
 */

module axi4_r_buffer (axi4_aclk,
                      axi4_arstn,
                      s_axi4_rid,
                      s_axi4_rdata,
                      s_axi4_rlast,
                      s_axi4_rresp,
                      s_axi4_rvalid,
                      s_axi4_ruser,
                      s_axi4_rready,
                      m_axi4_rid,
                      m_axi4_rdata,
                      m_axi4_rlast,
                      m_axi4_rresp,
                      m_axi4_rvalid,
                      m_axi4_ruser,
                      m_axi4_rready);

  parameter  AXI_DATA_WIDTH = 32;
  parameter  AXI_ID_WIDTH   = 4;
  parameter  AXI_USER_WIDTH = 4;

  input                       axi4_aclk;
  input                       axi4_arstn;

  output   [AXI_ID_WIDTH-1:0] s_axi4_rid;
  output                [1:0] s_axi4_rresp;
  output [AXI_DATA_WIDTH-1:0] s_axi4_rdata;
  output                      s_axi4_rlast;
  output                      s_axi4_rvalid;
  output [AXI_USER_WIDTH-1:0] s_axi4_ruser;
  input                       s_axi4_rready;

  input    [AXI_ID_WIDTH-1:0] m_axi4_rid;
  input                 [1:0] m_axi4_rresp;
  input  [AXI_DATA_WIDTH-1:0] m_axi4_rdata;
  input                       m_axi4_rlast;
  input                       m_axi4_rvalid;
  input  [AXI_USER_WIDTH-1:0] m_axi4_ruser;
  output                      m_axi4_rready;

  wire [AXI_DATA_WIDTH+AXI_ID_WIDTH+AXI_USER_WIDTH+3-1:0] data_in;
  wire [AXI_DATA_WIDTH+AXI_ID_WIDTH+AXI_USER_WIDTH+3-1:0] data_out;

  localparam ID_START   = 3;
  localparam ID_END     = AXI_ID_WIDTH-1 + ID_START;
  localparam DATA_START = ID_END + 1;
  localparam DATA_END   = AXI_DATA_WIDTH-1 + DATA_START;
  localparam USER_START = DATA_END + 1;
  localparam USER_END   = AXI_USER_WIDTH-1 + USER_START;

  assign data_in                [1:0] = m_axi4_rresp;
  assign data_in                  [2] = m_axi4_rlast;
  assign data_in    [ID_END:ID_START] = m_axi4_rid;
  assign data_in[DATA_END:DATA_START] = m_axi4_rdata;
  assign data_in[USER_END:USER_START] = m_axi4_ruser;

  assign s_axi4_rresp  = data_out                [1:0];
  assign s_axi4_rlast  = data_out                  [2];
  assign s_axi4_rid    = data_out    [ID_END:ID_START];
  assign s_axi4_rdata  = data_out[DATA_END:DATA_START];
  assign s_axi4_ruser  = data_out[USER_END:USER_START];

  axi_buffer_rab
  #(
    .DATA_WIDTH ( AXI_DATA_WIDTH+AXI_ID_WIDTH+AXI_USER_WIDTH+3 )
    )
  u_buffer
  (
    .clk(axi4_aclk), 
    .rstn(axi4_arstn), 
    .valid_out(s_axi4_rvalid), 
    .data_out(data_out), 
    .ready_in(s_axi4_rready), 
    .valid_in(m_axi4_rvalid), 
    .data_in(data_in), 
    .ready_out(m_axi4_rready)
  );

endmodule



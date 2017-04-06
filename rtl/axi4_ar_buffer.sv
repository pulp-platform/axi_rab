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

module axi4_ar_buffer (axi4_aclk,
                       axi4_arstn,
                       s_axi4_arid,
                       s_axi4_araddr,
                       s_axi4_arvalid,
                       s_axi4_arready,
                       s_axi4_arlen,
                       s_axi4_arsize,
                       s_axi4_arburst,
                       s_axi4_arlock,
                       s_axi4_arprot,
                       s_axi4_arcache,
                       s_axi4_aruser,
                       m_axi4_arid,
                       m_axi4_araddr,
                       m_axi4_arvalid,
                       m_axi4_arready,
                       m_axi4_arlen,
                       m_axi4_arsize,
                       m_axi4_arburst,
                       m_axi4_arlock,
                       m_axi4_arprot,
                       m_axi4_arcache,
                       m_axi4_aruser);

  parameter AXI_ID_WIDTH   = 4;
  parameter AXI_USER_WIDTH = 4;

  input                           axi4_aclk;
  input                           axi4_arstn;

  input        [AXI_ID_WIDTH-1:0] s_axi4_arid;
  input                    [31:0] s_axi4_araddr;
  input                   		    s_axi4_arvalid;
  output                  		    s_axi4_arready;
  input             	      [7:0] s_axi4_arlen;
  input             	      [2:0] s_axi4_arsize;
  input                     [1:0] s_axi4_arburst;
  input                           s_axi4_arlock;
  input             	      [2:0] s_axi4_arprot;
  input             	      [3:0] s_axi4_arcache;
  input      [AXI_USER_WIDTH-1:0] s_axi4_aruser;

  output       [AXI_ID_WIDTH-1:0] m_axi4_arid;
  output                   [31:0] m_axi4_araddr;
  output                  		    m_axi4_arvalid;
  input              		          m_axi4_arready;
  output             	      [7:0] m_axi4_arlen;
  output             	      [2:0] m_axi4_arsize;
  output                    [1:0] m_axi4_arburst;
  output                          m_axi4_arlock;
  output             	      [2:0] m_axi4_arprot;
  output             	      [3:0] m_axi4_arcache;
  output     [AXI_USER_WIDTH-1:0] m_axi4_aruser;

  wire [AXI_ID_WIDTH+AXI_USER_WIDTH+52:0] data_in;
  wire [AXI_ID_WIDTH+AXI_USER_WIDTH+52:0] data_out;

  assign data_in                                           [3:0] = s_axi4_arcache;
  assign data_in                                           [6:4] = s_axi4_arprot;
  assign data_in                                             [7] = s_axi4_arlock;
  assign data_in                                           [9:8] = s_axi4_arburst;
  assign data_in                                         [12:10] = s_axi4_arsize;
  assign data_in                                         [20:13] = s_axi4_arlen;
  assign data_in                                         [52:21] = s_axi4_araddr;
  assign data_in                            [52+AXI_ID_WIDTH:53] = s_axi4_arid;
  assign data_in[52+AXI_ID_WIDTH+AXI_USER_WIDTH:53+AXI_ID_WIDTH] = s_axi4_aruser;

  assign m_axi4_arcache = data_out[3:0];
  assign m_axi4_arprot  = data_out[6:4];
  assign m_axi4_arlock  = data_out[7];
  assign m_axi4_arburst = data_out[9:8];
  assign m_axi4_arsize  = data_out[12:10];
  assign m_axi4_arlen   = data_out[20:13];
  assign m_axi4_araddr  = data_out[52:21];
  assign m_axi4_arid    = data_out[52+AXI_ID_WIDTH:53];
  assign m_axi4_aruser  = data_out[52+AXI_ID_WIDTH+AXI_USER_WIDTH:53+AXI_ID_WIDTH];

  axi_buffer_rab
    #(
      .DATA_WIDTH ( AXI_ID_WIDTH+AXI_USER_WIDTH+53 )
      )
    u_buffer
    (
      .clk(axi4_aclk), 
      .rstn(axi4_arstn), 
      .valid_out(m_axi4_arvalid), 
      .data_out(data_out), 
      .ready_in(m_axi4_arready), 
      .valid_in(s_axi4_arvalid), 
      .data_in(data_in), 
      .ready_out(s_axi4_arready)
    );

endmodule



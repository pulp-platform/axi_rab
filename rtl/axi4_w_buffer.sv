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

module axi4_w_buffer (axi4_aclk,
                         axi4_arstn,
                         s_axi4_wdata,
                         s_axi4_wvalid,
                         s_axi4_wready,
                         s_axi4_wstrb,
                         s_axi4_wlast,
                         s_axi4_wuser,
                         m_axi4_wdata,
                         m_axi4_wvalid,
                         m_axi4_wready,
                         m_axi4_wstrb,
                         m_axi4_wlast,
                         m_axi4_wuser);

  parameter AXI_DATA_WIDTH = 32;
  parameter AXI_USER_WIDTH = 2;

  input                         axi4_aclk;
  input                         axi4_arstn;
  input    [AXI_DATA_WIDTH-1:0] s_axi4_wdata;
  input                         s_axi4_wvalid;
  output                        s_axi4_wready;
  input  [AXI_DATA_WIDTH/8-1:0] s_axi4_wstrb;
  input                         s_axi4_wlast;
  input    [AXI_USER_WIDTH-1:0] s_axi4_wuser;
         
  output   [AXI_DATA_WIDTH-1:0] m_axi4_wdata;
  output                        m_axi4_wvalid;
  input                         m_axi4_wready;
  output [AXI_DATA_WIDTH/8-1:0] m_axi4_wstrb;
  output                        m_axi4_wlast;
  output   [AXI_USER_WIDTH-1:0] m_axi4_wuser;

  wire [AXI_DATA_WIDTH+AXI_USER_WIDTH+AXI_DATA_WIDTH/8:0] data_in;
  wire [AXI_DATA_WIDTH+AXI_USER_WIDTH+AXI_DATA_WIDTH/8:0] data_out;

  assign data_in                                                                               [0] = s_axi4_wlast;
  assign data_in                                                                [AXI_DATA_WIDTH:1] = s_axi4_wdata;
  assign data_in                                [AXI_DATA_WIDTH+AXI_DATA_WIDTH/8:AXI_DATA_WIDTH+1] = s_axi4_wstrb;
  assign data_in[AXI_DATA_WIDTH+AXI_USER_WIDTH+AXI_DATA_WIDTH/8:AXI_DATA_WIDTH+AXI_DATA_WIDTH/8+1] = s_axi4_wuser;

  assign m_axi4_wlast  = data_out[0];
  assign m_axi4_wdata  = data_out[AXI_DATA_WIDTH:1];
  assign m_axi4_wstrb  = data_out[AXI_DATA_WIDTH+AXI_DATA_WIDTH/8:AXI_DATA_WIDTH+1];
  assign m_axi4_wuser  = data_out[AXI_DATA_WIDTH+AXI_USER_WIDTH+AXI_DATA_WIDTH/8:AXI_DATA_WIDTH+AXI_DATA_WIDTH/8+1];

  axi_buffer_rab
    #(
      .DATA_WIDTH ( AXI_DATA_WIDTH+AXI_USER_WIDTH+AXI_DATA_WIDTH/8+1 )
      )
    u_buffer
    (
      .clk(axi4_aclk), 
      .rstn(axi4_arstn), 
      .valid_out(m_axi4_wvalid), 
      .data_out(data_out), 
      .ready_in(m_axi4_wready), 
      .valid_in(s_axi4_wvalid), 
      .data_in(data_in), 
      .ready_out(s_axi4_wready)
    );

endmodule



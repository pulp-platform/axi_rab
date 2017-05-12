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

module axi4_r_sender (axi4_aclk,
                      axi4_arstn,
                      trans_id,
                      trans_drop,
                      trans_prefetch,
                      trans_hit,
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

  parameter AXI_DATA_WIDTH = 32;
  parameter AXI_ID_WIDTH   = 4;
  parameter AXI_USER_WIDTH = 4;
  parameter ENABLE_L2TLB   = 0;

  input                       axi4_aclk;
  input                       axi4_arstn;

  input    [AXI_ID_WIDTH-1:0] trans_id;
  input                       trans_drop;
  input                       trans_prefetch;
  input                       trans_hit;

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

  wire                        trans_infifo;
  wire                        trans_done;
  wire                        fifo_not_full;
  wire     [AXI_ID_WIDTH-1:0] id_to_drop;
  wire                        prefetch;
  wire                        hit;

  reg                         dropping;

  axi_buffer_rab
    #(
      .DATA_WIDTH ( 2+AXI_ID_WIDTH )
      )
    u_transfifo
      (
        .clk       ( axi4_aclk                             ),
        .rstn      ( axi4_arstn                            ),
        .data_out  ( {prefetch, hit, id_to_drop}           ),
        .valid_out ( trans_infifo                          ),
        .ready_in  ( trans_done                            ),
        .valid_in  ( trans_drop                            ),
        .data_in   ( {trans_prefetch, trans_hit, trans_id} ),
        .ready_out ( fifo_not_full                         )
      );

  assign trans_done = dropping && s_axi4_rready;

  always @ (posedge axi4_aclk or negedge axi4_arstn)
    begin 
      if (axi4_arstn == 1'b0) begin
        dropping <= 1'b0;
      end else begin
        if (trans_infifo && ~dropping) 
          dropping <= 1'b1;
        else if (trans_done)
          dropping <= 1'b0;
      end
  end

  assign s_axi4_rdata  = m_axi4_rdata;
  assign s_axi4_rlast  = dropping ? 1'b1 : m_axi4_rlast;

  assign s_axi4_ruser  = dropping ? {AXI_USER_WIDTH{1'b0}} : m_axi4_ruser;
  assign s_axi4_rid    = dropping ? id_to_drop : m_axi4_rid;

  assign s_axi4_rresp = (dropping & ~hit)     ? 2'b10 :
                        (dropping & prefetch) ? 2'b00 :
                        m_axi4_rresp;

  assign s_axi4_rvalid =  dropping | m_axi4_rvalid;
  assign m_axi4_rready = ~dropping & s_axi4_rready;

endmodule



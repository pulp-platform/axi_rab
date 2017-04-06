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

`include "ulpsoc_defines.sv"
module axi4_b_sender (axi4_aclk,
                        axi4_arstn,
                        trans_id,
                        trans_drop,
                        trans_prefetch,
                        wlast_received,
                        response_sent,                         
                        s_axi4_wvalid,
                        s_axi4_wlast,
                        s_axi4_wready,
                        s_axi4_bid,
                        s_axi4_bresp,
                        s_axi4_bvalid,
                        s_axi4_buser,
                        s_axi4_bready,
                        m_axi4_bid,
                        m_axi4_bresp,
                        m_axi4_bvalid,
                        m_axi4_buser,
                        m_axi4_bready);

  parameter AXI_ID_WIDTH   = 10;
  parameter AXI_USER_WIDTH = 4;
  parameter ENABLE_L2TLB   = 0;

  input                       axi4_aclk;
  input                       axi4_arstn;
  
  input    [AXI_ID_WIDTH-1:0] trans_id;
  input                       trans_drop;
  input                       trans_prefetch;
  
  input                       s_axi4_wvalid;
  input                       s_axi4_wlast;
  input                       s_axi4_wready;   
  input                       wlast_received;   
  output                      response_sent;   
 
  output   [AXI_ID_WIDTH-1:0] s_axi4_bid;
  output                [1:0] s_axi4_bresp;
  output                      s_axi4_bvalid;
  output [AXI_USER_WIDTH-1:0] s_axi4_buser;
  input                       s_axi4_bready;
  
  input    [AXI_ID_WIDTH-1:0] m_axi4_bid;
  input                 [1:0] m_axi4_bresp;
  input                       m_axi4_bvalid;
  input  [AXI_USER_WIDTH-1:0] m_axi4_buser;
  output                      m_axi4_bready;

  wire                        trans_infifo;
  wire                        trans_done;
  wire                        fifo_not_full;
  wire     [AXI_ID_WIDTH-1:0] id_to_drop;
  wire                        prefetch;

  reg                         dropping;
  reg                         wlast_received_reg;
  
  axi_buffer_rab
    #(
      .DATA_WIDTH ( 1+AXI_ID_WIDTH )
      )
    u_transfifo
      (
        .clk       ( axi4_aclk                  ),
        .rstn      ( axi4_arstn                 ),
        .data_out  ( {prefetch, id_to_drop}     ),
        .valid_out ( trans_infifo               ),
        .ready_in  ( trans_done                 ),
        .valid_in  ( trans_drop                 ),
        .data_in   ( {trans_prefetch, trans_id} ),
        .ready_out ( fifo_not_full              )
      );

  assign trans_done = dropping && s_axi4_bready;

  always @ (posedge axi4_aclk or negedge axi4_arstn)
    begin 
      if (axi4_arstn == 1'b0) begin
        dropping <= 1'b0;
      end else begin
        if (trans_infifo && ~dropping && wlast_received_reg) 
          dropping <= 1'b1;
        else if (trans_done)
          dropping <= 1'b0;
      end
    end

generate 
if (ENABLE_L2TLB == 1) begin
  assign response_sent = trans_done;
  always @(wlast_received) begin
    wlast_received_reg <= wlast_received;
  end
end else begin   
  always @ (posedge axi4_aclk or negedge axi4_arstn)
    begin 
      if (axi4_arstn == 1'b0) begin
        wlast_received_reg <= 1'b0;
      end else begin
        if (trans_infifo && s_axi4_wlast && s_axi4_wready && s_axi4_wvalid)
          wlast_received_reg <= 1'b1;
        else if (trans_done)
          wlast_received_reg <= 1'b0;
      end
    end // always @ (posedge axi4_aclk or negedge axi4_arstn)
  
  assign response_sent = 1'b0;

end // else: !if(ENABLE_L2TLB == 1)
endgenerate

  assign s_axi4_buser  = dropping ? {AXI_USER_WIDTH{1'b0}} : m_axi4_buser;
  assign s_axi4_bid    = dropping ? id_to_drop : m_axi4_bid;

  assign s_axi4_bresp  = (dropping &  prefetch) ? 2'b00 :
                         (dropping & !prefetch) ? 2'b10 :
                         m_axi4_bresp;
  
  assign s_axi4_bvalid =  dropping | m_axi4_bvalid;
  assign m_axi4_bready = ~dropping & s_axi4_bready;

endmodule

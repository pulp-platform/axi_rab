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

import CfMath::log2;

module axi4_w_sender (axi4_aclk,
                      axi4_arstn,
                      l1_trans_accept,
                      l2_trans_accept,
                      l2_trans_drop,
                      l2_trans_drop_x,
                      l1_miss,
                      stall_aw,
                      wlast_received,
                      response_sent,
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
  parameter ENABLE_L2TLB   = 0;
  parameter L2BUFFER_DEPTH = 20;

  input                         axi4_aclk;
  input                         axi4_arstn;

  input                         l1_trans_accept;
  input                         l2_trans_accept;
  input                         l2_trans_drop;
  input                         l2_trans_drop_x;
  input                         l1_miss;
  output                        stall_aw;
  input                         response_sent;
  output                        wlast_received;

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


  wire                          trans_infifo;
  wire                          trans_done;
  wire                          fifo_not_full;
  wire [4:0]                    fifo_datain;
  wire [4:0]                    fifo_dataout;
  wire                          fifo_datain_valid;

  axi_buffer_rab
    #(
      .DATA_WIDTH       ( 5  ),
      .BUFFER_DEPTH     ( 10 ),
      .LOG_BUFFER_DEPTH ( 4  )
      )
    u_transfifo
    (
      .clk       ( axi4_aclk         ),
      .rstn      ( axi4_arstn        ),
      .data_out  ( fifo_dataout      ),
      .valid_out ( trans_infifo      ),
      .ready_in  ( trans_done        ),
      .valid_in  ( fifo_datain_valid ),
      .data_in   ( fifo_datain       ),
      .ready_out ( fifo_not_full     )
    );

  assign fifo_datain_valid = l1_miss | l1_trans_accept | l2_trans_accept | l2_trans_drop | l2_trans_drop_x;
  assign fifo_datain       = {l1_trans_accept, l1_miss, l2_trans_accept, l2_trans_drop, l2_trans_drop_x};

generate
if (ENABLE_L2TLB == 1) begin
  reg                         trans_is_l1_accept,trans_is_drop;
  wire   [AXI_DATA_WIDTH-1:0] l2_axi4_wdata;
  wire [AXI_DATA_WIDTH/8-1:0] l2_axi4_wstrb;
  wire                        l2_axi4_wlast;
  wire   [AXI_USER_WIDTH-1:0] l2_axi4_wuser;
  wire                        single_trans,double_trans;
  wire                        data_inbuffer, buffer_not_full;
  reg                         stop_storing, keep_storing;
  reg                         stop_storing_next;
  reg                         storing;
  wire                        buffer_datain_valid;
  wire                        get_next_bufferdata;
  reg                         trans_is_l1_miss;
  reg                         trans_is_l2_accept;
  reg                         second_trans;
  reg                         waiting_wlast;
  reg                         l2_wlast_received_reg;

  wire [AXI_DATA_WIDTH+AXI_DATA_WIDTH/8+AXI_USER_WIDTH+1-1:0] buffer_dataout;
  wire [AXI_DATA_WIDTH+AXI_DATA_WIDTH/8+AXI_USER_WIDTH+1-1:0] buffer_datain;

  typedef enum logic[1:0] {IDLE, STORE, DONE} store_state_t;
  store_state_t store_state, store_next_state;

  // Stall aw channel till wlast is encountered or if the fifo is full.(The fifo cannot be full if w and aw are aligned)
  assign stall_aw = ~fifo_not_full || waiting_wlast;
  always @(posedge axi4_aclk) begin
     if (axi4_arstn == 0) begin
        waiting_wlast <= 1'b0;
     end else if (s_axi4_wvalid && s_axi4_wready && ~s_axi4_wlast) begin // not the last transfer
        waiting_wlast <= 1'b1;
     end else if (s_axi4_wvalid && s_axi4_wready &&  s_axi4_wlast) begin
        waiting_wlast <= 1'b0;
     end
  end

  // wlast_received is used in b_sender to send write response signals.
  // Write response signals have to be sent only after wlast is received as per AXI protocol.
  // l2_wlast_received_reg indicates if wlast is received for L2 trans.
   always @(posedge axi4_aclk) begin
     if (axi4_arstn == 0) begin
        l2_wlast_received_reg <= 1'b0;
     end else if(stop_storing) begin
        l2_wlast_received_reg <= 1'b1;
     end else if (response_sent) begin
        l2_wlast_received_reg <= 1'b0;
     end
  end
  assign wlast_received = l2_wlast_received_reg;

  // In case of simultaneous L1 and L2 hit/miss, first send L2 transaction and then L1.
  // second_trans indicates that the second transaction (i.e L1) is taking place.
  always @(posedge axi4_aclk) begin
     if (axi4_arstn == 0) begin
        second_trans <= 1'b0;
     end else if(double_trans) begin
        if (trans_is_l2_accept && m_axi4_wvalid && m_axi4_wready && m_axi4_wlast) begin
           second_trans <= 1'b1;
        end else if (trans_is_drop && l2_axi4_wlast) begin
           second_trans <= 1'b1;
        end else if (trans_done) begin
           second_trans <= 1'b0;
        end
     end
  end // always @ (posedge axi4_aclk)

  //second transfer is always L1.
  always @(trans_infifo,fifo_dataout,second_trans) begin
     trans_is_drop      = 1'b0;
     trans_is_l2_accept = 1'b0;
     trans_is_l1_miss   = 1'b0;
     trans_is_l1_accept = 1'b0;
     if(trans_infifo & fifo_dataout[1] & ~second_trans) begin
        trans_is_drop      = 1'b1;
     end else if (trans_infifo & fifo_dataout[2] & ~second_trans) begin
        trans_is_l2_accept = 1'b1;
     end else if (trans_infifo & fifo_dataout[3]) begin
        trans_is_l1_miss   = 1'b1;
     end else if (trans_infifo & fifo_dataout[4]) begin
        trans_is_l1_accept = 1'b1;
     end
  end // always @ (trans_infifo,fifo_dataout,second_trans)

  // In case of double_trans, do not get assert trans_done after first transaction.
  assign trans_done = trans_is_l1_accept                ? (s_axi4_wvalid && s_axi4_wready && s_axi4_wlast) :
                      trans_is_l1_miss                  ? (s_axi4_wvalid && s_axi4_wready && s_axi4_wlast) | ~buffer_not_full :
                      trans_is_l2_accept & single_trans ?  m_axi4_wvalid && m_axi4_wready && m_axi4_wlast  :
                      trans_is_drop      & single_trans ?  l2_axi4_wlast                                   : // the l2buffer is only flushed if the transaction is dropped in all masters
                      1'b0;

  // Will have to send two trans if L1 and L2 results come simultaneously
  assign double_trans = trans_infifo & ( fifo_dataout[1]|fifo_dataout[2]) & (fifo_dataout[3]|fifo_dataout[4]);
  assign single_trans = trans_infifo & ((fifo_dataout[1]|fifo_dataout[2]) ^ (fifo_dataout[3]|fifo_dataout[4]));

  assign m_axi4_wlast  = trans_is_drop ? 1'b0                     : trans_is_l2_accept ? l2_axi4_wlast : trans_is_l1_accept ? s_axi4_wlast : 1'b0                     ;
  assign m_axi4_wdata  = trans_is_drop ? {AXI_DATA_WIDTH{1'b0}}   : trans_is_l2_accept ? l2_axi4_wdata : trans_is_l1_accept ? s_axi4_wdata : {AXI_DATA_WIDTH{1'b0}}   ;
  assign m_axi4_wstrb  = trans_is_drop ? {AXI_DATA_WIDTH/8{1'b0}} : trans_is_l2_accept ? l2_axi4_wstrb : trans_is_l1_accept ? s_axi4_wstrb : {AXI_DATA_WIDTH/8{1'b0}} ;
  assign m_axi4_wuser  = trans_is_drop ? {AXI_USER_WIDTH{1'b0}}   : trans_is_l2_accept ? l2_axi4_wuser : trans_is_l1_accept ? s_axi4_wuser : {AXI_USER_WIDTH{1'b0}}   ;

  // Outputs
  assign m_axi4_wvalid = (trans_is_l1_accept & s_axi4_wvalid) |                                (trans_is_l2_accept & data_inbuffer);
  assign s_axi4_wready = (trans_is_l1_accept & m_axi4_wready) | (trans_is_l1_miss & storing) | (trans_is_l2_accept & storing      ) | (trans_is_drop & storing);

  // Store signals in buffer in case of L1 miss.
  axi_buffer_rab_bram
   #(
     .DATA_WIDTH       ( AXI_DATA_WIDTH+AXI_DATA_WIDTH/8+AXI_USER_WIDTH+1 ),
     .BUFFER_DEPTH     ( L2BUFFER_DEPTH                                   ),
     .LOG_BUFFER_DEPTH ( log2(L2BUFFER_DEPTH)                             )
     )
   u_l2buffer
   (
     .clk          ( axi4_aclk                       ),
     .rstn         ( axi4_arstn                      ),
     .data_out     ( buffer_dataout                  ),
     .valid_out    ( data_inbuffer                   ),
     .ready_in     ( get_next_bufferdata             ),
     .valid_in     ( buffer_datain_valid             ),
     .data_in      ( buffer_datain                   ),
     .ready_out    ( buffer_not_full                 ),
     .flush_entries( trans_is_drop & fifo_dataout[0] )
   );

  assign                 {l2_axi4_wlast, l2_axi4_wuser, l2_axi4_wstrb, l2_axi4_wdata} = buffer_dataout;
  assign buffer_datain = { s_axi4_wlast,  s_axi4_wuser,  s_axi4_wstrb,  s_axi4_wdata};

  // Get the data out of buffer upon L2 hit or L2 miss.
  assign get_next_bufferdata = data_inbuffer && ( (trans_is_l2_accept && m_axi4_wready) || trans_is_drop);

  // Store all signals when valid
  assign buffer_datain_valid = storing ? s_axi4_wvalid : 0;

  // Store FSM
  always @(posedge axi4_aclk) begin
     if (axi4_arstn == 0) begin
        store_state <= IDLE;
     end else begin
        store_state <= store_next_state;
     end
  end

  always @(store_state, trans_is_l1_miss, s_axi4_wlast, s_axi4_wvalid, buffer_not_full, trans_is_l2_accept, trans_is_drop) begin
     store_next_state  = store_state;
     stop_storing_next = 1'b0;
     storing           = 1'b0;
     case(store_state)
       IDLE :
         if (trans_is_l1_miss)
           store_next_state = STORE;

       STORE : begin
          if (buffer_not_full == 1'b1) begin
            storing = 1'b1;
            if (s_axi4_wlast && s_axi4_wvalid) begin
               store_next_state = DONE;
               stop_storing_next = 1'b1;
            end
          end
       end

       DONE : begin
          stop_storing_next = 1'b1;
          if (trans_is_l2_accept || trans_is_drop)
            store_next_state = IDLE;
       end

       default : begin
          store_next_state = IDLE;
        end

     endcase // case (store_state)
  end

  always @(posedge axi4_aclk) begin
     if (axi4_arstn == 0) begin
        stop_storing <= 1'b0;
     end else begin
        stop_storing <= stop_storing_next;
     end
  end

end else begin // if (ENABLE_L2TLB == 1)

   wire trans_is_l1_accept,trans_is_drop;

   assign wlast_received     = 1'b0; // This signal is sent to rwch_sender
   assign stall_aw           = 1'b0; // This signal is sent to awch_sender

   assign trans_is_l1_accept = trans_infifo & fifo_dataout[4];
   assign trans_is_drop      = trans_infifo & fifo_dataout[3];

   assign trans_done         =  s_axi4_wvalid && s_axi4_wready && s_axi4_wlast;

   assign m_axi4_wlast  = trans_is_drop ? 1'b0                     : s_axi4_wlast ;
   assign m_axi4_wdata  = trans_is_drop ? {AXI_DATA_WIDTH{1'b0}}   : s_axi4_wdata ;
   assign m_axi4_wstrb  = trans_is_drop ? {AXI_DATA_WIDTH/8{1'b0}} : s_axi4_wstrb ;
   assign m_axi4_wuser  = trans_is_drop ? {AXI_USER_WIDTH{1'b0}}   : s_axi4_wuser ;

   // Outputs
   assign m_axi4_wvalid = (s_axi4_wvalid & trans_is_l1_accept);
   assign s_axi4_wready = (m_axi4_wready & trans_is_l1_accept) | trans_is_drop;

end // !`ifdef ENABLE_L2TLB
endgenerate

// L2 hit/miss cannot happen simultaneously with L1 miss because L1 miss =0 when L2 is busy.
endmodule

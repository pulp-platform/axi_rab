`include "ulpsoc_defines.sv"
module axi4_ar_sender (axi4_aclk,
                       axi4_arstn,
                       l1_trans_accept,
                       l1_trans_drop,
                       l1_trans_sent,
                       l2_trans_accept,
                       l2_busy,
                       l2_rtrans_sent,
                       s_axi4_arid,
                       l1_axi4_araddr,
                       l2_axi4_araddr,
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
  
  parameter AXI_ADDR_WIDTH = 40;
  parameter AXI_ID_WIDTH   = 4;
  parameter AXI_USER_WIDTH = 4;
  parameter ENABLE_L2TLB   = 0;
  
  input                       axi4_aclk;
  input                       axi4_arstn;
  input                       l1_trans_accept;
  input                       l1_trans_drop;
  output                      l1_trans_sent;
  input                       l2_trans_accept;
  input                       l2_busy;
  output                      l2_rtrans_sent;

  input    [AXI_ID_WIDTH-1:0] s_axi4_arid;
  input  [AXI_ADDR_WIDTH-1:0] l1_axi4_araddr;
  input  [AXI_ADDR_WIDTH-1:0] l2_axi4_araddr; 
  input                       s_axi4_arvalid;
  output                      s_axi4_arready;
  input                 [7:0] s_axi4_arlen;
  input                 [2:0] s_axi4_arsize;
  input                 [1:0] s_axi4_arburst;
  input                       s_axi4_arlock;
  input                 [2:0] s_axi4_arprot;
  input                 [3:0] s_axi4_arcache;
  input  [AXI_USER_WIDTH-1:0] s_axi4_aruser;

  output   [AXI_ID_WIDTH-1:0] m_axi4_arid;
  output [AXI_ADDR_WIDTH-1:0] m_axi4_araddr;
  output                      m_axi4_arvalid;
  input                       m_axi4_arready;
  output                [7:0] m_axi4_arlen;
  output                [2:0] m_axi4_arsize;
  output                [1:0] m_axi4_arburst;
  output                      m_axi4_arlock;
  output                [2:0] m_axi4_arprot;
  output                [3:0] m_axi4_arcache;
  output [AXI_USER_WIDTH-1:0] m_axi4_aruser;
  
  wire                        ar_sent;
  reg                         l1_waiting_arready;
  wire                        sending_l2;
  
  assign ar_sent = s_axi4_arvalid & s_axi4_arready;

  always @(posedge axi4_aclk or negedge axi4_arstn)
    begin: buffers_sequential
      if (axi4_arstn == 1'b0)
        l1_waiting_arready = 1'b0;
      else if (ar_sent)
        l1_waiting_arready = 1'b0;
      else if (l1_trans_accept)
        l1_waiting_arready = 1'b1;
    end
  
  // if 1: valid ar transaction at input & slave asserts arready & either transaction is accepted or we were waiting for arready. Not asserting arready for L2 transaction.
  //    2: valid ar transaction at input & transaction is dropped
  assign s_axi4_arready = (m_axi4_arvalid & m_axi4_arready & ~sending_l2) | (s_axi4_arvalid & l1_trans_drop);
  assign m_axi4_arvalid = (s_axi4_arvalid & (l1_trans_accept | l1_waiting_arready)) || sending_l2;
  assign l1_trans_sent = ar_sent;

generate
if (ENABLE_L2TLB == 1) begin
   reg [AXI_USER_WIDTH-1:0] l2_axi4_aruser;   
   reg                [3:0] l2_axi4_arcache ;
   reg                [3:0] l2_axi4_arregion;
   reg                [3:0] l2_axi4_arqos   ;
   reg                [2:0] l2_axi4_arprot  ;
   reg                      l2_axi4_arlock  ;
   reg                [1:0] l2_axi4_arburst ;
   reg                [2:0] l2_axi4_arsize  ;
   reg                [7:0] l2_axi4_arlen   ;
   reg   [AXI_ID_WIDTH-1:0] l2_axi4_arid    ;
   reg                      l2_waiting_arready;

   assign m_axi4_aruser  = sending_l2 ? l2_axi4_aruser   : s_axi4_aruser;
   assign m_axi4_arcache = sending_l2 ? l2_axi4_arcache  : s_axi4_arcache;
   assign m_axi4_arprot  = sending_l2 ? l2_axi4_arprot   : s_axi4_arprot;
   assign m_axi4_arlock  = sending_l2 ? l2_axi4_arlock   : s_axi4_arlock;
   assign m_axi4_arburst = sending_l2 ? l2_axi4_arburst  : s_axi4_arburst;
   assign m_axi4_arsize  = sending_l2 ? l2_axi4_arsize   : s_axi4_arsize;
   assign m_axi4_arlen   = sending_l2 ? l2_axi4_arlen    : s_axi4_arlen;
   assign m_axi4_araddr  = sending_l2 ? l2_axi4_araddr   : l1_axi4_araddr;
   assign m_axi4_arid    = sending_l2 ? l2_axi4_arid     : s_axi4_arid;
   
   // Buffer AXI signals in case of L1 miss
   always @(posedge axi4_aclk or negedge axi4_arstn)
     begin
        if (axi4_arstn == 1'b0) begin
           l2_axi4_aruser  <= 0;
           l2_axi4_arcache <= 0;
           l2_axi4_arprot  <= 0;
           l2_axi4_arlock  <= 0;
           l2_axi4_arburst <= 0;
           l2_axi4_arsize  <= 0;
           l2_axi4_arlen   <= 0;        
           l2_axi4_arid    <= 0;
        end else if (l1_trans_drop) begin          
           l2_axi4_aruser  <= s_axi4_aruser;
           l2_axi4_arcache <= s_axi4_arcache;
           l2_axi4_arprot  <= s_axi4_arprot;
           l2_axi4_arlock  <= s_axi4_arlock;
           l2_axi4_arburst <= s_axi4_arburst;
           l2_axi4_arsize  <= s_axi4_arsize;
           l2_axi4_arlen   <= s_axi4_arlen;           
           l2_axi4_arid    <= s_axi4_arid;
        end // if (l1_trans_drop == 1'b1)
     end // always_ff @ (posedge axi4_aclk or negedge axi4_arstn)

   always @(posedge axi4_aclk or negedge axi4_arstn)
     begin: l2_buffers_sequential
        if (axi4_arstn == 1'b0)
          l2_waiting_arready = 1'b0;
        else if (sending_l2 & m_axi4_arvalid & m_axi4_arready) // sending L2 trans
          l2_waiting_arready = 1'b0;
        else if (l2_trans_accept) // L2 hit
          l2_waiting_arready = 1'b1;
     end  
   
   assign sending_l2     = l2_trans_accept | l2_waiting_arready;
   assign l2_rtrans_sent = m_axi4_arvalid & m_axi4_arready & sending_l2;
   
end else begin// !`ifdef ENABLE_L2TLB
   assign m_axi4_aruser  =  s_axi4_aruser;
   assign m_axi4_arcache =  s_axi4_arcache;
   assign m_axi4_arprot  =  s_axi4_arprot;
   assign m_axi4_arlock  =  s_axi4_arlock;
   assign m_axi4_arburst =  s_axi4_arburst;
   assign m_axi4_arsize  =  s_axi4_arsize;
   assign m_axi4_arlen   =  s_axi4_arlen;
   assign m_axi4_araddr  =  l1_axi4_araddr;
   assign m_axi4_arid    =  s_axi4_arid;

   assign sending_l2     = 1'b0;
   assign l2_rtrans_sent = 1'b0;   
end // else: !if(ENABLE_L2TLB == 1)
endgenerate
   
endmodule

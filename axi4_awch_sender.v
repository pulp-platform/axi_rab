`include "ulpsoc_defines.sv"
module axi4_awch_sender (axi4_aclk,
                         axi4_arstn,
                         l1_trans_accept,
                         l1_trans_drop,
                         l1_trans_sent,
                         l2_trans_accept,
                         l2_wtrans_sent,
                         stall_aw,
                         l2_busy,
                         s_axi4_awid,
                         l1_axi4_awaddr,
                         l2_axi4_awaddr,
                         s_axi4_awvalid,
                         s_axi4_awready,
                         s_axi4_awlen,
                         s_axi4_awsize,
                         s_axi4_awburst,
                         s_axi4_awlock,
                         s_axi4_awprot,
                         s_axi4_awcache,
                         s_axi4_awregion,
                         s_axi4_awqos,
                         s_axi4_awuser,
                         m_axi4_awid,
                         m_axi4_awaddr,
                         m_axi4_awvalid,
                         m_axi4_awready,
                         m_axi4_awlen,
                         m_axi4_awsize,
                         m_axi4_awburst,
                         m_axi4_awlock,
                         m_axi4_awprot,
                         m_axi4_awcache,
                         m_axi4_awregion,
                         m_axi4_awqos,
                         m_axi4_awuser);

   parameter  C_AXI_ID_WIDTH = 4;
   parameter  C_AXI_USER_WIDTH = 4;
   parameter  ENABLE_L2TLB = 0;
   
   input                            axi4_aclk;
   input                            axi4_arstn;
   input                            l1_trans_accept;
   input                            l1_trans_drop;
   output                           l1_trans_sent;
   input                            l2_trans_accept;  
   input                            l2_busy;
   output                           l2_wtrans_sent;  
   input                            stall_aw;
  
   input [C_AXI_ID_WIDTH-1:0]       s_axi4_awid;
   input [31:0]                     l1_axi4_awaddr;
   input [31:0]                     l2_axi4_awaddr;
   input                            s_axi4_awvalid;
   output                           s_axi4_awready;
   input [7:0]                      s_axi4_awlen;
   input [2:0]                      s_axi4_awsize;
   input [1:0]                      s_axi4_awburst;
   input                            s_axi4_awlock;
   input [2:0]                      s_axi4_awprot;
   input [3:0]                      s_axi4_awcache;
   input [3:0]                      s_axi4_awregion;
   input [3:0]                      s_axi4_awqos;
   input [C_AXI_USER_WIDTH-1:0]     s_axi4_awuser;
   
   output [C_AXI_ID_WIDTH-1:0]      m_axi4_awid;
   output [31:0]                    m_axi4_awaddr;
   output                           m_axi4_awvalid;
   input                            m_axi4_awready;
   output [7:0]                     m_axi4_awlen;
   output [2:0]                     m_axi4_awsize;
   output [1:0]                     m_axi4_awburst;
   output                           m_axi4_awlock;
   output [2:0]                     m_axi4_awprot;
   output [3:0]                     m_axi4_awcache;
   output [3:0]                     m_axi4_awregion;
   output [3:0]                     m_axi4_awqos;
   output [C_AXI_USER_WIDTH-1:0]    m_axi4_awuser;

   
   reg                              l1_waiting_awready;
   reg                              waiting_stall; // waiting for aw_stall=0
   wire                             sending_l2;
   wire                             get_new;

   always @(posedge axi4_aclk or negedge axi4_arstn)
     begin: buffers_sequential
        if (axi4_arstn == 1'b0)
          l1_waiting_awready = 1'b0;
        else if (~sending_l2 & m_axi4_awvalid & m_axi4_awready)
          l1_waiting_awready = 1'b0;
        else if (l1_trans_accept)
          l1_waiting_awready = 1'b1;
     end

   assign m_axi4_awvalid = (s_axi4_awvalid & (l1_trans_accept | l1_waiting_awready)) || sending_l2 ;
//   assign s_axi4_awready = waiting_stall && ~stall_aw ;
   assign l1_trans_sent  = s_axi4_awvalid & s_axi4_awready;
   
//   always @(posedge axi4_aclk) begin
//      if (axi4_arstn == 1'b0) begin
//         waiting_stall <= 1'b0;
//      end else
//        // if 1: valid aw transaction at input & slave asserts awready & either transaction is accepted or we were waiting for awready. Not asserting awready for L2 transaction.
//        //    2: valid aw transaction at input & transaction is dropped
//        if ((m_axi4_awvalid & m_axi4_awready & ~sending_l2) | (s_axi4_awvalid & l1_trans_drop)) begin
//           waiting_stall = 1'b1;
//        end else if (s_axi4_awready) begin
//           waiting_stall = 1'b0; 
//        end
//   end // always @ (posedge axi4_aclk)
   assign get_new = ((m_axi4_awvalid & m_axi4_awready & ~sending_l2) | (s_axi4_awvalid & l1_trans_drop));
   assign s_axi4_awready = (get_new && ~stall_aw) || (waiting_stall && ~stall_aw);
   always @(posedge axi4_aclk) begin
      if (axi4_arstn == 1'b0) begin
         waiting_stall <= 1'b0;
      end else
        // if 1: valid aw transaction at input & slave asserts awready & either transaction is accepted or we were waiting for awready. Not asserting awready for L2 transaction.
        //    2: valid aw transaction at input & transaction is dropped
        if (stall_aw && get_new) begin
           waiting_stall = 1'b1;
        end else if (s_axi4_awready) begin
           waiting_stall = 1'b0; 
        end
   end // always @ (posedge axi4_aclk)   
 
generate   
if (ENABLE_L2TLB    == 1) begin    
   reg [C_AXI_USER_WIDTH-1:0]     l2_axi4_awuser  ;   
   reg [3:0]                      l2_axi4_awcache ;
   reg [3:0]                      l2_axi4_awregion;
   reg [3:0]                      l2_axi4_awqos   ;
   reg [2:0]                      l2_axi4_awprot  ;
   reg                            l2_axi4_awlock  ;
   reg [1:0]                      l2_axi4_awburst ;
   reg [2:0]                      l2_axi4_awsize  ;
   reg [7:0]                      l2_axi4_awlen   ;
   reg [C_AXI_ID_WIDTH-1:0]       l2_axi4_awid    ;
   reg                            l2_waiting_awready;      

   assign m_axi4_awuser   = sending_l2 ? l2_axi4_awuser   : s_axi4_awuser;
   assign m_axi4_awcache  = sending_l2 ? l2_axi4_awcache  : s_axi4_awcache;
   assign m_axi4_awregion = sending_l2 ? l2_axi4_awregion : s_axi4_awregion;
   assign m_axi4_awqos    = sending_l2 ? l2_axi4_awqos    : s_axi4_awqos;
   assign m_axi4_awprot   = sending_l2 ? l2_axi4_awprot   : s_axi4_awprot;
   assign m_axi4_awlock   = sending_l2 ? l2_axi4_awlock   : s_axi4_awlock;
   assign m_axi4_awburst  = sending_l2 ? l2_axi4_awburst  : s_axi4_awburst;
   assign m_axi4_awsize   = sending_l2 ? l2_axi4_awsize   : s_axi4_awsize;
   assign m_axi4_awlen    = sending_l2 ? l2_axi4_awlen    : s_axi4_awlen;
   assign m_axi4_awaddr   = sending_l2 ? l2_axi4_awaddr   : l1_axi4_awaddr;
   assign m_axi4_awid     = sending_l2 ? l2_axi4_awid     : s_axi4_awid;
     
   // Buffer AXI signals in case of L1 miss
   always @(posedge axi4_aclk or negedge axi4_arstn)
     begin
        if (axi4_arstn == 1'b0) begin
           l2_axi4_awuser  <= 0;
           l2_axi4_awcache <= 0;
           l2_axi4_awregion <= 0;
           l2_axi4_awqos   <= 0;
           l2_axi4_awprot  <= 0;
           l2_axi4_awlock  <= 0;
           l2_axi4_awburst <= 0;
           l2_axi4_awsize  <= 0;
           l2_axi4_awlen   <= 0;    
           l2_axi4_awid    <= 0;   
        end else if (l1_trans_drop) begin           
           l2_axi4_awuser  <= s_axi4_awuser;
           l2_axi4_awcache <= s_axi4_awcache;
           l2_axi4_awregion <= s_axi4_awregion;
           l2_axi4_awqos   <= s_axi4_awqos;
           l2_axi4_awprot  <= s_axi4_awprot;
           l2_axi4_awlock  <= s_axi4_awlock;
           l2_axi4_awburst <= s_axi4_awburst;
           l2_axi4_awsize  <= s_axi4_awsize;
           l2_axi4_awlen   <= s_axi4_awlen;           
           l2_axi4_awid    <= s_axi4_awid;
        end // if (l1_trans_drop == 1'b1)
     end // always_ff @ (posedge axi4_aclk or negedge axi4_arstn)

   // keep sending L2 trans until ready is received
  always @(posedge axi4_aclk or negedge axi4_arstn)
    begin: l2_buffers_sequential
      if (axi4_arstn == 1'b0)
        l2_waiting_awready = 1'b0;
      else if (sending_l2 & m_axi4_awvalid & m_axi4_awready) // sending L2 trans
        l2_waiting_awready = 1'b0;
      else if (l2_trans_accept) // L2 hit
        l2_waiting_awready = 1'b1;
    end  

   assign sending_l2     = l2_trans_accept | l2_waiting_awready;
   assign l2_wtrans_sent = m_axi4_awvalid & m_axi4_awready & sending_l2;   

end else begin
   assign sending_l2     = 1'b0;
   assign l2_wtrans_sent = 1'b0;

   assign m_axi4_awuser   =  s_axi4_awuser;
   assign m_axi4_awcache  =  s_axi4_awcache;
   assign m_axi4_awregion =  s_axi4_awregion;
   assign m_axi4_awqos    =  s_axi4_awqos;
   assign m_axi4_awprot   =  s_axi4_awprot;
   assign m_axi4_awlock   =  s_axi4_awlock;
   assign m_axi4_awburst  =  s_axi4_awburst;
   assign m_axi4_awsize   =  s_axi4_awsize;
   assign m_axi4_awlen    =  s_axi4_awlen;
   assign m_axi4_awaddr   =  l1_axi4_awaddr;
   assign m_axi4_awid     =  s_axi4_awid;   
   
end // !`ifdef ENABLE_L2TLB
endgenerate   
   


// What happens when both L1 and L2 accept/drop happen together ?
// Ans: L2 trans will be sent first. But L1_accept will be recorded via l1_waiting_awready and L1 trans can be sent in next cycle.
   
endmodule



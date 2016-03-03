`include "ulpsoc_defines.sv"
module axi_rab_top   
  #(
    parameter NUM_SLICES          = 16,
    parameter C_AXI_DATA_WIDTH    = 64,
    parameter C_AXICFG_DATA_WIDTH = 32,
    parameter C_AXI_ID_WIDTH      = 8,
    parameter C_AXI_USER_WIDTH    = 6,
    parameter N_PORTS             = 2
    )
   (
    input   logic axi4_aclk,
    input   logic axi4_arstn,
    input   logic axi4lite_aclk,
    input   logic axi4lite_arstn,

    input   logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] s_axi4_awid,
    input   logic    [N_PORTS-1:0]                   [31:0] s_axi4_awaddr,
    input   logic    [N_PORTS-1:0]                          s_axi4_awvalid,
    output  logic    [N_PORTS-1:0]        	                s_axi4_awready,
    input   logic    [N_PORTS-1:0]       	           [7:0]  s_axi4_awlen,
    input   logic    [N_PORTS-1:0]                   [2:0]  s_axi4_awsize,
    input   logic    [N_PORTS-1:0]                   [1:0]  s_axi4_awburst,
    input   logic    [N_PORTS-1:0]                          s_axi4_awlock,
    input   logic    [N_PORTS-1:0]      	           [2:0]  s_axi4_awprot,
    input   logic    [N_PORTS-1:0]      	           [3:0]  s_axi4_awcache,
    input   logic    [N_PORTS-1:0]      	           [3:0]  s_axi4_awregion,
    input   logic    [N_PORTS-1:0]     	             [3:0]  s_axi4_awqos,
    input   logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] s_axi4_awuser,

    input   logic    [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] s_axi4_wdata,
    input   logic    [N_PORTS-1:0] 	                        s_axi4_wvalid,
    output  logic    [N_PORTS-1:0]  	                      s_axi4_wready,
    input   logic    [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0] s_axi4_wstrb,
    input   logic    [N_PORTS-1:0]                          s_axi4_wlast,
    input   logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] s_axi4_wuser,

    output  logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] s_axi4_bid,
    output  logic    [N_PORTS-1:0]                    [1:0] s_axi4_bresp,
    output  logic    [N_PORTS-1:0]                          s_axi4_bvalid,
    output  logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] s_axi4_buser,
    input   logic    [N_PORTS-1:0]                          s_axi4_bready,

    input   logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] s_axi4_arid,
    input   logic    [N_PORTS-1:0]                   [31:0] s_axi4_araddr,
    input   logic    [N_PORTS-1:0]          	              s_axi4_arvalid,
    output  logic    [N_PORTS-1:0]                          s_axi4_arready,
    input   logic    [N_PORTS-1:0]          	       [7:0]  s_axi4_arlen,
    input   logic    [N_PORTS-1:0]          	       [2:0]  s_axi4_arsize,
    input   logic    [N_PORTS-1:0]                   [1:0]  s_axi4_arburst,
    input   logic    [N_PORTS-1:0]                          s_axi4_arlock,
    input   logic    [N_PORTS-1:0]         	         [2:0]  s_axi4_arprot,
    input   logic    [N_PORTS-1:0]                   [3:0]  s_axi4_arcache,
    input   logic    [N_PORTS-1:0]  [C_AXI_USER_WIDTH-1:0]  s_axi4_aruser,

    output  logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] s_axi4_rid,
    output  logic    [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] s_axi4_rdata,
    output  logic    [N_PORTS-1:0]                    [1:0] s_axi4_rresp,
    output  logic    [N_PORTS-1:0]                          s_axi4_rvalid,
    input   logic    [N_PORTS-1:0]                          s_axi4_rready,
    output  logic    [N_PORTS-1:0]                          s_axi4_rlast,
    output  logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] s_axi4_ruser,

    output  logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] m_axi4_awid,
    output  logic    [N_PORTS-1:0]                   [31:0] m_axi4_awaddr,
    output  logic    [N_PORTS-1:0]           	            m_axi4_awvalid,
    input   logic    [N_PORTS-1:0]           	            m_axi4_awready,
    output  logic    [N_PORTS-1:0]          	     [7:0]  m_axi4_awlen,
    output  logic    [N_PORTS-1:0]           	     [2:0]  m_axi4_awsize,
    output  logic    [N_PORTS-1:0]                 [1:0]  m_axi4_awburst,
    output  logic    [N_PORTS-1:0]                        m_axi4_awlock,
    output  logic    [N_PORTS-1:0]           	     [2:0]  m_axi4_awprot,
    output  logic    [N_PORTS-1:0]           	     [3:0]  m_axi4_awcache,
    output  logic    [N_PORTS-1:0]           	     [3:0]  m_axi4_awregion,
    output  logic    [N_PORTS-1:0]           	     [3:0]  m_axi4_awqos,
    output  logic    [N_PORTS-1:0]  [C_AXI_USER_WIDTH-1:0]  m_axi4_awuser,

    output  logic    [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] m_axi4_wdata,
    output  logic    [N_PORTS-1:0]                          m_axi4_wvalid,
    input   logic    [N_PORTS-1:0]                          m_axi4_wready,
    output  logic    [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0] m_axi4_wstrb,
    output  logic    [N_PORTS-1:0]                          m_axi4_wlast,
    output  logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] m_axi4_wuser,

    input   logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] m_axi4_bid,
    input   logic    [N_PORTS-1:0]                    [1:0] m_axi4_bresp,
    input   logic    [N_PORTS-1:0]                          m_axi4_bvalid,
    input   logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] m_axi4_buser,
    output  logic    [N_PORTS-1:0]                          m_axi4_bready,

    output  logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] m_axi4_arid,
    output  logic    [N_PORTS-1:0]                   [31:0] m_axi4_araddr,
    output  logic    [N_PORTS-1:0]                          m_axi4_arvalid,
    input   logic    [N_PORTS-1:0]           	              m_axi4_arready,
    output  logic    [N_PORTS-1:0]          	       [7:0]  m_axi4_arlen,
    output  logic    [N_PORTS-1:0]           	       [2:0]  m_axi4_arsize,
    output  logic    [N_PORTS-1:0]                   [1:0]  m_axi4_arburst,
    output  logic    [N_PORTS-1:0]                          m_axi4_arlock,
    output  logic    [N_PORTS-1:0]           	       [2:0]  m_axi4_arprot,
    output  logic    [N_PORTS-1:0]           	       [3:0]  m_axi4_arcache,
    output  logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] m_axi4_aruser,

    input   logic    [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] m_axi4_rid,
    input   logic    [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] m_axi4_rdata,
    input   logic    [N_PORTS-1:0]                    [1:0] m_axi4_rresp,
    input   logic    [N_PORTS-1:0]           	              m_axi4_rvalid,
    output  logic    [N_PORTS-1:0]           	              m_axi4_rready,
    input   logic    [N_PORTS-1:0]          	              m_axi4_rlast,
    input   logic    [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] m_axi4_ruser,

    input    logic                      [31:0] s_axi4lite_awaddr,
    input    logic                             s_axi4lite_awvalid,
    output   logic                             s_axi4lite_awready,

    input    logic   [C_AXICFG_DATA_WIDTH-1:0] s_axi4lite_wdata,
    input    logic           	                 s_axi4lite_wvalid,
    output   logic             	               s_axi4lite_wready,
    input    logic [C_AXICFG_DATA_WIDTH/8-1:0] s_axi4lite_wstrb,

    output   logic                       [1:0] s_axi4lite_bresp,
    output   logic                             s_axi4lite_bvalid,
    input    logic                             s_axi4lite_bready,

    input    logic                      [31:0] s_axi4lite_araddr,
    input    logic           	                 s_axi4lite_arvalid,
    output   logic             	               s_axi4lite_arready,

    output   logic   [C_AXICFG_DATA_WIDTH-1:0] s_axi4lite_rdata,
    output   logic                       [1:0] s_axi4lite_rresp,
    output   logic                             s_axi4lite_rvalid,
    input    logic                             s_axi4lite_rready,

    output   logic [N_PORTS-1:0]               int_miss,
    output   logic [N_PORTS-1:0]               int_multi,
    output   logic [N_PORTS-1:0]               int_prot,
    output   logic                             int_mhr_full
    );
   
   wire [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0] int_awid;
   wire [N_PORTS-1:0]                    [31:0] int_awaddr;
   wire [N_PORTS-1:0]                           int_awvalid;
   wire [N_PORTS-1:0]                           int_awready;
   wire [N_PORTS-1:0]        	          [7:0]   int_awlen;
   wire [N_PORTS-1:0]                     [2:0] int_awsize;
   wire [N_PORTS-1:0]                     [1:0] int_awburst;
   wire [N_PORTS-1:0]                           int_awlock;
   wire [N_PORTS-1:0]                     [2:0] int_awprot;
   wire [N_PORTS-1:0]                     [3:0] int_awcache;
   wire [N_PORTS-1:0]                     [3:0] int_awregion;
   wire [N_PORTS-1:0]                     [3:0] int_awqos;
   wire [N_PORTS-1:0]    [C_AXI_USER_WIDTH-1:0] int_awuser;
   
   wire [N_PORTS-1:0]    [C_AXI_DATA_WIDTH-1:0] int_wdata;
   wire [N_PORTS-1:0]                           int_wvalid;
   wire [N_PORTS-1:0]                           int_wready;
   wire  [N_PORTS-1:0]  [C_AXI_DATA_WIDTH/8-1:0] int_wstrb;
   wire [N_PORTS-1:0]                            int_wlast;
   wire [N_PORTS-1:0]    [C_AXI_USER_WIDTH-1:0]  int_wuser;
   
   wire [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0]  int_bid;
   wire [N_PORTS-1:0]                     [1:0]  int_bresp;
   wire [N_PORTS-1:0]                            int_bvalid;
   wire [N_PORTS-1:0]    [C_AXI_USER_WIDTH-1:0]  int_buser;
   wire [N_PORTS-1:0]                            int_bready;
   
   wire [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0]  int_arid;
   wire [N_PORTS-1:0]                    [31:0]  int_araddr;
   wire [N_PORTS-1:0]                            int_arvalid;
   wire [N_PORTS-1:0]                            int_arready;
   wire [N_PORTS-1:0]        	          [7:0]    int_arlen;
   wire [N_PORTS-1:0]        	          [2:0]    int_arsize;
   wire [N_PORTS-1:0]                     [1:0]  int_arburst;
   wire [N_PORTS-1:0]                            int_arlock;
   wire [N_PORTS-1:0]        	          [2:0]    int_arprot;
   wire [N_PORTS-1:0]        	          [3:0]    int_arcache;
   wire [N_PORTS-1:0]    [C_AXI_USER_WIDTH-1:0]  int_aruser;
   
   wire  [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0] int_rid;
   wire [N_PORTS-1:0]                     [1:0]  int_rresp;
   wire [N_PORTS-1:0]    [C_AXI_DATA_WIDTH-1:0]  int_rdata;
   wire [N_PORTS-1:0]                            int_rlast;
   wire [N_PORTS-1:0]    [C_AXI_USER_WIDTH-1:0]  int_ruser;
   wire [N_PORTS-1:0]                            int_rvalid;
   wire [N_PORTS-1:0]                            int_rready;
   
   wire [N_PORTS-1:0]                    [31:0]  int_wtrans_addr;
   wire [N_PORTS-1:0]                            int_wtrans_accept;
   wire [N_PORTS-1:0]                            int_wtrans_drop;
   wire [N_PORTS-1:0]                            int_wtrans_sent;
   
   wire [N_PORTS-1:0]                    [31:0] int_rtrans_addr;
   wire [N_PORTS-1:0]                           int_rtrans_accept;
   wire [N_PORTS-1:0]                           int_rtrans_drop;
   wire [N_PORTS-1:0]                           int_rtrans_sent;

   logic [N_PORTS-1:0]                          l1_miss;  // Trigger for L2
   wire [N_PORTS-1:0]                           rab_miss; // L1/RAB miss
   wire [N_PORTS-1:0]                           rab_prot;
   wire [N_PORTS-1:0]                           rab_multi;
   wire [N_PORTS-1:0]                           int_prot_next,int_multi_next;
   
   wire [N_PORTS-1:0]                           stall_aw; // Stall AW channel till wlast is received
   wire [N_PORTS-1:0]                           wlast_received;
   wire [N_PORTS-1:0]                           response_sent;
   wire [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0] trans_awid;
   wire [N_PORTS-1:0]      [C_AXI_ID_WIDTH-1:0] trans_arid;
   wire [N_PORTS-1:0]                           wtrans_drop,rtrans_drop; // signals used in rwch,rrch senders
   logic [N_PORTS-1:0]                          l1_multi_or_prot;
   logic [N_PORTS-1:0]                          l1_wtrans_drop_saved, l1_rtrans_drop_saved;
//   logic [N_PORTS-1:0]                          l1_wtrans_drop_next, l1_rtrans_drop_next;

   logic [N_PORTS-1:0] [31:0]                   l2_in_addr, l2_in_addr_saved;
   wire  [N_PORTS-1:0]                          l2_wtrans_accept;
   wire  [N_PORTS-1:0]                          l2_rtrans_accept;
   logic [N_PORTS-1:0]                          l2_wtrans_drop,l1_wtrans_drop;
   logic [N_PORTS-1:0]                          l2_rtrans_drop,l1_rtrans_drop;
   wire  [N_PORTS-1:0] [31:0]                   l2_wtrans_addr;
   wire  [N_PORTS-1:0] [31:0]                   l2_rtrans_addr;
   wire  [N_PORTS-1:0]                          l2_trans_sent;
   wire  [N_PORTS-1:0]                          l2_wtrans_sent;
   wire  [N_PORTS-1:0]                          l2_rtrans_sent;
   wire  [N_PORTS-1:0]                          l2_busy;
   wire  [N_PORTS-1:0] [31:0]                   l2_out_addr;
   reg   [N_PORTS-1:0]                          l2_rw_type,l2_rw_type_comb,l2_rw_type_seq;
   reg   [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     l2_awid;
   reg   [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     l2_arid;
   wire  [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     trans_id_l2;
   logic [N_PORTS-1:0]                          double_prot,double_prot_en;
   logic [N_PORTS-1:0]                          double_multi,double_multi_en;
   logic [N_PORTS-1:0]                          l1_multi_or_prot_next;
   logic [N_PORTS-1:0]                          update_id, update_id_next;
   
    // L2 outputs
   wire [N_PORTS-1:0]                           miss_l2;
   wire [N_PORTS-1:0]                           hit_l2;
   wire [N_PORTS-1:0]                           prot_l2;
   wire [N_PORTS-1:0]                           multi_l2;

   // L2 RAM configuration signals
   wire [N_PORTS-1:0] [C_AXICFG_DATA_WIDTH-1:0] wdata_tlb_l2;
   wire [N_PORTS-1:0] [31:0]                    waddr_tlb_l2;
   wire [N_PORTS-1:0]                           wren_tlb_l2; 
   
   genvar 					i;

   // L2 FSM
   typedef enum     logic[2:0] {L2_IDLE, L2_BUSY, L1_WAITING, L1_MULTI_PROT, L1_MULTI_PROT_1, L1_MULTI_PROT_WAITING} l2_state_t;   
   l2_state_t [N_PORTS-1:0] [2:0] l2_state,l2_next_state;   

  // Enable L2 for select ports
   localparam integer ENABLE_L2TLB[N_PORTS-1:0] = `EN_L2TLB_ARRAY;    

generate for (i = 0; i < N_PORTS; i++) begin

  axi4_awch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_awinbuffer(
                            .axi4_aclk       (axi4_aclk),
                            .axi4_arstn      (axi4_arstn),
                            .s_axi4_awid     (s_axi4_awid [i]),
                            .s_axi4_awaddr   (s_axi4_awaddr [i]),
                            .s_axi4_awvalid  (s_axi4_awvalid [i]),
                            .s_axi4_awready  (s_axi4_awready [i]),
                            .s_axi4_awlen    (s_axi4_awlen [i]),
                            .s_axi4_awsize   (s_axi4_awsize [i]),
                            .s_axi4_awburst  (s_axi4_awburst [i]),
                            .s_axi4_awlock   (s_axi4_awlock [i]),
                            .s_axi4_awprot   (s_axi4_awprot [i]),
                            .s_axi4_awcache  (s_axi4_awcache [i]),
                            .s_axi4_awregion (s_axi4_awregion [i]),
                            .s_axi4_awqos    (s_axi4_awqos [i]),
                            .s_axi4_awuser   (s_axi4_awuser [i]),
                            .m_axi4_awid     (int_awid [i]),
                            .m_axi4_awaddr   (int_awaddr [i]),
                            .m_axi4_awvalid  (int_awvalid [i]),
                            .m_axi4_awready  (int_awready [i]),
                            .m_axi4_awlen    (int_awlen [i]),
                            .m_axi4_awsize   (int_awsize [i]),
                            .m_axi4_awburst  (int_awburst [i]),
                            .m_axi4_awlock   (int_awlock [i]),
                            .m_axi4_awprot   (int_awprot [i]),
                            .m_axi4_awcache  (int_awcache [i]),
                            .m_axi4_awregion (int_awregion [i]),
                            .m_axi4_awqos    (int_awqos [i]),
                            .m_axi4_awuser   (int_awuser [i]));

  axi4_awch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH,ENABLE_L2TLB[i]) u_awsender(
			                      .axi4_aclk       (axi4_aclk),
                            .axi4_arstn      (axi4_arstn),
                            .l1_trans_accept (int_wtrans_accept[i]),
                            .l1_trans_drop   (l1_wtrans_drop[i]),
                            .l1_trans_sent   (int_wtrans_sent[i]),
                            .l2_trans_accept (l2_wtrans_accept[i]),
                            .l2_busy         (l2_busy[i]),
                            .l2_wtrans_sent  (l2_wtrans_sent[i]),
                            .stall_aw        (stall_aw[i]),                                 
                            .s_axi4_awid     (int_awid[i]),
                            .l1_axi4_awaddr  (int_wtrans_addr[i]), //gets the modified address
                            .l2_axi4_awaddr  (l2_wtrans_addr[i]), //gets the modified address from L2
                            .s_axi4_awvalid  (int_awvalid[i]),
                            .s_axi4_awready  (int_awready[i]),
                            .s_axi4_awlen    (int_awlen[i]),
                            .s_axi4_awsize   (int_awsize[i]),
                            .s_axi4_awburst  (int_awburst[i]),
                            .s_axi4_awlock   (int_awlock[i]),
                            .s_axi4_awprot   (int_awprot[i]),
                            .s_axi4_awcache  (int_awcache[i]),
                            .s_axi4_awregion (int_awregion[i]),
                            .s_axi4_awqos    (int_awqos[i]),
                            .s_axi4_awuser   (int_awuser[i]),
                            .m_axi4_awid     (m_axi4_awid[i]),
                            .m_axi4_awaddr   (m_axi4_awaddr[i]),
                            .m_axi4_awvalid  (m_axi4_awvalid[i]),
                            .m_axi4_awready  (m_axi4_awready[i]),
                            .m_axi4_awlen    (m_axi4_awlen[i]),
                            .m_axi4_awsize   (m_axi4_awsize[i]),
                            .m_axi4_awburst  (m_axi4_awburst[i]),
                            .m_axi4_awlock   (m_axi4_awlock[i]),
                            .m_axi4_awprot   (m_axi4_awprot[i]),
                            .m_axi4_awcache  (m_axi4_awcache[i]),
                            .m_axi4_awregion (m_axi4_awregion[i]),
                            .m_axi4_awqos    (m_axi4_awqos[i]),
                            .m_axi4_awuser   (m_axi4_awuser[i]));

axi4_dwch_buffer #(C_AXI_DATA_WIDTH,C_AXI_USER_WIDTH) u_dwinbuffer(
                            .axi4_aclk     (axi4_aclk),
                            .axi4_arstn    (axi4_arstn),
                            .s_axi4_wdata  (s_axi4_wdata [i]),
                            .s_axi4_wvalid (s_axi4_wvalid [i]),
                            .s_axi4_wready (s_axi4_wready [i]),
                            .s_axi4_wstrb  (s_axi4_wstrb [i]),
                            .s_axi4_wlast  (s_axi4_wlast [i]),
                            .s_axi4_wuser  (s_axi4_wuser [i]),
                            .m_axi4_wdata  (int_wdata [i]),
                            .m_axi4_wvalid (int_wvalid [i]),
                            .m_axi4_wready (int_wready [i]),
                            .m_axi4_wstrb  (int_wstrb [i]),
                            .m_axi4_wlast  (int_wlast [i]),
                            .m_axi4_wuser  (int_wuser [i]));

axi4_dwch_sender #(C_AXI_DATA_WIDTH,C_AXI_USER_WIDTH,ENABLE_L2TLB[i]) u_dwsender(
                            .axi4_aclk       (axi4_aclk),
                            .axi4_arstn      (axi4_arstn),
                            .l1_trans_accept (int_wtrans_accept[i]),
                            .l2_trans_accept (l2_wtrans_accept[i]),                                     
                            .l2_trans_drop   (l2_wtrans_drop[i]),
                            .l1_miss         (l1_wtrans_drop[i]),                                     
                            .stall_aw        (stall_aw[i]),
                            .wlast_received  (wlast_received[i]),
                            .response_sent   (response_sent[i]),                                                                              
                            .s_axi4_wdata    (int_wdata[i]),
                            .s_axi4_wvalid   (int_wvalid[i]),
                            .s_axi4_wready   (int_wready[i]),
                            .s_axi4_wstrb    (int_wstrb[i]),
                            .s_axi4_wlast    (int_wlast[i]),
                            .s_axi4_wuser    (int_wuser[i]),
                            .m_axi4_wdata    (m_axi4_wdata[i]),
                            .m_axi4_wvalid   (m_axi4_wvalid[i]),
                            .m_axi4_wready   (m_axi4_wready[i]),
                            .m_axi4_wstrb    (m_axi4_wstrb[i]),
                            .m_axi4_wlast    (m_axi4_wlast[i]),
                            .m_axi4_wuser    (m_axi4_wuser[i]));


axi4_rwch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rwchbuffer(
                            .axi4_aclk     (axi4_aclk),
                            .axi4_arstn    (axi4_arstn),
                            .s_axi4_bid    (int_bid [i]),
                            .s_axi4_bresp  (int_bresp [i]),
                            .s_axi4_bvalid (int_bvalid [i]),
                            .s_axi4_buser  (int_buser [i]),
                            .s_axi4_bready (int_bready [i]),
                            .m_axi4_bid    (m_axi4_bid [i]),
                            .m_axi4_bresp  (m_axi4_bresp [i]),
                            .m_axi4_bvalid (m_axi4_bvalid [i]),
                            .m_axi4_buser  (m_axi4_buser [i]),
                            .m_axi4_bready (m_axi4_bready [i]));

axi4_rwch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH,ENABLE_L2TLB[i]) u_rwchsender( 
                            .axi4_aclk      (axi4_aclk),
                            .axi4_arstn     (axi4_arstn),                                                              
                            .trans_id       (trans_awid[i]),
                            .trans_drop     (wtrans_drop[i]),                                                              
                            .wlast_received (wlast_received[i]),
                            .response_sent  (response_sent[i]),                                     
                            .s_axi4_wvalid  (int_wvalid[i]),
                            .s_axi4_wlast   (int_wlast[i]),
                            .s_axi4_wready  (int_wready[i]),
                            .s_axi4_bid     (s_axi4_bid[i]),
                            .s_axi4_bresp   (s_axi4_bresp[i]),
                            .s_axi4_bvalid  (s_axi4_bvalid[i]),
                            .s_axi4_buser   (s_axi4_buser[i]),
                            .s_axi4_bready  (s_axi4_bready[i]),
                            .m_axi4_bid     (int_bid[i]),
                            .m_axi4_bresp   (int_bresp[i]),
                            .m_axi4_bvalid  (int_bvalid[i]),
                            .m_axi4_buser   (int_buser[i]),
                            .m_axi4_bready  (int_bready[i]));

 axi4_arch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_arinbuffer(
                            .axi4_aclk      (axi4_aclk),
                            .axi4_arstn     (axi4_arstn),
                            .s_axi4_arid    (s_axi4_arid [i]),
                            .s_axi4_araddr  (s_axi4_araddr [i]),
                            .s_axi4_arvalid (s_axi4_arvalid [i]),
                            .s_axi4_arready (s_axi4_arready [i]),
                            .s_axi4_arlen   (s_axi4_arlen [i]),
                            .s_axi4_arsize  (s_axi4_arsize [i]),
                            .s_axi4_arburst (s_axi4_arburst [i]),
                            .s_axi4_arlock  (s_axi4_arlock [i]),
                            .s_axi4_arprot  (s_axi4_arprot [i]),
                            .s_axi4_arcache (s_axi4_arcache [i]),
                            .s_axi4_aruser  (s_axi4_aruser [i]),
                            .m_axi4_arid    (int_arid [i]),
                            .m_axi4_araddr  (int_araddr [i]),
                            .m_axi4_arvalid (int_arvalid [i]),
                            .m_axi4_arready (int_arready [i]),
                            .m_axi4_arlen   (int_arlen [i]),
                            .m_axi4_arsize  (int_arsize [i]),
                            .m_axi4_arburst (int_arburst [i]),
                            .m_axi4_arlock  (int_arlock [i]),
                            .m_axi4_arprot  (int_arprot [i]),
                            .m_axi4_arcache (int_arcache [i]),
                            .m_axi4_aruser  (int_aruser [i]));

  axi4_arch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH,ENABLE_L2TLB[i]) u_arsender(
			                      .axi4_aclk       (axi4_aclk),
                            .axi4_arstn      (axi4_arstn),
                            .l1_trans_accept (int_rtrans_accept[i]),
                            .l1_trans_drop   (l1_rtrans_drop[i]),
                            .l1_trans_sent   (int_rtrans_sent[i]),
                            .l2_trans_accept (l2_rtrans_accept[i]),
                            .l2_busy         (l2_busy[i]),
                            .l2_rtrans_sent  (l2_rtrans_sent[i]),         
                            .s_axi4_arid     (int_arid[i]),
                            .l1_axi4_araddr  (int_rtrans_addr[i]), //gets the modified address
                            .l2_axi4_araddr  (l2_rtrans_addr[i]),  //gets the modified address from L2                                  
                            .s_axi4_arvalid  (int_arvalid[i]),
                            .s_axi4_arready  (int_arready[i]),
                            .s_axi4_arlen    (int_arlen[i]),
                            .s_axi4_arsize   (int_arsize[i]),
                            .s_axi4_arburst  (int_arburst[i]),
                            .s_axi4_arlock   (int_arlock[i]),
                            .s_axi4_arprot   (int_arprot[i]),
                            .s_axi4_arcache  (int_arcache[i]),
                            .s_axi4_aruser   (int_aruser[i]),
                            .m_axi4_arid     (m_axi4_arid[i]),
                            .m_axi4_araddr   (m_axi4_araddr[i]),
                            .m_axi4_arvalid  (m_axi4_arvalid[i]),
                            .m_axi4_arready  (m_axi4_arready[i]),
                            .m_axi4_arlen    (m_axi4_arlen[i]),
                            .m_axi4_arsize   (m_axi4_arsize[i]),
                            .m_axi4_arburst  (m_axi4_arburst[i]),
                            .m_axi4_arlock   (m_axi4_arlock[i]),
                            .m_axi4_arprot   (m_axi4_arprot[i]),
                            .m_axi4_arcache  (m_axi4_arcache[i]),
                            .m_axi4_aruser   (m_axi4_aruser[i]));

axi4_rrch_buffer #(C_AXI_DATA_WIDTH,C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rrchbuffer(
                            .axi4_aclk     (axi4_aclk),
                            .axi4_arstn    (axi4_arstn),
                            .s_axi4_rid    (int_rid [i]),
                            .s_axi4_rresp  (int_rresp [i]),
                            .s_axi4_rdata  (int_rdata [i]),
                            .s_axi4_rlast  (int_rlast [i]),
                            .s_axi4_rvalid (int_rvalid [i]),
                            .s_axi4_ruser  (int_ruser [i]),
                            .s_axi4_rready (int_rready [i]),
                            .m_axi4_rid    (m_axi4_rid [i]),
                            .m_axi4_rresp  (m_axi4_rresp [i]),
                            .m_axi4_rdata  (m_axi4_rdata [i]),
                            .m_axi4_rlast  (m_axi4_rlast [i]),
                            .m_axi4_rvalid (m_axi4_rvalid [i]),
                            .m_axi4_ruser  (m_axi4_ruser [i]),
                            .m_axi4_rready (m_axi4_rready [i]));

axi4_rrch_sender #(C_AXI_DATA_WIDTH,C_AXI_ID_WIDTH,C_AXI_USER_WIDTH,ENABLE_L2TLB[i]) u_rrchsender(
                            .axi4_aclk     (axi4_aclk),
                            .axi4_arstn    (axi4_arstn),
                            .trans_id      (trans_arid[i]),
                            .trans_drop    (rtrans_drop[i]),                                                                                 
                            .s_axi4_rid    (s_axi4_rid[i]),
                            .s_axi4_rresp  (s_axi4_rresp[i]),
                            .s_axi4_rdata  (s_axi4_rdata[i]),
                            .s_axi4_rlast  (s_axi4_rlast[i]),
                            .s_axi4_rvalid (s_axi4_rvalid[i]),
                            .s_axi4_ruser  (s_axi4_ruser[i]),
                            .s_axi4_rready (s_axi4_rready[i]),
                            .m_axi4_rid    (int_rid[i]),
                            .m_axi4_rresp  (int_rresp[i]),
                            .m_axi4_rdata  (int_rdata[i]),
                            .m_axi4_rlast  (int_rlast[i]),
                            .m_axi4_rvalid (int_rvalid[i]),
                            .m_axi4_ruser  (int_ruser[i]),
                            .m_axi4_rready (int_rready[i]));
    
    end
endgenerate

   rab_core
     #(
       .C_AXI_DATA_WIDTH   (C_AXI_DATA_WIDTH),
       .C_AXICFG_DATA_WIDTH(C_AXICFG_DATA_WIDTH),
       .C_AXI_ID_WIDTH     (C_AXI_ID_WIDTH),
       .C_AXI_USER_WIDTH   (C_AXI_USER_WIDTH), 
       .N_PORTS            (N_PORTS)
       ) 
   u_rab_core
     (
		  .s_axi_aclk       (axi4lite_aclk),
		  .s_axi_aresetn    (axi4lite_arstn),
		  .s_axi_awaddr     (s_axi4lite_awaddr),
		  .s_axi_awvalid    (s_axi4lite_awvalid),
		  .s_axi_awready    (s_axi4lite_awready),
		  .s_axi_wdata      (s_axi4lite_wdata),
		  .s_axi_wstrb      (s_axi4lite_wstrb),
		  .s_axi_wvalid     (s_axi4lite_wvalid),
		  .s_axi_wready     (s_axi4lite_wready),
		  .s_axi_bresp      (s_axi4lite_bresp),
		  .s_axi_bvalid     (s_axi4lite_bvalid),
		  .s_axi_bready     (s_axi4lite_bready),
		  .s_axi_araddr     (s_axi4lite_araddr),
		  .s_axi_arvalid    (s_axi4lite_arvalid),
		  .s_axi_arready    (s_axi4lite_arready),
		  .s_axi_rready     (s_axi4lite_rready),
		  .s_axi_rdata      (s_axi4lite_rdata),
		  .s_axi_rresp      (s_axi4lite_rresp),
		  .s_axi_rvalid     (s_axi4lite_rvalid),
		  .int_miss         (rab_miss),
		  .int_multi        (rab_multi),
		  .int_prot         (rab_prot),
		  .int_mhr_full     (int_mhr_full),
		  .port1_addr       (int_awaddr),
		  .port1_id         (int_awid),                                                                                
		  .port1_len        (int_awlen),
		  .port1_size       (int_awsize),
		  .port1_addr_valid (int_awvalid),
		  .port1_type       ('1),
      .port1_ctrl       (int_awuser),
		  .port1_sent       (int_wtrans_sent),
		  .port1_out_addr   (int_wtrans_addr),
		  .port1_accept     (int_wtrans_accept),
		  .port1_drop       (int_wtrans_drop),
		  .port2_addr       (int_araddr),
		  .port2_id         (int_arid),
		  .port2_len        (int_arlen),
		  .port2_size       (int_arsize),
		  .port2_addr_valid (int_arvalid),
		  .port2_type       ('0),
      .port2_ctrl       (int_aruser),
		  .port2_sent       (int_rtrans_sent),
		  .port2_out_addr   (int_rtrans_addr),
		  .port2_accept     (int_rtrans_accept),
		  .port2_drop       (int_rtrans_drop),
      .miss_l2          (miss_l2),     
      .miss_addr_l2     (l2_in_addr),
      .miss_id_l2       (trans_id_l2),  
      .wdata_tlb_l2     (wdata_tlb_l2),
      .waddr_tlb_l2     (waddr_tlb_l2),
      .wren_tlb_l2      (wren_tlb_l2)      
      );


generate for (i = 0; i < N_PORTS; i++) begin 
   if (ENABLE_L2TLB[i] == 1) begin  
      tlb_l2
        #(
          .ADDR_WIDTH()
          )
      u_tlb_l2
        (
         .clk_i           (axi4lite_aclk),
         .rst_ni          (axi4lite_arstn),
         .in_addr         (l2_in_addr[i]),
         .rw_type         (l2_rw_type_comb[i]),
         .l1_miss         (l1_miss[i]),
         .we              (wren_tlb_l2[i]),
         .waddr           (waddr_tlb_l2[i]),
         .wdata           (wdata_tlb_l2[i]),
         .l2_trans_sent   (l2_trans_sent[i]),
         .miss_l2         (miss_l2[i]),
         .hit_l2          (hit_l2[i]),
         .multiple_hit_l2 (multi_l2[i]),
         .prot_l2         (prot_l2[i]),
         .l2_busy         (l2_busy[i]),
         .out_addr        (l2_out_addr[i])
         );

      assign l2_wtrans_accept[i] =  l2_rw_type[i] && hit_l2[i] && ~(multi_l2[i] || prot_l2[i]);
      assign l2_rtrans_accept[i] = ~l2_rw_type[i] && hit_l2[i] && ~(multi_l2[i] || prot_l2[i]);
      assign l2_wtrans_drop[i]   =  l2_rw_type[i] && (miss_l2[i] || multi_l2[i] || prot_l2[i] || l1_multi_or_prot_next[i]);
      assign l2_rtrans_drop[i]   = ~l2_rw_type[i] && (miss_l2[i] || multi_l2[i] || prot_l2[i] || l1_multi_or_prot_next[i]);
      assign l2_wtrans_addr[i]   =  l2_out_addr[i];
      assign l2_rtrans_addr[i]   =  l2_out_addr[i];
      assign l2_trans_sent[i]    =  l2_wtrans_sent[i] | l2_rtrans_sent[i];
      
      ////////////////////////// L2 FSM ////////////////////////////////////
      // In case of rab multi/prot, there is no need for L2. In this case, l1_<r/w>trans_drop is asserted, similar to
      // a rab_miss. l2_<w/r>_trans_drop is asserted in the next cycle so that the transaction is dropped in the sender modules.
      // If a rab miss/prot/multi occurs when L2 is busy, the RAB is blocked and the transaction goes into L2 when L2
      // becomes available.
      
      // FSM Sequential logic
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            l2_state[i] <= L2_IDLE;
         end else begin
            l2_state[i] <= l2_next_state[i];
         end
      end      

      // FSM Combinational logic
      always_comb begin
         l2_next_state[i]          = l2_state[i];
         l1_miss[i]                = 1'b0;
         l2_in_addr[i]             = 0;
         l1_wtrans_drop[i]    = 1'b0;
         l1_rtrans_drop[i]    = 1'b0;
         l1_multi_or_prot_next[i]  = 1'b0;
         update_id_next[i]         = 1'b0;
         unique case(l2_state[i])
           L2_IDLE : begin
              l2_in_addr[i]          = int_wtrans_drop[i] ? int_awaddr[i] :
                                       int_rtrans_drop[i] ? int_araddr[i] :
                                       0;
              l1_wtrans_drop[i] = int_wtrans_drop[i];
              l1_rtrans_drop[i] = int_rtrans_drop[i];
              if (rab_miss[i]) begin
                 l2_next_state[i]  = L2_BUSY;
                 l1_miss[i]        = 1'b1;
                 update_id_next[i] = 1'b1;                 
              end else if (rab_prot[i] || rab_multi[i]) begin
                 l2_next_state[i]  = L1_MULTI_PROT;
                 update_id_next[i] = 1'b1;
              end
           end // case: L2_IDLE
           
           L2_BUSY :
             if (rab_miss[i])
               l2_next_state[i] = L1_WAITING;
             else if (rab_prot[i] || rab_multi[i])
               l2_next_state[i] = L1_MULTI_PROT_WAITING;
             else if (~l2_busy[i])
               l2_next_state[i] = L2_IDLE;

           L1_WAITING : begin
              if (~l2_busy[i]) begin
                 l2_next_state[i]       = L2_BUSY;
                 l1_miss[i]             = 1'b1;
                 l1_wtrans_drop[i] = l1_wtrans_drop_saved[i];
                 l1_rtrans_drop[i] = l1_rtrans_drop_saved[i];
                 update_id_next[i]      = 1'b1;
              end
              l2_in_addr[i] = l1_wtrans_drop_saved[i] ? int_awaddr[i] :
                              l1_rtrans_drop_saved[i] ? int_araddr[i] :
                              0;
           end           

           L1_MULTI_PROT_WAITING : begin            
              if (~l2_busy[i]) begin
                 l2_next_state[i]       = L1_MULTI_PROT;
                 l1_wtrans_drop[i] = l1_wtrans_drop_saved[i];
                 l1_rtrans_drop[i] = l1_rtrans_drop_saved[i];
                 update_id_next[i]      = 1'b1;
              end  
           end
           
           L1_MULTI_PROT : begin
              l2_next_state[i]         = L1_MULTI_PROT_1;
              l1_multi_or_prot_next[i] = 1'b1;
           end

           L1_MULTI_PROT_1 : begin
              l2_in_addr[i]          = int_wtrans_drop[i] ? int_awaddr[i] :
                                       int_rtrans_drop[i] ? int_araddr[i] :
                                       0;
              l1_wtrans_drop[i] = int_wtrans_drop[i];
              l1_rtrans_drop[i] = int_rtrans_drop[i];              
              if (rab_miss[i]) begin
                 l2_next_state[i]  = L2_BUSY;
                 l1_miss[i]        = 1'b1;
                 update_id_next[i] = 1'b1;
              end else if (rab_prot[i] || rab_multi[i]) begin
                 l2_next_state[i]  = L1_MULTI_PROT;
                 update_id_next[i] = 1'b1;
              end else
                l2_next_state[i]   = L2_IDLE;
           end // case: L1_MULTI_PROT_1           
           
         endcase // case (l2_state[i])
      end // always_comb begin

      // ID
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            update_id[i] <= 1'b0;
         end else begin
            update_id[i] <= update_id_next[i];
         end
      end
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            l2_awid[i] <= 0;
            l2_arid[i] <= 0;            
         end else if (update_id) begin
            l2_awid[i] <= int_awid[i];
            l2_arid[i] <= int_arid[i];
         end
      end // always_ff @ (posedge axi4lite_aclk)      
      
      // Save drop status in flipflop
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            l1_wtrans_drop_saved[i] <= 1'b0;
            l1_rtrans_drop_saved[i] <= 1'b0;
         end else if (int_wtrans_drop[i]) begin
            l1_wtrans_drop_saved[i] <= 1'b1;
            l1_rtrans_drop_saved[i] <= 1'b0;
         end else if (int_rtrans_drop[i]) begin
            l1_wtrans_drop_saved[i] <= 1'b0;
            l1_rtrans_drop_saved[i] <= 1'b1;
         end        
      end

      // L1 drop
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            l1_multi_or_prot[i] <= 1'b0;
         end else begin
            l1_multi_or_prot[i] <= l1_multi_or_prot_next[i];
         end
      end // always_ff @ (posedge axi4lite_aclk)
      
      // Read/Write
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            l2_rw_type[i] <= 1'b0;
         end else if (l1_wtrans_drop[i] || l1_rtrans_drop[i]) begin
            l2_rw_type[i] <= l1_wtrans_drop[i]; //write=1, read=0
         end
      end
      assign l2_rw_type_comb[i] = l1_wtrans_drop[i];
      //assign l2_rw_type[i] = l1_miss[i] ? l2_rw_type_comb[i] : l2_rw_type_seq[i];
                         
      //////////////////////////////////////////////////////////////////////////////
      
      // In case of simultaneous L1 and L2 prot/multi, int_<prot/multi> needs to be asserted twice.
      assign double_prot_en[i]  = prot_l2[i]  && rab_prot[i];
      assign double_multi_en[i] = multi_l2[i] && rab_multi[i];
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            double_prot[i]  <= 1'b0;
            double_multi[i] <= 1'b0;
         end else begin
            double_prot[i]  <= double_prot_en[i];
            double_multi[i] <= double_multi_en[i];
         end
      end
      assign int_prot_next[i]  = prot_l2[i]  || rab_prot[i]  || double_prot[i];
      assign int_multi_next[i] = multi_l2[i] || rab_multi[i] || double_multi[i]; 
      always_ff @(posedge axi4lite_aclk) begin
         if (axi4lite_arstn == 0) begin
            int_prot[i]  <= 1'b0;
            int_multi[i] <= 1'b0;
         end else begin
            int_prot[i]  <= int_prot_next[i];
            int_multi[i] <= int_multi_next[i];
         end
      end            
      //
      assign int_miss[i]    = miss_l2[i];

      assign trans_awid[i]  = l2_awid[i];
      assign trans_arid[i]  = l2_arid[i];
      assign wtrans_drop[i] = l2_wtrans_drop[i];
      assign rtrans_drop[i] = l2_rtrans_drop[i];
      assign trans_id_l2[i] = l2_rw_type[i] ? l2_awid[i] : l2_arid[i];      
      
   end else begin // if (ENABLE_L2TLB[i] == 1) 
   
      assign l2_busy[i]          = 1'b0;
      assign l2_wtrans_accept[i] = 1'b0;
      assign l2_rtrans_accept[i] = 1'b0;
      assign l2_wtrans_drop[i]   = 1'b0;
      assign l2_rtrans_drop[i]   = 1'b0;
      assign l2_wtrans_addr[i]   = 0;
      assign l2_rtrans_addr[i]   = 0;
      assign trans_id_l2[i]      = 0;
      
      assign l1_wtrans_drop[i] = int_wtrans_drop[i];
      assign l1_rtrans_drop[i] = int_rtrans_drop[i];
      assign int_miss[i]       = rab_miss[i];
      assign int_prot[i]       = rab_prot[i];
      assign int_multi[i]      = rab_multi[i]; 
      assign trans_awid[i]     = int_awid[i];
      assign trans_arid[i]     = int_arid[i];
      assign wtrans_drop[i]    = int_wtrans_drop[i];
      assign rtrans_drop[i]    = int_rtrans_drop[i]; 
   end // !`ifdef ENABLE_L2TLB
end // for (i = 0; i < N_PORTS; i++)
endgenerate


endmodule


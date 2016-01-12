/*
 *
 * axi_rab_top
 * 
 * This file controls AXI operations and routing using the master select flag in
 * rab slices.
 * 
 * It uses the rab_core, which translates addresses, to manipulate axi
 * transactions
 * 
 * The five axi channels are each buffered on the input side using a FIFO,
 * described in axi4_XXch_buffer.
 * 
 * The rab lookup result is merged into the axi transaction via the
 * axi4_XXch_sender instances, which manage inserting error responses
 * for failed lookups
 * 
 * 
 * For every slave there are two master ports, which can be used. This decision
 * is made using the master_select flag (bit 3 of the protection flags) in the
 * rab slices.
 * 
 * Revisions:
 * 
 * v 2.0 Added support for two master ports per slave port
 *       (Conrad Burchert bconrad@ethz.ch)
 * 
 */


module axi_rab_top   
  #(
    parameter NUM_SLICES          = 16,
    parameter C_AXI_DATA_WIDTH    = 64,
    parameter C_AXICFG_DATA_WIDTH = 32,
    parameter C_AXI_ID_WIDTH      = 8,
    parameter C_AXI_USER_WIDTH    = 6,
    parameter N_PORTS             = 3
    )
   (
    // AXI ports. For every slave port there are two master ports. The master
    // port to use can be set using the master_select flag of the protection
    // bits of a slice
    
    input logic                                         axi4_aclk,
    input logic                                         axi4_arstn,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      s_axi4_awid,
    input logic [N_PORTS-1:0] [31:0]                    s_axi4_awaddr,
    input logic [N_PORTS-1:0]                           s_axi4_awvalid,
    output logic [N_PORTS-1:0]                          s_axi4_awready,
    input logic [N_PORTS-1:0] [7:0]                     s_axi4_awlen,
    input logic [N_PORTS-1:0] [2:0]                     s_axi4_awsize,
    input logic [N_PORTS-1:0] [1:0]                     s_axi4_awburst,
    input logic [N_PORTS-1:0]                           s_axi4_awlock,
    input logic [N_PORTS-1:0] [2:0]                     s_axi4_awprot,
    input logic [N_PORTS-1:0] [3:0]                     s_axi4_awcache,
    input logic [N_PORTS-1:0] [3:0]                     s_axi4_awregion,
    input logic [N_PORTS-1:0] [3:0]                     s_axi4_awqos,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    s_axi4_awuser,

    input logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]    s_axi4_wdata,
    input logic [N_PORTS-1:0]                           s_axi4_wvalid,
    output logic [N_PORTS-1:0]                          s_axi4_wready,
    input logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0]  s_axi4_wstrb,
    input logic [N_PORTS-1:0]                           s_axi4_wlast,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    s_axi4_wuser,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     s_axi4_bid,
    output logic [N_PORTS-1:0] [1:0]                    s_axi4_bresp,
    output logic [N_PORTS-1:0]                          s_axi4_bvalid,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   s_axi4_buser,
    input logic [N_PORTS-1:0]                           s_axi4_bready,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      s_axi4_arid,
    input logic [N_PORTS-1:0] [31:0]                    s_axi4_araddr,
    input logic [N_PORTS-1:0]                           s_axi4_arvalid,
    output logic [N_PORTS-1:0]                          s_axi4_arready,
    input logic [N_PORTS-1:0] [7:0]                     s_axi4_arlen,
    input logic [N_PORTS-1:0] [2:0]                     s_axi4_arsize,
    input logic [N_PORTS-1:0] [1:0]                     s_axi4_arburst,
    input logic [N_PORTS-1:0]                           s_axi4_arlock,
    input logic [N_PORTS-1:0] [2:0]                     s_axi4_arprot,
    input logic [N_PORTS-1:0] [3:0]                     s_axi4_arcache,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    s_axi4_aruser,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     s_axi4_rid,
    output logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]   s_axi4_rdata,
    output logic [N_PORTS-1:0] [1:0]                    s_axi4_rresp,
    output logic [N_PORTS-1:0]                          s_axi4_rvalid,
    input logic [N_PORTS-1:0]                           s_axi4_rready,
    output logic [N_PORTS-1:0]                          s_axi4_rlast,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   s_axi4_ruser,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     m0_axi4_awid,
    output logic [N_PORTS-1:0] [31:0]                   m0_axi4_awaddr,
    output logic [N_PORTS-1:0]                          m0_axi4_awvalid,
    input logic [N_PORTS-1:0]                           m0_axi4_awready,
    output logic [N_PORTS-1:0] [7:0]                    m0_axi4_awlen,
    output logic [N_PORTS-1:0] [2:0]                    m0_axi4_awsize,
    output logic [N_PORTS-1:0] [1:0]                    m0_axi4_awburst,
    output logic [N_PORTS-1:0]                          m0_axi4_awlock,
    output logic [N_PORTS-1:0] [2:0]                    m0_axi4_awprot,
    output logic [N_PORTS-1:0] [3:0]                    m0_axi4_awcache,
    output logic [N_PORTS-1:0] [3:0]                    m0_axi4_awregion,
    output logic [N_PORTS-1:0] [3:0]                    m0_axi4_awqos,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m0_axi4_awuser,

    output logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]   m0_axi4_wdata,
    output logic [N_PORTS-1:0]                          m0_axi4_wvalid,
    input logic [N_PORTS-1:0]                           m0_axi4_wready,
    output logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0] m0_axi4_wstrb,
    output logic [N_PORTS-1:0]                          m0_axi4_wlast,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m0_axi4_wuser,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      m0_axi4_bid,
    input logic [N_PORTS-1:0] [1:0]                     m0_axi4_bresp,
    input logic [N_PORTS-1:0]                           m0_axi4_bvalid,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    m0_axi4_buser,
    output logic [N_PORTS-1:0]                          m0_axi4_bready,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     m0_axi4_arid,
    output logic [N_PORTS-1:0] [31:0]                   m0_axi4_araddr,
    output logic [N_PORTS-1:0]                          m0_axi4_arvalid,
    input logic [N_PORTS-1:0]                           m0_axi4_arready,
    output logic [N_PORTS-1:0] [7:0]                    m0_axi4_arlen,
    output logic [N_PORTS-1:0] [2:0]                    m0_axi4_arsize,
    output logic [N_PORTS-1:0] [1:0]                    m0_axi4_arburst,
    output logic [N_PORTS-1:0]                          m0_axi4_arlock,
    output logic [N_PORTS-1:0] [2:0]                    m0_axi4_arprot,
    output logic [N_PORTS-1:0] [3:0]                    m0_axi4_arcache,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m0_axi4_aruser,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      m0_axi4_rid,
    input logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]    m0_axi4_rdata,
    input logic [N_PORTS-1:0] [1:0]                     m0_axi4_rresp,
    input logic [N_PORTS-1:0]                           m0_axi4_rvalid,
    output logic [N_PORTS-1:0]                          m0_axi4_rready,
    input logic [N_PORTS-1:0]                           m0_axi4_rlast,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    m0_axi4_ruser,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     m1_axi4_awid,
    output logic [N_PORTS-1:0] [31:0]                   m1_axi4_awaddr,
    output logic [N_PORTS-1:0]                          m1_axi4_awvalid,
    input logic [N_PORTS-1:0]                           m1_axi4_awready,
    output logic [N_PORTS-1:0] [7:0]                    m1_axi4_awlen,
    output logic [N_PORTS-1:0] [2:0]                    m1_axi4_awsize,
    output logic [N_PORTS-1:0] [1:0]                    m1_axi4_awburst,
    output logic [N_PORTS-1:0]                          m1_axi4_awlock,
    output logic [N_PORTS-1:0] [2:0]                    m1_axi4_awprot,
    output logic [N_PORTS-1:0] [3:0]                    m1_axi4_awcache,
    output logic [N_PORTS-1:0] [3:0]                    m1_axi4_awregion,
    output logic [N_PORTS-1:0] [3:0]                    m1_axi4_awqos,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m1_axi4_awuser,

    output logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]   m1_axi4_wdata,
    output logic [N_PORTS-1:0]                          m1_axi4_wvalid,
    input logic [N_PORTS-1:0]                           m1_axi4_wready,
    output logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0] m1_axi4_wstrb,
    output logic [N_PORTS-1:0]                          m1_axi4_wlast,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m1_axi4_wuser,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      m1_axi4_bid,
    input logic [N_PORTS-1:0] [1:0]                     m1_axi4_bresp,
    input logic [N_PORTS-1:0]                           m1_axi4_bvalid,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    m1_axi4_buser,
    output logic [N_PORTS-1:0]                          m1_axi4_bready,

    output logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]     m1_axi4_arid,
    output logic [N_PORTS-1:0] [31:0]                   m1_axi4_araddr,
    output logic [N_PORTS-1:0]                          m1_axi4_arvalid,
    input logic [N_PORTS-1:0]                           m1_axi4_arready,
    output logic [N_PORTS-1:0] [7:0]                    m1_axi4_arlen,
    output logic [N_PORTS-1:0] [2:0]                    m1_axi4_arsize,
    output logic [N_PORTS-1:0] [1:0]                    m1_axi4_arburst,
    output logic [N_PORTS-1:0]                          m1_axi4_arlock,
    output logic [N_PORTS-1:0] [2:0]                    m1_axi4_arprot,
    output logic [N_PORTS-1:0] [3:0]                    m1_axi4_arcache,
    output logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]   m1_axi4_aruser,

    input logic [N_PORTS-1:0] [C_AXI_ID_WIDTH-1:0]      m1_axi4_rid,
    input logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH-1:0]    m1_axi4_rdata,
    input logic [N_PORTS-1:0] [1:0]                     m1_axi4_rresp,
    input logic [N_PORTS-1:0]                           m1_axi4_rvalid,
    output logic [N_PORTS-1:0]                          m1_axi4_rready,
    input logic [N_PORTS-1:0]                           m1_axi4_rlast,
    input logic [N_PORTS-1:0] [C_AXI_USER_WIDTH-1:0]    m1_axi4_ruser,

    // axi4lite port to setup the rab slices
    // use this to program the configuration registers

    input logic                                         axi4lite_aclk,
    input logic                                         axi4lite_arstn,
    
    input logic [31:0]                                  s_axi4lite_awaddr,
    input logic                                         s_axi4lite_awvalid,
    output logic                                        s_axi4lite_awready,

    input logic [C_AXICFG_DATA_WIDTH-1:0]               s_axi4lite_wdata,
    input logic                                         s_axi4lite_wvalid,
    output logic                                        s_axi4lite_wready,
    input logic [C_AXICFG_DATA_WIDTH/8-1:0]             s_axi4lite_wstrb,

    output logic [1:0]                                  s_axi4lite_bresp,
    output logic                                        s_axi4lite_bvalid,
    input logic                                         s_axi4lite_bready,

    input logic [31:0]                                  s_axi4lite_araddr,
    input logic                                         s_axi4lite_arvalid,
    output logic                                        s_axi4lite_arready,

    output logic [C_AXICFG_DATA_WIDTH-1:0]              s_axi4lite_rdata,
    output logic [1:0]                                  s_axi4lite_rresp,
    output logic                                        s_axi4lite_rvalid,
    input logic                                         s_axi4lite_rready,

    // Interrupt lines to handle misses, collisions of slices/multiple hits,
    // protection faults and overflow of the miss handling fifo
    output logic [N_PORTS-1:0]                          int_miss,
    output logic [N_PORTS-1:0]                          int_multi,
    output logic [N_PORTS-1:0]                          int_prot,
    output logic                                        int_mhr_full
    );

   // Internal AXI4 lines, these connect buffers on the slave side to the rab core and
   // multiplexers which switch between the two master outputs
   
   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_awid;
   logic [N_PORTS-1:0]                   [31:0] int_awaddr;
   logic [N_PORTS-1:0]			                  	int_awvalid;
   logic [N_PORTS-1:0]			                  	int_awready;
   logic [N_PORTS-1:0]       	            [7:0] int_awlen;
   logic [N_PORTS-1:0]                    [2:0] int_awsize;
   logic [N_PORTS-1:0]                    [1:0] int_awburst;
   logic [N_PORTS-1:0]		                      int_awlock;
   logic [N_PORTS-1:0]                    [2:0] int_awprot;
   logic [N_PORTS-1:0]                    [3:0] int_awcache;
   logic [N_PORTS-1:0]                    [3:0] int_awregion;
   logic [N_PORTS-1:0]                    [3:0] int_awqos;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_awuser;

   logic [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] int_wdata;
   logic [N_PORTS-1:0]	            	          int_wvalid;
   logic [N_PORTS-1:0]			                    int_wready;
   logic [N_PORTS-1:0] [C_AXI_DATA_WIDTH/8-1:0] int_wstrb;
   logic [N_PORTS-1:0]			                  	int_wlast;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_wuser;

   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_bid;
   logic [N_PORTS-1:0]                    [1:0] int_bresp;
   logic [N_PORTS-1:0]                          int_bvalid;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_buser;
   logic [N_PORTS-1:0]	                        int_bready;

   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_arid;
   logic [N_PORTS-1:0]                   [31:0] int_araddr;
   logic [N_PORTS-1:0]         		              int_arvalid;
   logic [N_PORTS-1:0]			                    int_arready;
   logic [N_PORTS-1:0]       	            [7:0] int_arlen;
   logic [N_PORTS-1:0]       	            [2:0] int_arsize;
   logic [N_PORTS-1:0]                    [1:0] int_arburst;
   logic [N_PORTS-1:0]		                      int_arlock;
   logic [N_PORTS-1:0]       	            [2:0] int_arprot;
   logic [N_PORTS-1:0]       	            [3:0] int_arcache;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_aruser;

   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_rid;
   logic [N_PORTS-1:0]                    [1:0] int_rresp;
   logic [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] int_rdata;
   logic [N_PORTS-1:0]                          int_rlast;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_ruser;
   logic [N_PORTS-1:0]                          int_rvalid;
   logic [N_PORTS-1:0]                          int_rready;

   // Internal master0 AXI4 lines. These connect the first master port to the
   // multiplexers
   // For channels read address, write address and write data the other lines
   // are ignored if valid is not set, therefore we only need to multiplex those
   
   logic [N_PORTS-1:0] 			                  	int_m0_awvalid;
   logic [N_PORTS-1:0] 			                  	int_m0_awready;

   logic [N_PORTS-1:0] 	            	          int_m0_wvalid;
   logic [N_PORTS-1:0] 			                    int_m0_wready;

   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_m0_bid;
   logic [N_PORTS-1:0]                    [1:0] int_m0_bresp;
   logic [N_PORTS-1:0]                          int_m0_bvalid;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_m0_buser;
   logic [N_PORTS-1:0] 	                        int_m0_bready;

   logic [N_PORTS-1:0]          		            int_m0_arvalid;
   logic [N_PORTS-1:0] 			                    int_m0_arready;
   
   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_m0_rid;
   logic [N_PORTS-1:0]                    [1:0] int_m0_rresp;
   logic [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] int_m0_rdata;
   logic [N_PORTS-1:0] 	                        int_m0_rlast;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_m0_ruser;
   logic [N_PORTS-1:0] 			                    int_m0_rready;
   logic [N_PORTS-1:0]                          int_m0_rvalid;

   // Internal master1 AXI4 lines. These connect the second master port to the
   // multiplexers
   // For channels read address, write address and write data the other lines
   // are ignored if valid is not set, therefore we only need to multiplex those

   logic [N_PORTS-1:0] 		                      int_m1_awvalid;
   logic [N_PORTS-1:0] 		                      int_m1_awready;

   logic [N_PORTS-1:0]             	            int_m1_wvalid;
   logic [N_PORTS-1:0] 		                      int_m1_wready;

   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_m1_bid;
   logic [N_PORTS-1:0]                    [1:0] int_m1_bresp;
   logic [N_PORTS-1:0]                          int_m1_bvalid;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_m1_buser;
   logic [N_PORTS-1:0]                          int_m1_bready;
   
   logic [N_PORTS-1:0]         		              int_m1_arvalid;
   logic [N_PORTS-1:0] 		                      int_m1_arready;
   
   logic [N_PORTS-1:0]     [C_AXI_ID_WIDTH-1:0] int_m1_rid;
   logic [N_PORTS-1:0]                    [1:0] int_m1_rresp;
   logic [N_PORTS-1:0]   [C_AXI_DATA_WIDTH-1:0] int_m1_rdata;
   logic [N_PORTS-1:0]                          int_m1_rlast;
   logic [N_PORTS-1:0]   [C_AXI_USER_WIDTH-1:0] int_m1_ruser;
   logic [N_PORTS-1:0]                          int_m1_rvalid;
   logic [N_PORTS-1:0] 		                      int_m1_rready;

   // rab_core output lines for the address write and data write channels
   // int_wtrans_drop is also used to control error responses of the write
   // response sender
   
   logic [N_PORTS-1:0]                   [31:0] int_wtrans_addr;
   logic [N_PORTS-1:0] 			                    int_wtrans_accept;
   logic [N_PORTS-1:0] 			                    int_wtrans_drop;
   logic [N_PORTS-1:0] 			                    int_wtrans_sent;
   logic [N_PORTS-1:0] 			                    int_wmaster_select;
   logic [N_PORTS-1:0]                          int_dwch_master_select; // for the current transaction on dw channel

   // rab_core output lines for the address read channel
   // int_wtrans_drop is also used to control error responses of the read
   // response sender
   
   logic [N_PORTS-1:0]                   [31:0] int_rtrans_addr;
   logic [N_PORTS-1:0] 			                    int_rtrans_accept;
   logic [N_PORTS-1:0] 			                    int_rtrans_drop;
   logic [N_PORTS-1:0] 			                    int_rtrans_sent;
   logic [N_PORTS-1:0] 			                    int_rmaster_select;
   
   // rab_output lines after multiplexers
   // address does not need to be multiplexed, as senders will ignore it, if
   // neither valid from the slave side nor accept is set

   logic [N_PORTS-1:0] 			                    int_m0_wtrans_accept;
   logic [N_PORTS-1:0] 			                    int_m0_wtrans_drop;
   logic [N_PORTS-1:0] 			                    int_m0_wtrans_sent;

   logic [N_PORTS-1:0] 			                    int_m0_rtrans_sent;
   logic [N_PORTS-1:0]                          int_m0_rtrans_accept;
   logic [N_PORTS-1:0] 			                    int_m0_rtrans_drop;

   logic [N_PORTS-1:0] 			                    int_m1_wtrans_accept;
   logic [N_PORTS-1:0] 			                    int_m1_wtrans_drop;
   logic [N_PORTS-1:0] 			                    int_m1_wtrans_sent;

   logic [N_PORTS-1:0] 			                    int_m1_rtrans_sent;
   logic [N_PORTS-1:0]                          int_m1_rtrans_accept;
   logic [N_PORTS-1:0] 			                    int_m1_rtrans_drop;

   // dw channel master_select fifo

   logic [N_PORTS-1:0]                          master_select_fifo_not_empty;
   logic [N_PORTS-1:0]                          master_select_fifo_not_full;
   logic [N_PORTS-1:0]                          master_select_fifo_out;
   logic [N_PORTS-1:0]                          w_new_rab_output;
                           
   
   genvar 					i;

generate for (i = 0; i < N_PORTS; i++) begin

/*
 * write address channel (aw)
 * 
 * ██╗    ██╗██████╗ ██╗████████╗███████╗     █████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗███████╗
 * ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
 * ██║ █╗ ██║██████╔╝██║   ██║   █████╗      ███████║██║  ██║██║  ██║██████╔╝█████╗  ███████╗███████╗
 * ██║███╗██║██╔══██╗██║   ██║   ██╔══╝      ██╔══██║██║  ██║██║  ██║██╔══██╗██╔══╝  ╚════██║╚════██║
 * ╚███╔███╔╝██║  ██║██║   ██║   ███████╗    ██║  ██║██████╔╝██████╔╝██║  ██║███████╗███████║███████║
 *  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝    ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
 * 
 * 
 */
   
  axi4_awch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_awinbuffer(
                            .axi4_aclk       (axi4_aclk      ),
                            .axi4_arstn      (axi4_arstn     ),
                            .s_axi4_awid     (s_axi4_awid [i]     ),
                            .s_axi4_awaddr   (s_axi4_awaddr [i]   ),
                            .s_axi4_awvalid  (s_axi4_awvalid [i]  ),
                            .s_axi4_awready  (s_axi4_awready [i]  ),
                            .s_axi4_awlen    (s_axi4_awlen [i]    ),
                            .s_axi4_awsize   (s_axi4_awsize [i]   ),
                            .s_axi4_awburst  (s_axi4_awburst [i]  ),
                            .s_axi4_awlock   (s_axi4_awlock [i]   ),
                            .s_axi4_awprot   (s_axi4_awprot [i]   ),
                            .s_axi4_awcache  (s_axi4_awcache [i]  ),
                            .s_axi4_awregion (s_axi4_awregion [i] ),
                            .s_axi4_awqos    (s_axi4_awqos [i]    ),
                            .s_axi4_awuser   (s_axi4_awuser [i]   ),
                            .m_axi4_awid     (int_awid [i]     ),
                            .m_axi4_awaddr   (int_awaddr [i]   ),
                            .m_axi4_awvalid  (int_awvalid [i]  ),
                            .m_axi4_awready  (int_awready [i]  ),
                            .m_axi4_awlen    (int_awlen [i]    ),
                            .m_axi4_awsize   (int_awsize [i]   ),
                            .m_axi4_awburst  (int_awburst [i]  ),
                            .m_axi4_awlock   (int_awlock [i]   ),
                            .m_axi4_awprot   (int_awprot [i]   ),
                            .m_axi4_awcache  (int_awcache [i]  ),
                            .m_axi4_awregion (int_awregion [i] ),
                            .m_axi4_awqos    (int_awqos [i]    ),
                            .m_axi4_awuser   (int_awuser [i]   ));

  axi4_awch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_awsender_m0(
			                      .axi4_aclk       (axi4_aclk   ),
                            .axi4_arstn      (axi4_arstn  ),
                            .trans_accept    (int_m0_wtrans_accept[i] ),
                            .trans_drop      (int_m0_wtrans_drop[i]   ),
                            .trans_sent      (int_m0_wtrans_sent[i]   ),
                            .s_axi4_awid     (int_awid[i]          ),
                            .s_axi4_awaddr   (int_wtrans_addr[i]   ), //gets the modified address
                            .s_axi4_awvalid  (int_m0_awvalid[i]       ),
                            .s_axi4_awready  (int_m0_awready[i]       ),
                            .s_axi4_awlen    (int_awlen[i]         ),
                            .s_axi4_awsize   (int_awsize[i]        ),
                            .s_axi4_awburst  (int_awburst[i]       ),
                            .s_axi4_awlock   (int_awlock[i]        ),
                            .s_axi4_awprot   (int_awprot[i]        ),
                            .s_axi4_awcache  (int_awcache[i]       ),
                            .s_axi4_awregion (int_awregion[i]      ),
                            .s_axi4_awqos    (int_awqos[i]         ),
                            .s_axi4_awuser   (int_awuser[i]        ),
                            .m_axi4_awid     (m0_axi4_awid[i]       ),
                            .m_axi4_awaddr   (m0_axi4_awaddr[i]     ),
                            .m_axi4_awvalid  (m0_axi4_awvalid[i]    ),
                            .m_axi4_awready  (m0_axi4_awready[i]    ),
                            .m_axi4_awlen    (m0_axi4_awlen[i]      ),
                            .m_axi4_awsize   (m0_axi4_awsize[i]     ),
                            .m_axi4_awburst  (m0_axi4_awburst[i]    ),
                            .m_axi4_awlock   (m0_axi4_awlock[i]     ),
                            .m_axi4_awprot   (m0_axi4_awprot[i]     ),
                            .m_axi4_awcache  (m0_axi4_awcache[i]    ),
                            .m_axi4_awregion (m0_axi4_awregion[i]   ),
                            .m_axi4_awqos    (m0_axi4_awqos[i]      ),
                            .m_axi4_awuser   (m0_axi4_awuser[i]     ));

  axi4_awch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_awsender_m1(
			                      .axi4_aclk       (axi4_aclk            ),
                            .axi4_arstn      (axi4_arstn           ),
                            .trans_accept    (int_m1_wtrans_accept[i]),
                            .trans_drop      (int_m1_wtrans_drop[i]  ),
                            .trans_sent      (int_m1_wtrans_sent[i]  ),
                            .s_axi4_awid     (int_awid[i]         ),
                            .s_axi4_awaddr   (int_wtrans_addr[i]  ), //gets the modified address
                            .s_axi4_awvalid  (int_m1_awvalid[i]      ),
                            .s_axi4_awready  (int_m1_awready[i]      ),
                            .s_axi4_awlen    (int_awlen[i]        ),
                            .s_axi4_awsize   (int_awsize[i]       ),
                            .s_axi4_awburst  (int_awburst[i]      ),
                            .s_axi4_awlock   (int_awlock[i]       ),
                            .s_axi4_awprot   (int_awprot[i]       ),
                            .s_axi4_awcache  (int_awcache[i]      ),
                            .s_axi4_awregion (int_awregion[i]     ),
                            .s_axi4_awqos    (int_awqos[i]        ),
                            .s_axi4_awuser   (int_awuser[i]       ),
                            .m_axi4_awid     (m1_axi4_awid[i]       ),
                            .m_axi4_awaddr   (m1_axi4_awaddr[i]     ),
                            .m_axi4_awvalid  (m1_axi4_awvalid[i]    ),
                            .m_axi4_awready  (m1_axi4_awready[i]    ),
                            .m_axi4_awlen    (m1_axi4_awlen[i]      ),
                            .m_axi4_awsize   (m1_axi4_awsize[i]     ),
                            .m_axi4_awburst  (m1_axi4_awburst[i]    ),
                            .m_axi4_awlock   (m1_axi4_awlock[i]     ),
                            .m_axi4_awprot   (m1_axi4_awprot[i]     ),
                            .m_axi4_awcache  (m1_axi4_awcache[i]    ),
                            .m_axi4_awregion (m1_axi4_awregion[i]   ),
                            .m_axi4_awqos    (m1_axi4_awqos[i]      ),
                            .m_axi4_awuser   (m1_axi4_awuser[i]     ));

/* 
 * Multiplexer to switch between the two output master ports on the write address(aw) channel
 */

  always_comb
    begin
       if(int_wmaster_select[i] == 1'b0)
         begin
            int_m0_wtrans_accept[i]  = int_wtrans_accept[i];
            int_m0_wtrans_drop[i]    = int_wtrans_drop[i];
            int_m0_awvalid[i]        = int_awvalid[i];

            int_m1_wtrans_accept[i]  = 1'b0;
            int_m1_wtrans_drop[i]    = 1'b0;
            int_m1_awvalid[i]        = 1'b0;
            
            int_wtrans_sent[i]       = int_m0_wtrans_sent[i];
            int_awready[i]           = int_m0_awready[i];
         end
       else
         begin
            int_m0_wtrans_accept[i]  = 1'b0;
            int_m0_wtrans_drop[i]    = 1'b0;
            int_m0_awvalid[i]        = 1'b0;
            
            int_m1_wtrans_accept[i]  = int_wtrans_accept[i];
            int_m1_wtrans_drop[i]    = int_wtrans_drop[i];
            int_m1_awvalid[i]        = int_awvalid[i];
            
            int_wtrans_sent[i]       = int_m1_wtrans_sent[i];
            int_awready[i]           = int_m1_awready[i];
         end
    end

/*
 * write data channel(dw)
 * 
 * ██╗    ██╗██████╗ ██╗████████╗███████╗    ██████╗  █████╗ ████████╗ █████╗ 
 * ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝    ██╔══██╗██╔══██╗╚══██╔══╝██╔══██╗
 * ██║ █╗ ██║██████╔╝██║   ██║   █████╗      ██║  ██║███████║   ██║   ███████║
 * ██║███╗██║██╔══██╗██║   ██║   ██╔══╝      ██║  ██║██╔══██║   ██║   ██╔══██║
 * ╚███╔███╔╝██║  ██║██║   ██║   ███████╗    ██████╔╝██║  ██║   ██║   ██║  ██║
 *  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝    ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝
 * 
 */                                                                           
   
  axi4_dwch_buffer #(C_AXI_DATA_WIDTH,C_AXI_USER_WIDTH) u_dwinbuffer(
                            .axi4_aclk     (axi4_aclk    ),
                            .axi4_arstn    (axi4_arstn   ),
                            .s_axi4_wdata  (s_axi4_wdata [i]  ),
                            .s_axi4_wvalid (s_axi4_wvalid [i] ),
                            .s_axi4_wready (s_axi4_wready [i] ),
                            .s_axi4_wstrb  (s_axi4_wstrb [i]  ),
                            .s_axi4_wlast  (s_axi4_wlast [i]  ),
                            .s_axi4_wuser  (s_axi4_wuser [i]  ),
                            .m_axi4_wdata  (int_wdata [i]     ),
                            .m_axi4_wvalid (int_wvalid [i]    ),
                            .m_axi4_wready (int_wready [i]    ),
                            .m_axi4_wstrb  (int_wstrb [i]     ),
                            .m_axi4_wlast  (int_wlast [i]     ),
                            .m_axi4_wuser  (int_wuser [i]     ));

  axi4_dwch_sender #(C_AXI_DATA_WIDTH,C_AXI_USER_WIDTH) u_dwsender_m0(
                            .axi4_aclk     (axi4_aclk            ),
                            .axi4_arstn    (axi4_arstn           ),
                            .trans_accept  (int_m0_wtrans_accept[i] ),
                            .trans_drop    (int_m0_wtrans_drop[i]   ),
                            .s_axi4_wdata  (int_wdata[i]         ),
                            .s_axi4_wvalid (int_m0_wvalid[i]        ),
                            .s_axi4_wready (int_m0_wready[i]        ),
                            .s_axi4_wstrb  (int_wstrb[i]         ),
                            .s_axi4_wlast  (int_wlast[i]         ),
                            .s_axi4_wuser  (int_wuser[i]         ),
                            .m_axi4_wdata  (m0_axi4_wdata[i]      ),
                            .m_axi4_wvalid (m0_axi4_wvalid[i]     ),
                            .m_axi4_wready (m0_axi4_wready[i]     ),
                            .m_axi4_wstrb  (m0_axi4_wstrb[i]      ),
                            .m_axi4_wlast  (m0_axi4_wlast[i]      ),
                            .m_axi4_wuser  (m0_axi4_wuser[i]      ));

  axi4_dwch_sender #(C_AXI_DATA_WIDTH,C_AXI_USER_WIDTH) u_dwsender_m1(
                            .axi4_aclk     (axi4_aclk            ),
                            .axi4_arstn    (axi4_arstn           ),
                            .trans_accept  (int_m1_wtrans_accept[i] ),
                            .trans_drop    (int_m1_wtrans_drop[i]   ),
                            .s_axi4_wdata  (int_wdata[i]         ),
                            .s_axi4_wvalid (int_m1_wvalid[i]        ),
                            .s_axi4_wready (int_m1_wready[i]        ),
                            .s_axi4_wstrb  (int_wstrb[i]         ),
                            .s_axi4_wlast  (int_wlast[i]         ),
                            .s_axi4_wuser  (int_wuser[i]         ),
                            .m_axi4_wdata  (m1_axi4_wdata[i]      ),
                            .m_axi4_wvalid (m1_axi4_wvalid[i]     ),
                            .m_axi4_wready (m1_axi4_wready[i]     ),
                            .m_axi4_wstrb  (m1_axi4_wstrb[i]      ),
                            .m_axi4_wlast  (m1_axi4_wlast[i]      ),
                            .m_axi4_wuser  (m1_axi4_wuser[i]      ));

/*
 * To be able to switch between the two master ports for write data, we need to
 * store the master_select flags of the last write addresses in a FIFO, as
 * multiple data write requests might have been startet and the data can be
 * interleaved with the addresses. However the data has the same order as the
 * addresses. The FIFO is triggered by accept/drop from the rab_core on push
 * and by wlast for pop(data transaction finished)
 */


  axi_buffer_rab #(.DATA_WIDTH(1)) u_master_select_fifo
    (
     .clk(axi4_aclk),
     .rstn(axi4_arstn),
     .data_out(master_select_fifo_out[i]),
     .valid_out(master_select_fifo_not_empty[i]),
     .ready_out(master_select_fifo_not_full[i]),
     .data_in(int_wmaster_select[i]),
     .valid_in(w_new_rab_output[i]),
     .ready_in(int_wlast[i])
     );

  assign w_new_rab_output[i] = int_wtrans_accept[i] | int_wtrans_drop[i]; 
  assign int_dwch_master_select[i] = master_select_fifo_not_empty[i] & master_select_fifo_out[i];

/* 
 * Multiplexer to switch between the two output master ports on the write address(aw) channel
 */

   always_comb
     begin
        if(int_dwch_master_select[i] == 1'b0)
          begin
             int_m0_wvalid[i] = int_wvalid[i];
             int_m1_wvalid[i] = 1'b0;

             int_wready[i]    = int_m0_wready[i];
          end
        else
          begin
             int_m0_wvalid[i] = 1'b0;
             int_m1_wvalid[i] = int_wvalid[i];

             int_wready[i]    = int_m1_wvalid[i];
          end
     end // always_comb

/*
 * write response channel(rw)
 * 
 * ██╗    ██╗██████╗ ██╗████████╗███████╗    ██████╗ ███████╗███████╗██████╗  ██████╗ ███╗   ██╗███████╗███████╗
 * ██║    ██║██╔══██╗██║╚══██╔══╝██╔════╝    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗████╗  ██║██╔════╝██╔════╝
 * ██║ █╗ ██║██████╔╝██║   ██║   █████╗      ██████╔╝█████╗  ███████╗██████╔╝██║   ██║██╔██╗ ██║███████╗█████╗  
 * ██║███╗██║██╔══██╗██║   ██║   ██╔══╝      ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║██╔══╝  
 * ╚███╔███╔╝██║  ██║██║   ██║   ███████╗    ██║  ██║███████╗███████║██║     ╚██████╔╝██║ ╚████║███████║███████╗
 *  ╚══╝╚══╝ ╚═╝  ╚═╝╚═╝   ╚═╝   ╚══════╝    ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝
 *                                                                                                              
 */
   
  axi4_rwch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rwchbuffer_m0(
                            .axi4_aclk      (axi4_aclk          ),
                            .axi4_arstn     (axi4_arstn         ),
                            .s_axi4_bid     (int_m0_bid [i]     ),
                            .s_axi4_bresp   (int_m0_bresp [i]   ),
                            .s_axi4_bvalid  (int_m0_bvalid [i]  ),
                            .s_axi4_buser   (int_m0_buser [i]   ),
                            .s_axi4_bready  (int_m0_bready [i]  ),
                            .m_axi4_bid     (m0_axi4_bid [i]    ),
                            .m_axi4_bresp   (m0_axi4_bresp [i]  ),
                            .m_axi4_bvalid  (m0_axi4_bvalid [i] ),
                            .m_axi4_buser   (m0_axi4_buser [i]  ),
                            .m_axi4_bready  (m0_axi4_bready [i] ));

   axi4_rwch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rwchbuffer_m1(
                            .axi4_aclk      (axi4_aclk            ),
                            .axi4_arstn     (axi4_arstn           ),
                            .s_axi4_bid     (int_m1_bid [i]       ),
                            .s_axi4_bresp   (int_m1_bresp [i]     ),
                            .s_axi4_bvalid  (int_m1_bvalid [i]    ),
                            .s_axi4_buser   (int_m1_buser [i]     ),
                            .s_axi4_bready  (int_m1_bready [i]    ),
                            .m_axi4_bid     (m1_axi4_bid [i]      ),
                            .m_axi4_bresp   (m1_axi4_bresp [i]    ),
                            .m_axi4_bvalid  (m1_axi4_bvalid [i]   ),
                            .m_axi4_buser   (m1_axi4_buser [i]    ),
                            .m_axi4_bready  (m1_axi4_bready [i]   ));

  axi4_rwch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rwchsender(
                            .axi4_aclk     (axi4_aclk          ),
                            .axi4_arstn    (axi4_arstn         ),
                            .trans_id      (int_awid[i]        ),
                            .trans_drop    (int_wtrans_drop[i] ),
                            .s_axi4_wvalid (int_wvalid[i]      ),
                            .s_axi4_wlast  (int_wlast[i]       ),
                            .s_axi4_wready (int_wready[i]      ),
                            .s_axi4_bid    (s_axi4_bid[i]      ),
                            .s_axi4_bresp  (s_axi4_bresp[i]    ),
                            .s_axi4_bvalid (s_axi4_bvalid[i]   ),
                            .s_axi4_buser  (s_axi4_buser[i]    ),
                            .s_axi4_bready (s_axi4_bready[i]   ),
                            .m_axi4_bid    (int_bid[i]         ),
                            .m_axi4_bresp  (int_bresp[i]       ),
                            .m_axi4_bvalid (int_bvalid[i]      ),
                            .m_axi4_buser  (int_buser[i]       ),
                            .m_axi4_bready (int_bready[i]      ));
/* 
 * Multiplexer to switch between the two output master ports on the write response(rw) channel
 */
   
  always_comb
    begin
       /* Output 1 always gets priority, so if it has something to send connect
        it and let output 0 wait using rready = 0 */
      if (int_m1_bvalid[i] == 1'b1)
        begin
           int_m0_bready[i] = 1'b0;
           int_m1_bready[i] = int_bready[i];

           int_bid[i]    = int_m1_bid[i];
           int_bresp[i]  = int_m1_bresp[i];
           int_buser[i]  = int_m1_buser[i];
           int_bvalid[i] = int_m1_bvalid[i];
        end
      else
        begin
           int_m0_bready[i] = int_bready[i];
           int_m1_bready[i] = 1'b0;

           int_bid[i]    = int_m0_bid[i];
           int_bresp[i]  = int_m0_bresp[i];
           int_buser[i]  = int_m0_buser[i];
           int_bvalid[i] = int_m0_bvalid[i];
        end
    end

/*
 * read address channel (ar)
 *
 * ██████╗ ███████╗ █████╗ ██████╗      █████╗ ██████╗ ██████╗ ██████╗ ███████╗███████╗███████╗
 * ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔══██╗██╔══██╗██╔══██╗██╔══██╗██╔════╝██╔════╝██╔════╝
 * ██████╔╝█████╗  ███████║██║  ██║    ███████║██║  ██║██║  ██║██████╔╝█████╗  ███████╗███████╗
 * ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══██║██║  ██║██║  ██║██╔══██╗██╔══╝  ╚════██║╚════██║
 * ██║  ██║███████╗██║  ██║██████╔╝    ██║  ██║██████╔╝██████╔╝██║  ██║███████╗███████║███████║
 * ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═╝╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝╚══════╝╚══════╝
 * 
 */

   
  axi4_arch_buffer #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_arinbuffer(
                            .axi4_aclk       (axi4_aclk      ),
                            .axi4_arstn      (axi4_arstn     ),
                            .s_axi4_arid     (s_axi4_arid [i]     ),
                            .s_axi4_araddr   (s_axi4_araddr [i]   ),
                            .s_axi4_arvalid  (s_axi4_arvalid [i]  ),
                            .s_axi4_arready  (s_axi4_arready [i]  ),
                            .s_axi4_arlen    (s_axi4_arlen [i]    ),
                            .s_axi4_arsize   (s_axi4_arsize [i]   ),
                            .s_axi4_arburst  (s_axi4_arburst [i]  ),
                            .s_axi4_arlock   (s_axi4_arlock [i]   ),
                            .s_axi4_arprot   (s_axi4_arprot [i]   ),
                            .s_axi4_arcache  (s_axi4_arcache [i]  ),
                            .s_axi4_aruser   (s_axi4_aruser [i]   ),
                            .m_axi4_arid     (int_arid [i]       ),
                            .m_axi4_araddr   (int_araddr [i]     ),
                            .m_axi4_arvalid  (int_arvalid [i]    ),
                            .m_axi4_arready  (int_arready [i]    ),
                            .m_axi4_arlen    (int_arlen [i]      ),
                            .m_axi4_arsize   (int_arsize [i]     ),
                            .m_axi4_arburst  (int_arburst [i]    ),
                            .m_axi4_arlock   (int_arlock [i]     ),
                            .m_axi4_arprot   (int_arprot [i]     ),
                            .m_axi4_arcache  (int_arcache [i]    ),
                            .m_axi4_aruser   (int_aruser [i]     ));

  axi4_arch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_arsender_m0(
			                      .axi4_aclk      (axi4_aclk      ),
                            .axi4_arstn     (axi4_arstn     ),
                            .trans_accept   (int_m0_rtrans_accept[i] ),
                            .trans_drop     (int_m0_rtrans_drop[i]   ),
                            .trans_sent     (int_m0_rtrans_sent[i]   ),
                            .s_axi4_arid    (int_arid[i]          ),
                            .s_axi4_araddr  (int_rtrans_addr[i]   ), //gets the modified address
                            .s_axi4_arvalid (int_m0_arvalid[i]       ),
                            .s_axi4_arready (int_m0_arready[i]       ),
                            .s_axi4_arlen   (int_arlen[i]         ),
                            .s_axi4_arsize  (int_arsize[i]        ),
                            .s_axi4_arburst (int_arburst[i]       ),
                            .s_axi4_arlock  (int_arlock[i]        ),
                            .s_axi4_arprot  (int_arprot[i]        ),
                            .s_axi4_arcache (int_arcache[i]       ),
                            .s_axi4_aruser  (int_aruser[i]        ),
                            .m_axi4_arid    (m0_axi4_arid[i]       ),
                            .m_axi4_araddr  (m0_axi4_araddr[i]     ),
                            .m_axi4_arvalid (m0_axi4_arvalid[i]    ),
                            .m_axi4_arready (m0_axi4_arready[i]    ),
                            .m_axi4_arlen   (m0_axi4_arlen[i]      ),
                            .m_axi4_arsize  (m0_axi4_arsize[i]     ),
                            .m_axi4_arburst (m0_axi4_arburst[i]    ),
                            .m_axi4_arlock  (m0_axi4_arlock[i]     ),
                            .m_axi4_arprot  (m0_axi4_arprot[i]     ),
                            .m_axi4_arcache (m0_axi4_arcache[i]    ),
                            .m_axi4_aruser  (m0_axi4_aruser[i]     ));

 axi4_arch_sender #(C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_arsender_m1(
			                      .axi4_aclk      (axi4_aclk            ),
                            .axi4_arstn     (axi4_arstn           ),
                            .trans_accept   (int_m1_rtrans_accept[i]),
                            .trans_drop     (int_m1_rtrans_drop[i]  ),
                            .trans_sent     (int_m1_rtrans_sent[i]  ),
                            .s_axi4_arid    (int_arid[i]         ),
                            .s_axi4_araddr  (int_rtrans_addr[i]  ), //gets the modified address
                            .s_axi4_arvalid (int_m1_arvalid[i]      ),
                            .s_axi4_arready (int_m1_arready[i]      ),
                            .s_axi4_arlen   (int_arlen[i]        ),
                            .s_axi4_arsize  (int_arsize[i]       ),
                            .s_axi4_arburst (int_arburst[i]      ),
                            .s_axi4_arlock  (int_arlock[i]       ),
                            .s_axi4_arprot  (int_arprot[i]       ),
                            .s_axi4_arcache (int_arcache[i]      ),
                            .s_axi4_aruser  (int_aruser[i]       ),
                            .m_axi4_arid    (m1_axi4_arid[i]       ),
                            .m_axi4_araddr  (m1_axi4_araddr[i]     ),
                            .m_axi4_arvalid (m1_axi4_arvalid[i]    ),
                            .m_axi4_arready (m1_axi4_arready[i]    ),
                            .m_axi4_arlen   (m1_axi4_arlen[i]      ),
                            .m_axi4_arsize  (m1_axi4_arsize[i]     ),
                            .m_axi4_arburst (m1_axi4_arburst[i]    ),
                            .m_axi4_arlock  (m1_axi4_arlock[i]     ),
                            .m_axi4_arprot  (m1_axi4_arprot[i]     ),
                            .m_axi4_arcache (m1_axi4_arcache[i]    ),
                            .m_axi4_aruser  (m1_axi4_aruser[i]     ));
/* 
 * Multiplexer to switch between the two output master ports on the read address(ar) channel
 */

  always_comb
    begin
       if(int_rmaster_select[i] == 1'b0)
         begin
            int_m0_rtrans_accept[i]  = int_rtrans_accept[i];
            int_m0_rtrans_drop[i]    = int_rtrans_drop[i];
            int_m0_arvalid[i]        = int_arvalid[i];

            int_m1_rtrans_accept[i]  = 1'b0;
            int_m1_rtrans_drop[i]    = 1'b0;
            int_m1_arvalid[i]        = 1'b0;
            
            int_rtrans_sent[i]       = int_m0_rtrans_sent[i];
            int_arready[i]           = int_m0_arready[i];
         end
       else
         begin
            int_m0_rtrans_accept[i]  = 1'b0;
            int_m0_rtrans_drop[i]    = 1'b0;
            int_m0_arvalid[i]        = 1'b0;
            
            int_m1_rtrans_accept[i]  = int_rtrans_accept[i];
            int_m1_rtrans_drop[i]    = int_rtrans_drop[i];
            int_m1_arvalid[i] = int_arvalid[i];
            
            int_rtrans_sent[i]       = int_m1_rtrans_sent[i];
            int_arready[i]           = int_m1_arready[i];
         end
    end

/*
 * read response channel (rr)
 *
 * ██████╗ ███████╗ █████╗ ██████╗     ██████╗ ███████╗███████╗██████╗  ██████╗ ███╗   ██╗███████╗███████╗
 * ██╔══██╗██╔════╝██╔══██╗██╔══██╗    ██╔══██╗██╔════╝██╔════╝██╔══██╗██╔═══██╗████╗  ██║██╔════╝██╔════╝
 * ██████╔╝█████╗  ███████║██║  ██║    ██████╔╝█████╗  ███████╗██████╔╝██║   ██║██╔██╗ ██║███████╗█████╗  
 * ██╔══██╗██╔══╝  ██╔══██║██║  ██║    ██╔══██╗██╔══╝  ╚════██║██╔═══╝ ██║   ██║██║╚██╗██║╚════██║██╔══╝  
 * ██║  ██║███████╗██║  ██║██████╔╝    ██║  ██║███████╗███████║██║     ╚██████╔╝██║ ╚████║███████║███████╗
 * ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚═════╝     ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝      ╚═════╝ ╚═╝  ╚═══╝╚══════╝╚══════╝
 * 
 */
 
  axi4_rrch_buffer #(C_AXI_DATA_WIDTH,C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rrchbuffer_m0(
                            .axi4_aclk     (axi4_aclk        ),
                            .axi4_arstn    (axi4_arstn       ),
                            .s_axi4_rid    (int_m0_rid[i]    ),
                            .s_axi4_rresp  (int_m0_rresp[i]  ),
                            .s_axi4_rdata  (int_m0_rdata[i]  ),
                            .s_axi4_rlast  (int_m0_rlast[i]  ),
                            .s_axi4_rvalid (int_m0_rvalid[i] ),
                            .s_axi4_ruser  (int_m0_ruser[i]  ),
                            .s_axi4_rready (int_m0_rready[i] ),
                            .m_axi4_rid    (m0_axi4_rid[i]    ),
                            .m_axi4_rresp  (m0_axi4_rresp[i]  ),
                            .m_axi4_rdata  (m0_axi4_rdata[i]  ),
                            .m_axi4_rlast  (m0_axi4_rlast[i]  ),
                            .m_axi4_rvalid (m0_axi4_rvalid[i] ),
                            .m_axi4_ruser  (m0_axi4_ruser[i]  ),
                            .m_axi4_rready (m0_axi4_rready[i] ));
   
  axi4_rrch_buffer #(C_AXI_DATA_WIDTH,C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rrchbuffer_m1(
                            .axi4_aclk     (axi4_aclk        ),
                            .axi4_arstn    (axi4_arstn       ),
                            .s_axi4_rid    (int_m1_rid[i]       ),
                            .s_axi4_rresp  (int_m1_rresp[i]     ),
                            .s_axi4_rdata  (int_m1_rdata[i]     ),
                            .s_axi4_rlast  (int_m1_rlast[i]     ),
                            .s_axi4_rvalid (int_m1_rvalid[i]    ),
                            .s_axi4_ruser  (int_m1_ruser[i]     ),
                            .s_axi4_rready (int_m1_rready[i]    ),
                            .m_axi4_rid    (m1_axi4_rid[i]    ),
                            .m_axi4_rresp  (m1_axi4_rresp[i]  ),
                            .m_axi4_rdata  (m1_axi4_rdata[i]  ),
                            .m_axi4_rlast  (m1_axi4_rlast[i]  ),
                            .m_axi4_rvalid (m1_axi4_rvalid[i] ),
                            .m_axi4_ruser  (m1_axi4_ruser[i]  ),
                            .m_axi4_rready (m1_axi4_rready[i] ));
   
  axi4_rrch_sender #(C_AXI_DATA_WIDTH,C_AXI_ID_WIDTH,C_AXI_USER_WIDTH) u_rrchsender(
                            .axi4_aclk      (axi4_aclk         ),
                            .axi4_arstn     (axi4_arstn        ),
                            .trans_id       (int_arid[i]       ),  // These two are used to send error responses when
                            .trans_drop     (int_rtrans_drop[i]),  // lookup in the rab fails
                            .s_axi4_rid     (s_axi4_rid[i]     ),
                            .s_axi4_rresp   (s_axi4_rresp[i]   ),
                            .s_axi4_rdata   (s_axi4_rdata[i]   ),
                            .s_axi4_rlast   (s_axi4_rlast[i]   ),
                            .s_axi4_rvalid  (s_axi4_rvalid[i]  ),
                            .s_axi4_ruser   (s_axi4_ruser[i]   ),
                            .s_axi4_rready  (s_axi4_rready[i]  ),
                            .m_axi4_rid     (int_rid[i]        ),
                            .m_axi4_rresp   (int_rresp[i]      ),
                            .m_axi4_rdata   (int_rdata[i]      ),
                            .m_axi4_rlast   (int_rlast[i]      ),
                            .m_axi4_rvalid  (int_rvalid[i]     ),
                            .m_axi4_ruser   (int_ruser[i]      ),
                            .m_axi4_rready  (int_rready[i]     ));
   
/* 
 * Multiplexer to switch between the two output master ports on the read response(rr) channel
 */
   
  always_comb
    begin
       /* Output 1 always gets priority, so if it has something to send connect
        it and let output 0 wait using rready = 0 */
      if (int_m1_rvalid[i] == 1'b1)
        begin
           int_m0_rready[i] = 1'b0;
           int_m1_rready[i] = int_rready[i];

           int_rid[i]    = int_m1_rid[i];
           int_rresp[i]  = int_m1_rresp[i];
           int_rdata[i]  = int_m1_rdata[i];
           int_rlast[i]  = int_m1_rlast[i];
           int_ruser[i]  = int_m1_ruser[i];
           int_rvalid[i] = int_m1_rvalid[i];
        end
      else
        begin
           int_m0_rready[i] = int_rready[i];
           int_m1_rready[i] = 1'b0;

           int_rid[i]    = int_m0_rid[i];
           int_rresp[i]  = int_m0_rresp[i];
           int_rdata[i]  = int_m0_rdata[i];
           int_rlast[i]  = int_m0_rlast[i];
           int_ruser[i]  = int_m0_ruser[i];
           int_rvalid[i] = int_m0_rvalid[i];
        end
    end

    end
endgenerate

/*
 *
 * rab_core
 * 
 * The rab core translates addresses. It has two ports, which can be used
 * independently, however they will compete for time internally, as lookups
 * are serialized.
 * 
 * type is the read(0) or write(1) used to check the protection flags. If they
 * don't match an interrupt is created on the int_prot line.
 * 
 * 
 * 
 */
   
   rab_core
     #(
       .RAB_ENTRIES        (NUM_SLICES),
       .C_AXI_DATA_WIDTH   (C_AXI_DATA_WIDTH),
       .C_AXICFG_DATA_WIDTH(C_AXICFG_DATA_WIDTH),
       .C_AXI_ID_WIDTH     (C_AXI_ID_WIDTH),
       .C_AXI_USER_WIDTH   (C_AXI_USER_WIDTH), 
       .N_PORTS            (N_PORTS)
       ) 
   u_rab_core
     (
		  .s_axi_aclk   (axi4lite_aclk),
		  .s_axi_aresetn(axi4lite_arstn),
		  .s_axi_awaddr (s_axi4lite_awaddr),
		  .s_axi_awvalid(s_axi4lite_awvalid),
		  .s_axi_awready(s_axi4lite_awready),
		  .s_axi_wdata  (s_axi4lite_wdata),
		  .s_axi_wstrb  (s_axi4lite_wstrb),
		  .s_axi_wvalid (s_axi4lite_wvalid),
		  .s_axi_wready (s_axi4lite_wready),
		  .s_axi_bresp  (s_axi4lite_bresp),
		  .s_axi_bvalid (s_axi4lite_bvalid),
		  .s_axi_bready (s_axi4lite_bready),
		  .s_axi_araddr (s_axi4lite_araddr),
		  .s_axi_arvalid(s_axi4lite_arvalid),
		  .s_axi_arready(s_axi4lite_arready),
		  .s_axi_rready (s_axi4lite_rready),
		  .s_axi_rdata  (s_axi4lite_rdata),
		  .s_axi_rresp  (s_axi4lite_rresp),
		  .s_axi_rvalid (s_axi4lite_rvalid),
		  .int_miss    (int_miss),
		  .int_multi   (int_multi),
		  .int_prot    (int_prot),
		  .int_mhr_full(int_mhr_full),
		  .port1_addr         (int_awaddr),
		  .port1_id           (int_awid), 
		  .port1_len          (int_awlen),
		  .port1_size         (int_awsize),
		  .port1_addr_valid   (int_awvalid),
		  .port1_type         ('1),
      .port1_ctrl         (int_awuser),
		  .port1_sent         (int_wtrans_sent),
		  .port1_out_addr     (int_wtrans_addr),
      .port1_master_select(int_wmaster_select),
		  .port1_accept       (int_wtrans_accept),
		  .port1_drop         (int_wtrans_drop),
		  .port2_addr         (int_araddr),
		  .port2_id           (int_arid),
		  .port2_len          (int_arlen),
		  .port2_size         (int_arsize),
		  .port2_addr_valid   (int_arvalid),
		  .port2_type         ('0),
      .port2_ctrl         (int_aruser),
		  .port2_sent         (int_rtrans_sent),
		  .port2_out_addr     (int_rtrans_addr),
      .port2_master_select(int_rmaster_select),
		  .port2_accept       (int_rtrans_accept),
		  .port2_drop         (int_rtrans_drop)
      );

endmodule


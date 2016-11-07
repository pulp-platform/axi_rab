// --=========================================================================--
//
//  █████╗ ██╗  ██╗██╗    ██████╗  █████╗ ██████╗     ████████╗ ██████╗ ██████╗ 
// ██╔══██╗╚██╗██╔╝██║    ██╔══██╗██╔══██╗██╔══██╗    ╚══██╔══╝██╔═══██╗██╔══██╗
// ███████║ ╚███╔╝ ██║    ██████╔╝███████║██████╔╝       ██║   ██║   ██║██████╔╝
// ██╔══██║ ██╔██╗ ██║    ██╔══██╗██╔══██║██╔══██╗       ██║   ██║   ██║██╔═══╝ 
// ██║  ██║██╔╝ ██╗██║    ██║  ██║██║  ██║██████╔╝       ██║   ╚██████╔╝██║     
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝        ╚═╝    ╚═════╝ ╚═╝     
// 
// --=========================================================================-- 
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
 * described in axi4_XX_buffer.
 * 
 * The rab lookup result is merged into the axi transaction via the
 * axi4_XX_sender instances, which manage inserting error responses
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
 * v 3.0 Added level-2(L2) TLB.
 *       (Maheshwara Sharma  msharma@student.ethz.ch)
 * 
 */

`include "ulpsoc_defines.sv"
`include "BramPort.sv"
`include "log2.sv"

module axi_rab_top   

  // Parameters {{{
  #(
    parameter N_PORTS             = 2,
    parameter AXI_DATA_WIDTH      = 64,
    parameter AXI_S_ADDR_WIDTH    = 32,
    parameter AXI_M_ADDR_WIDTH    = 40,
    parameter AXI_LITE_DATA_WIDTH = 64,
    parameter AXI_LITE_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH        = 10,
    parameter AXI_USER_WIDTH      = 6
  )
  // }}}

  // Ports {{{
  (

    input logic                                            Clk_CI,
    input logic                                            ClusterClk_CI,
    input logic                                            Rst_RBI,

    // For every slave port there are two master ports. The master
    // port to use can be set using the master_select flag of the protection
    // bits of a slice
    
    // AXI4 Slave {{{
    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] s_axi4_awid,
    input  logic    [N_PORTS-1:0]   [AXI_S_ADDR_WIDTH-1:0] s_axi4_awaddr,
    input  logic    [N_PORTS-1:0]                          s_axi4_awvalid,
    output logic    [N_PORTS-1:0]                          s_axi4_awready,
    input  logic    [N_PORTS-1:0]                    [7:0] s_axi4_awlen,
    input  logic    [N_PORTS-1:0]                    [2:0] s_axi4_awsize,
    input  logic    [N_PORTS-1:0]                    [1:0] s_axi4_awburst,
    input  logic    [N_PORTS-1:0]                          s_axi4_awlock,
    input  logic    [N_PORTS-1:0]                    [2:0] s_axi4_awprot,
    input  logic    [N_PORTS-1:0]                    [3:0] s_axi4_awcache,
    input  logic    [N_PORTS-1:0]                    [3:0] s_axi4_awregion,
    input  logic    [N_PORTS-1:0]                    [3:0] s_axi4_awqos,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] s_axi4_awuser,

    input  logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] s_axi4_wdata,
    input  logic    [N_PORTS-1:0]                          s_axi4_wvalid,
    output logic    [N_PORTS-1:0]                          s_axi4_wready,
    input  logic    [N_PORTS-1:0]   [AXI_DATA_WIDTH/8-1:0] s_axi4_wstrb,
    input  logic    [N_PORTS-1:0]                          s_axi4_wlast,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] s_axi4_wuser,

    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] s_axi4_bid,
    output logic    [N_PORTS-1:0]                    [1:0] s_axi4_bresp,
    output logic    [N_PORTS-1:0]                          s_axi4_bvalid,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] s_axi4_buser,
    input  logic    [N_PORTS-1:0]                          s_axi4_bready,

    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] s_axi4_arid,
    input  logic    [N_PORTS-1:0]   [AXI_S_ADDR_WIDTH-1:0] s_axi4_araddr,
    input  logic    [N_PORTS-1:0]                          s_axi4_arvalid,
    output logic    [N_PORTS-1:0]                          s_axi4_arready,
    input  logic    [N_PORTS-1:0]                    [7:0] s_axi4_arlen,
    input  logic    [N_PORTS-1:0]                    [2:0] s_axi4_arsize,
    input  logic    [N_PORTS-1:0]                    [1:0] s_axi4_arburst,
    input  logic    [N_PORTS-1:0]                          s_axi4_arlock,
    input  logic    [N_PORTS-1:0]                    [2:0] s_axi4_arprot,
    input  logic    [N_PORTS-1:0]                    [3:0] s_axi4_arcache,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] s_axi4_aruser,

    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] s_axi4_rid,
    output logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] s_axi4_rdata,
    output logic    [N_PORTS-1:0]                    [1:0] s_axi4_rresp,
    output logic    [N_PORTS-1:0]                          s_axi4_rvalid,
    input  logic    [N_PORTS-1:0]                          s_axi4_rready,
    output logic    [N_PORTS-1:0]                          s_axi4_rlast,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] s_axi4_ruser,
    // }}}

    // AXI4 Master 0 {{{
    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m0_axi4_awid,
    output logic    [N_PORTS-1:0]   [AXI_M_ADDR_WIDTH-1:0] m0_axi4_awaddr,
    output logic    [N_PORTS-1:0]                          m0_axi4_awvalid,
    input  logic    [N_PORTS-1:0]                          m0_axi4_awready,
    output logic    [N_PORTS-1:0]                    [7:0] m0_axi4_awlen,
    output logic    [N_PORTS-1:0]                    [2:0] m0_axi4_awsize,
    output logic    [N_PORTS-1:0]                    [1:0] m0_axi4_awburst,
    output logic    [N_PORTS-1:0]                          m0_axi4_awlock,
    output logic    [N_PORTS-1:0]                    [2:0] m0_axi4_awprot,
    output logic    [N_PORTS-1:0]                    [3:0] m0_axi4_awcache,
    output logic    [N_PORTS-1:0]                    [3:0] m0_axi4_awregion,
    output logic    [N_PORTS-1:0]                    [3:0] m0_axi4_awqos,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m0_axi4_awuser,
    
    output logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] m0_axi4_wdata,
    output logic    [N_PORTS-1:0]                          m0_axi4_wvalid,
    input  logic    [N_PORTS-1:0]                          m0_axi4_wready,
    output logic    [N_PORTS-1:0]   [AXI_DATA_WIDTH/8-1:0] m0_axi4_wstrb,
    output logic    [N_PORTS-1:0]                          m0_axi4_wlast,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m0_axi4_wuser,

    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m0_axi4_bid,
    input  logic    [N_PORTS-1:0]                    [1:0] m0_axi4_bresp,
    input  logic    [N_PORTS-1:0]                          m0_axi4_bvalid,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m0_axi4_buser,
    output logic    [N_PORTS-1:0]                          m0_axi4_bready,

    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m0_axi4_arid,
    output logic    [N_PORTS-1:0]   [AXI_M_ADDR_WIDTH-1:0] m0_axi4_araddr,
    output logic    [N_PORTS-1:0]                          m0_axi4_arvalid,
    input  logic    [N_PORTS-1:0]                          m0_axi4_arready,
    output logic    [N_PORTS-1:0]                    [7:0] m0_axi4_arlen,
    output logic    [N_PORTS-1:0]                    [2:0] m0_axi4_arsize,
    output logic    [N_PORTS-1:0]                    [1:0] m0_axi4_arburst,
    output logic    [N_PORTS-1:0]                          m0_axi4_arlock,
    output logic    [N_PORTS-1:0]                    [2:0] m0_axi4_arprot,
    output logic    [N_PORTS-1:0]                    [3:0] m0_axi4_arcache,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m0_axi4_aruser,

    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m0_axi4_rid,
    input  logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] m0_axi4_rdata,
    input  logic    [N_PORTS-1:0]                    [1:0] m0_axi4_rresp,
    input  logic    [N_PORTS-1:0]                          m0_axi4_rvalid,
    output logic    [N_PORTS-1:0]                          m0_axi4_rready,
    input  logic    [N_PORTS-1:0]                          m0_axi4_rlast,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m0_axi4_ruser,
    // }}}

    // AXI4 Master 1 {{{
    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m1_axi4_awid,
    output logic    [N_PORTS-1:0]   [AXI_M_ADDR_WIDTH-1:0] m1_axi4_awaddr,
    output logic    [N_PORTS-1:0]                          m1_axi4_awvalid,
    input  logic    [N_PORTS-1:0]                          m1_axi4_awready,
    output logic    [N_PORTS-1:0]                    [7:0] m1_axi4_awlen,
    output logic    [N_PORTS-1:0]                    [2:0] m1_axi4_awsize,
    output logic    [N_PORTS-1:0]                    [1:0] m1_axi4_awburst,
    output logic    [N_PORTS-1:0]                          m1_axi4_awlock,
    output logic    [N_PORTS-1:0]                    [2:0] m1_axi4_awprot,
    output logic    [N_PORTS-1:0]                    [3:0] m1_axi4_awcache,
    output logic    [N_PORTS-1:0]                    [3:0] m1_axi4_awregion,
    output logic    [N_PORTS-1:0]                    [3:0] m1_axi4_awqos,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m1_axi4_awuser,

    output logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] m1_axi4_wdata,
    output logic    [N_PORTS-1:0]                          m1_axi4_wvalid,
    input  logic    [N_PORTS-1:0]                          m1_axi4_wready,
    output logic    [N_PORTS-1:0]   [AXI_DATA_WIDTH/8-1:0] m1_axi4_wstrb,
    output logic    [N_PORTS-1:0]                          m1_axi4_wlast,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m1_axi4_wuser,

    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m1_axi4_bid,
    input  logic    [N_PORTS-1:0]                    [1:0] m1_axi4_bresp,
    input  logic    [N_PORTS-1:0]                          m1_axi4_bvalid,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m1_axi4_buser,
    output logic    [N_PORTS-1:0]                          m1_axi4_bready,

    output logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m1_axi4_arid,
    output logic    [N_PORTS-1:0]   [AXI_M_ADDR_WIDTH-1:0] m1_axi4_araddr,
    output logic    [N_PORTS-1:0]                          m1_axi4_arvalid,
    input  logic    [N_PORTS-1:0]                          m1_axi4_arready,
    output logic    [N_PORTS-1:0]                    [7:0] m1_axi4_arlen,
    output logic    [N_PORTS-1:0]                    [2:0] m1_axi4_arsize,
    output logic    [N_PORTS-1:0]                    [1:0] m1_axi4_arburst,
    output logic    [N_PORTS-1:0]                          m1_axi4_arlock,
    output logic    [N_PORTS-1:0]                    [2:0] m1_axi4_arprot,
    output logic    [N_PORTS-1:0]                    [3:0] m1_axi4_arcache,
    output logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m1_axi4_aruser,

    input  logic    [N_PORTS-1:0]       [AXI_ID_WIDTH-1:0] m1_axi4_rid,
    input  logic    [N_PORTS-1:0]     [AXI_DATA_WIDTH-1:0] m1_axi4_rdata,
    input  logic    [N_PORTS-1:0]                    [1:0] m1_axi4_rresp,
    input  logic    [N_PORTS-1:0]                          m1_axi4_rvalid,
    output logic    [N_PORTS-1:0]                          m1_axi4_rready,
    input  logic    [N_PORTS-1:0]                          m1_axi4_rlast,
    input  logic    [N_PORTS-1:0]     [AXI_USER_WIDTH-1:0] m1_axi4_ruser,    
    // }}}
    
    // AXI 4 Lite Slave (Configuration Interface) {{{
    // AXI4-Lite port to setup the rab slices
    // use this to program the configuration registers
    input  logic                 [AXI_LITE_ADDR_WIDTH-1:0] s_axi4lite_awaddr,
    input  logic                                           s_axi4lite_awvalid,
    output logic                                           s_axi4lite_awready,
           
    input  logic                 [AXI_LITE_DATA_WIDTH-1:0] s_axi4lite_wdata,
    input  logic                                           s_axi4lite_wvalid,
    output logic                                           s_axi4lite_wready,
    input  logic               [AXI_LITE_DATA_WIDTH/8-1:0] s_axi4lite_wstrb,
           
    output logic                                     [1:0] s_axi4lite_bresp,
    output logic                                           s_axi4lite_bvalid,
    input  logic                                           s_axi4lite_bready,
           
    input  logic                 [AXI_LITE_ADDR_WIDTH-1:0] s_axi4lite_araddr,
    input  logic                                           s_axi4lite_arvalid,
    output logic                                           s_axi4lite_arready,
           
    output logic                 [AXI_LITE_DATA_WIDTH-1:0] s_axi4lite_rdata,
    output logic                                     [1:0] s_axi4lite_rresp,
    output logic                                           s_axi4lite_rvalid,
    input  logic                                           s_axi4lite_rready,
    // }}}

    // BRAMs {{{
    BramPort.Slave                                         ArBram_PS,
    BramPort.Slave                                         AwBram_PS,
    // }}}

    // Logger Control {{{
    input  logic                                           ArLogClr_SI,
    input  logic                                           AwLogClr_SI,
    // }}}

    // Interrupt Outputs {{{
    // Interrupt lines to handle misses, collisions of slices/multiple hits,
    // protection faults and overflow of the miss handling fifo    
    output logic                             [N_PORTS-1:0] int_miss,
    output logic                             [N_PORTS-1:0] int_multi,
    output logic                             [N_PORTS-1:0] int_prot,
    output logic                                           int_mhr_full,
    output logic                                           int_ar_log_full,
    output logic                                           int_aw_log_full
    // }}}

  );

  // }}}

  // Signals {{{
  // ███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
  // ██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
  // ███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
  // ╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
  // ███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
  // ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
  //                                                       

  // Internal AXI4 lines, these connect buffers on the slave side to the rab core and
  // multiplexers which switch between the two master outputs
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_awid;
  logic [N_PORTS-1:0]  [AXI_S_ADDR_WIDTH-1:0] int_awaddr;
  logic [N_PORTS-1:0]                         int_awvalid;
  logic [N_PORTS-1:0]                         int_awready;
  logic [N_PORTS-1:0]                   [7:0] int_awlen;
  logic [N_PORTS-1:0]                   [2:0] int_awsize;
  logic [N_PORTS-1:0]                   [1:0] int_awburst;
  logic [N_PORTS-1:0]                         int_awlock;
  logic [N_PORTS-1:0]                   [2:0] int_awprot;
  logic [N_PORTS-1:0]                   [3:0] int_awcache;
  logic [N_PORTS-1:0]                   [3:0] int_awregion;
  logic [N_PORTS-1:0]                   [3:0] int_awqos;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_awuser;
  
  logic [N_PORTS-1:0]    [AXI_DATA_WIDTH-1:0] int_wdata;
  logic [N_PORTS-1:0]                         int_wvalid;
  logic [N_PORTS-1:0]                         int_wready;
  logic [N_PORTS-1:0]  [AXI_DATA_WIDTH/8-1:0] int_wstrb;
  logic [N_PORTS-1:0]                         int_wlast;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_wuser;
  
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_bid;
  logic [N_PORTS-1:0]                   [1:0] int_bresp;
  logic [N_PORTS-1:0]                         int_bvalid;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_buser;
  logic [N_PORTS-1:0]                         int_bready;
  
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_arid;
  logic [N_PORTS-1:0]  [AXI_S_ADDR_WIDTH-1:0] int_araddr;
  logic [N_PORTS-1:0]                         int_arvalid;
  logic [N_PORTS-1:0]                         int_arready;
  logic [N_PORTS-1:0]                   [7:0] int_arlen;
  logic [N_PORTS-1:0]                   [2:0] int_arsize;
  logic [N_PORTS-1:0]                   [1:0] int_arburst;
  logic [N_PORTS-1:0]                         int_arlock;
  logic [N_PORTS-1:0]                   [2:0] int_arprot;
  logic [N_PORTS-1:0]                   [3:0] int_arcache;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_aruser;
  
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_rid;
  logic [N_PORTS-1:0]                   [1:0] int_rresp;
  logic [N_PORTS-1:0]    [AXI_DATA_WIDTH-1:0] int_rdata;
  logic [N_PORTS-1:0]                         int_rlast;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_ruser;
  logic [N_PORTS-1:0]                         int_rvalid;
  logic [N_PORTS-1:0]                         int_rready;

  // rab_core outputs
  logic [N_PORTS-1:0]  [AXI_M_ADDR_WIDTH-1:0] int_wtrans_addr;
  logic [N_PORTS-1:0]                         int_wtrans_accept;
  logic [N_PORTS-1:0]                         int_wtrans_drop;
  logic [N_PORTS-1:0]                         int_wtrans_sent;
  logic [N_PORTS-1:0]                         int_wmaster_select;   
  
  logic [N_PORTS-1:0]  [AXI_M_ADDR_WIDTH-1:0] int_rtrans_addr;
  logic [N_PORTS-1:0]                         int_rtrans_accept;
  logic [N_PORTS-1:0]                         int_rtrans_drop;
  logic [N_PORTS-1:0]                         int_rtrans_sent;
  logic [N_PORTS-1:0]                         int_rmaster_select;   

  logic [N_PORTS-1:0]                         int_dwch_master_select; // for the current transaction on dw channel
  logic [N_PORTS-1:0]                         int_wtrans_was_accept;
  logic [N_PORTS-1:0]                         master_select_fifo_not_empty;
  logic [N_PORTS-1:0]                         master_select_fifo_not_full;
  logic [N_PORTS-1:0]                         master_select_fifo_out;
  logic [N_PORTS-1:0]                         w_new_rab_output;   
  
  // Internal master0 AXI4 lines. These connect the first master port to the
  // multiplexers
  // For channels read address, write address and write data the other lines
  // are ignored if valid is not set, therefore we only need to multiplex those
  logic [N_PORTS-1:0]                         int_m0_awvalid;
  logic [N_PORTS-1:0]                         int_m0_awready;

  logic [N_PORTS-1:0]                         int_m0_wvalid;
  logic [N_PORTS-1:0]                         int_m0_wready;

  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_m0_bid;
  logic [N_PORTS-1:0]                   [1:0] int_m0_bresp;
  logic [N_PORTS-1:0]                         int_m0_bvalid;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_m0_buser;
  logic [N_PORTS-1:0]                         int_m0_bready;

  logic [N_PORTS-1:0]                         int_m0_arvalid;
  logic [N_PORTS-1:0]                         int_m0_arready;
  
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_m0_rid;
  logic [N_PORTS-1:0]                   [1:0] int_m0_rresp;
  logic [N_PORTS-1:0]    [AXI_DATA_WIDTH-1:0] int_m0_rdata;
  logic [N_PORTS-1:0]                         int_m0_rlast;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_m0_ruser;
  logic [N_PORTS-1:0]                         int_m0_rready;
  logic [N_PORTS-1:0]                         int_m0_rvalid;

  logic [N_PORTS-1:0]                         int_m0_wtrans_accept;
  logic [N_PORTS-1:0]                         l1_m0_wtrans_drop;
  logic [N_PORTS-1:0]                         l2_m0_wtrans_accept;
  logic [N_PORTS-1:0]                         l2_m0_wtrans_sent;
  logic [N_PORTS-1:0]                         l2_m0_wtrans_drop;
  logic [N_PORTS-1:0]                         int_m0_rtrans_accept;
  logic [N_PORTS-1:0]                         l1_m0_rtrans_drop;   
  logic [N_PORTS-1:0]                         l2_m0_rtrans_accept;  
  logic [N_PORTS-1:0]                         int_m0_wtrans_sent;
  logic [N_PORTS-1:0]                         int_m0_rtrans_sent;
  logic [N_PORTS-1:0]                         l2_m0_rtrans_sent;               
  
  // Internal master1 AXI4 lines. These connect the second master port to the
  // multiplexers
  // For channels read address, write address and write data the other lines
  // are ignored if valid is not set, therefore we only need to multiplex those
  logic [N_PORTS-1:0]                         int_m1_awvalid;
  logic [N_PORTS-1:0]                         int_m1_awready;

  logic [N_PORTS-1:0]                         int_m1_wvalid;
  logic [N_PORTS-1:0]                         int_m1_wready;

  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_m1_bid;
  logic [N_PORTS-1:0]                   [1:0] int_m1_bresp;
  logic [N_PORTS-1:0]                         int_m1_bvalid;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_m1_buser;
  logic [N_PORTS-1:0]                         int_m1_bready;
  
  logic [N_PORTS-1:0]                         int_m1_arvalid;
  logic [N_PORTS-1:0]                         int_m1_arready;
  
  logic [N_PORTS-1:0]      [AXI_ID_WIDTH-1:0] int_m1_rid;
  logic [N_PORTS-1:0]                   [1:0] int_m1_rresp;
  logic [N_PORTS-1:0]    [AXI_DATA_WIDTH-1:0] int_m1_rdata;
  logic [N_PORTS-1:0]                         int_m1_rlast;
  logic [N_PORTS-1:0]    [AXI_USER_WIDTH-1:0] int_m1_ruser;
  logic [N_PORTS-1:0]                         int_m1_rvalid;
  logic [N_PORTS-1:0]                         int_m1_rready;

  logic [N_PORTS-1:0]                         int_m1_wtrans_accept;
  logic [N_PORTS-1:0]                         l1_m1_wtrans_drop;
  logic [N_PORTS-1:0]                         l2_m1_wtrans_accept;
  logic [N_PORTS-1:0]                         l2_m1_wtrans_sent;
  logic [N_PORTS-1:0]                         l2_m1_wtrans_drop;
  logic [N_PORTS-1:0]                         int_m1_rtrans_accept;
  logic [N_PORTS-1:0]                         l1_m1_rtrans_drop;   
  logic [N_PORTS-1:0]                         l2_m1_rtrans_accept;   
  logic [N_PORTS-1:0]                         int_m1_wtrans_sent;
  logic [N_PORTS-1:0]                         int_m1_rtrans_sent;
  logic [N_PORTS-1:0]                         l2_m1_rtrans_sent;
     
  // L1 outputs
  logic [N_PORTS-1:0]                         rab_miss; // L1 RAB miss
  logic [N_PORTS-1:0]                         rab_prot;
  logic [N_PORTS-1:0]                         rab_multi;

  //
  // Signals used to support L2 TLB
  //
  // L2 RAM configuration signals
  logic [N_PORTS-1:0] [AXI_LITE_DATA_WIDTH-1:0] wdata_tlb_l2;
  logic [N_PORTS-1:0] [AXI_LITE_ADDR_WIDTH-1:0] waddr_tlb_l2;
  logic [N_PORTS-1:0]                           wren_tlb_l2; 
  
   // L2 outputs
  logic [N_PORTS-1:0]                           miss_l2;
  logic [N_PORTS-1:0]                           hit_l2;
  logic [N_PORTS-1:0]                           prot_l2;
  logic [N_PORTS-1:0]                           multi_l2;
  
  logic [N_PORTS-1:0]                           l1_miss;  // Trigger for L2

  // Signals used when there are simultaneous prot/multi in L1 and L2.
  logic [N_PORTS-1:0]                           int_prot_next,int_multi_next;
  logic [N_PORTS-1:0]                           double_prot,double_prot_en;
  logic [N_PORTS-1:0]                           double_multi,double_multi_en;

  // Signals used in axi senders.
  logic [N_PORTS-1:0]                           stall_aw_m0,stall_aw_m1; // Stall AW channel till wlast is received
  logic [N_PORTS-1:0]                           wlast_received;
  logic [N_PORTS-1:0]                           response_sent;
  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] trans_awid;
  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] trans_arid;
  logic [N_PORTS-1:0]                           wtrans_drop,rtrans_drop; // signals used in rwch,rrch senders

  logic [N_PORTS-1:0]    [AXI_S_ADDR_WIDTH-1:0] l2_in_addr, l2_in_addr_reg;
  logic [N_PORTS-1:0]                           l2_wtrans_accept;
  logic [N_PORTS-1:0]                           l2_rtrans_accept;
  logic [N_PORTS-1:0]                           l2_wtrans_drop,l1_wtrans_drop;
  logic [N_PORTS-1:0]                           l2_rtrans_drop,l1_rtrans_drop;
  logic [N_PORTS-1:0]                           l1_wtrans_drop_saved, l1_rtrans_drop_saved;
  logic [N_PORTS-1:0]    [AXI_M_ADDR_WIDTH-1:0] l2_out_addr;
  logic [N_PORTS-1:0]                           l2_rw_type,l2_rw_type_comb;   
  logic [N_PORTS-1:0]    [AXI_M_ADDR_WIDTH-1:0] l2_wtrans_addr;
  logic [N_PORTS-1:0]    [AXI_M_ADDR_WIDTH-1:0] l2_rtrans_addr;
  logic [N_PORTS-1:0]                           l2_trans_sent;
  logic [N_PORTS-1:0]                           l2_wtrans_sent;
  logic [N_PORTS-1:0]                           l2_rtrans_sent;
  logic [N_PORTS-1:0]                           l2_busy;

  logic [N_PORTS-1:0]                           l2_master_select;

  logic [N_PORTS-1:0]                           l1_multi_or_prot_next;
  logic [N_PORTS-1:0]                           l1_multi_or_prot;
  
  logic [N_PORTS-1:0]                           update_id, update_id_next;
  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] l2_awid,int_awid_d;
  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] l2_arid,int_arid_d;
  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] trans_id_l2;   
    
  genvar           i;

  // L2 FSM
  typedef enum logic[2:0] {L2_IDLE, L2_BUSY, L1_WAITING, L1_MULTI_PROT, L1_MULTI_PROT_1, L1_MULTI_PROT_WAITING} l2_state_t;   
  l2_state_t [N_PORTS-1:0] [2:0] l2_state,l2_next_state;   

  // WREADY FSM
  typedef enum logic[1:0] {WREADY_IDLE, WREADY_WAIT_FOR_M0, WREADY_WAIT_FOR_M1} wready_state_t;   
  wready_state_t [N_PORTS-1:0] [1:0] wready_state, wready_next_state;  
  logic [N_PORTS-1:0] clr_m0_wvalid, clr_m1_wvalid, send_wready;

  // }}}
     
  // Local parameters {{{

  // Enable L2 for select ports
  localparam integer ENABLE_L2TLB[N_PORTS-1:0] = `EN_L2TLB_ARRAY;

  // L2TLB parameters
  // Total entries in L2 TLB is (L2TLB_NUM_SETS * L2TLB_NUM_ENTRIES_PER_SET)
  localparam integer L2TLB_NUM_SETS = 32;
  localparam integer L2TLB_NUM_ENTRIES_PER_SET = 32; // total number including both ports and all rams.
  localparam integer L2TLB_PARALLEL = 4; // Number of parallel VA RAMs in L2 TLB.
  localparam integer L2TLB_W_BUFFER_DEPTH = (16/L2TLB_PARALLEL)+3;

  // }}}
  
  // Buf and Send {{{
  // ██████╗ ██╗   ██╗███████╗       ██╗       ███████╗███████╗███╗   ██╗██████╗ 
  // ██╔══██╗██║   ██║██╔════╝       ██║       ██╔════╝██╔════╝████╗  ██║██╔══██╗
  // ██████╔╝██║   ██║█████╗      ████████╗    ███████╗█████╗  ██╔██╗ ██║██║  ██║
  // ██╔══██╗██║   ██║██╔══╝      ██╔═██╔═╝    ╚════██║██╔══╝  ██║╚██╗██║██║  ██║
  // ██████╔╝╚██████╔╝██║         ██████║      ███████║███████╗██║ ╚████║██████╔╝
  // ╚═════╝  ╚═════╝ ╚═╝         ╚═════╝      ╚══════╝╚══════╝╚═╝  ╚═══╝╚═════╝ 
  // 
  generate for (i = 0; i < N_PORTS; i++) begin
     
  // Write Address channel (aw) {{{
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
     
  axi4_aw_buffer
    #(
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_aw_inbuffer
    (
      .axi4_aclk       (Clk_CI),
      .axi4_arstn      (Rst_RBI),
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
      .m_axi4_awuser   (int_awuser [i])
    );

  axi4_aw_sender
    #(
      .AXI_ADDR_WIDTH ( AXI_M_ADDR_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH     ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH   ),
      .ENABLE_L2TLB   ( ENABLE_L2TLB[i]  )
      )
    u_aw_sender_m0
    (
      .axi4_aclk       (Clk_CI),
      .axi4_arstn      (Rst_RBI),
      .l1_trans_accept (int_m0_wtrans_accept[i]),
      .l1_trans_drop   (l1_m0_wtrans_drop[i]),
      .l1_trans_sent   (int_m0_wtrans_sent[i]),
      .l2_trans_accept (l2_m0_wtrans_accept[i]),
      .l2_busy         (l2_busy[i]),
      .l2_wtrans_sent  (l2_m0_wtrans_sent[i]),
      .stall_aw        (stall_aw_m0[i]),
      .s_axi4_awid     (int_awid[i]),
      .l1_axi4_awaddr  (int_wtrans_addr[i]), //gets the modified address
      .l2_axi4_awaddr  (l2_wtrans_addr[i]), //gets the modified address from L2
      .s_axi4_awvalid  (int_m0_awvalid[i]),
      .s_axi4_awready  (int_m0_awready[i]),
      .s_axi4_awlen    (int_awlen[i]),
      .s_axi4_awsize   (int_awsize[i]),
      .s_axi4_awburst  (int_awburst[i]),
      .s_axi4_awlock   (int_awlock[i]),
      .s_axi4_awprot   (int_awprot[i]),
      .s_axi4_awcache  (int_awcache[i]),
      .s_axi4_awregion (int_awregion[i]),
      .s_axi4_awqos    (int_awqos[i]),
      .s_axi4_awuser   (int_awuser[i]),
      .m_axi4_awid     (m0_axi4_awid[i]),
      .m_axi4_awaddr   (m0_axi4_awaddr[i]),
      .m_axi4_awvalid  (m0_axi4_awvalid[i]),
      .m_axi4_awready  (m0_axi4_awready[i]),
      .m_axi4_awlen    (m0_axi4_awlen[i]),
      .m_axi4_awsize   (m0_axi4_awsize[i]),
      .m_axi4_awburst  (m0_axi4_awburst[i]),
      .m_axi4_awlock   (m0_axi4_awlock[i]),
      .m_axi4_awprot   (m0_axi4_awprot[i]),
      .m_axi4_awcache  (m0_axi4_awcache[i]),
      .m_axi4_awregion (m0_axi4_awregion[i]),
      .m_axi4_awqos    (m0_axi4_awqos[i]),
      .m_axi4_awuser   (m0_axi4_awuser[i])
    );
  
    axi4_aw_sender
    #(
      .AXI_ADDR_WIDTH ( AXI_M_ADDR_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH     ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH   ),
      .ENABLE_L2TLB   ( ENABLE_L2TLB[i]  )
      )
    u_aw_sender_m1
    (
      .axi4_aclk       (Clk_CI),
      .axi4_arstn      (Rst_RBI),
      .l1_trans_accept (int_m1_wtrans_accept[i]),
      .l1_trans_drop   (l1_m1_wtrans_drop[i]),
      .l1_trans_sent   (int_m1_wtrans_sent[i]),
      .l2_trans_accept (l2_m1_wtrans_accept[i]),
      .l2_busy         (l2_busy[i]),
      .l2_wtrans_sent  (l2_m1_wtrans_sent[i]),
      .stall_aw        (stall_aw_m1[i]),                                 
      .s_axi4_awid     (int_awid[i]),
      .l1_axi4_awaddr  (int_wtrans_addr[i]), //gets the modified address
      .l2_axi4_awaddr  (l2_wtrans_addr[i]), //gets the modified address from L2
      .s_axi4_awvalid  (int_m1_awvalid[i]),
      .s_axi4_awready  (int_m1_awready[i]),
      .s_axi4_awlen    (int_awlen[i]),
      .s_axi4_awsize   (int_awsize[i]),
      .s_axi4_awburst  (int_awburst[i]),
      .s_axi4_awlock   (int_awlock[i]),
      .s_axi4_awprot   (int_awprot[i]),
      .s_axi4_awcache  (int_awcache[i]),
      .s_axi4_awregion (int_awregion[i]),
      .s_axi4_awqos    (int_awqos[i]),
      .s_axi4_awuser   (int_awuser[i]),
      .m_axi4_awid     (m1_axi4_awid[i]),
      .m_axi4_awaddr   (m1_axi4_awaddr[i]),
      .m_axi4_awvalid  (m1_axi4_awvalid[i]),
      .m_axi4_awready  (m1_axi4_awready[i]),
      .m_axi4_awlen    (m1_axi4_awlen[i]),
      .m_axi4_awsize   (m1_axi4_awsize[i]),
      .m_axi4_awburst  (m1_axi4_awburst[i]),
      .m_axi4_awlock   (m1_axi4_awlock[i]),
      .m_axi4_awprot   (m1_axi4_awprot[i]),
      .m_axi4_awcache  (m1_axi4_awcache[i]),
      .m_axi4_awregion (m1_axi4_awregion[i]),
      .m_axi4_awqos    (m1_axi4_awqos[i]),
      .m_axi4_awuser   (m1_axi4_awuser[i])
    );
  
  /*   
   * Multiplexer to switch between the two output master ports on the write address(aw) channel
   */
  // In case of L1 Hit, send the signals to the correct master.
  // In case of L1 Miss, send the signals to both masters. They will be stored till L2 outputs are available.
  always_comb
    begin
       if(int_wmaster_select[i] == 1'b0 && int_wtrans_accept[i])
         begin
            int_m0_wtrans_accept[i]  = int_wtrans_accept[i];
            l1_m0_wtrans_drop[i]     = l1_wtrans_drop[i];
            int_m0_awvalid[i]        = int_awvalid[i];
  
            int_m1_wtrans_accept[i]  = 1'b0;
            l1_m1_wtrans_drop[i]     = 1'b0;
            int_m1_awvalid[i]        = 1'b0;
         end
       else if (int_wmaster_select[i] == 1'b1 && int_wtrans_accept[i])
         begin
            int_m0_wtrans_accept[i]  = 1'b0;
            l1_m0_wtrans_drop[i]     = 1'b0;
            int_m0_awvalid[i]        = 1'b0;
            
            int_m1_wtrans_accept[i]  = int_wtrans_accept[i];
            l1_m1_wtrans_drop[i]     = l1_wtrans_drop[i];
            int_m1_awvalid[i]        = int_awvalid[i];
         end 
       else // L1 drop
         begin
            int_m0_wtrans_accept[i]  = int_wtrans_accept[i];
            l1_m0_wtrans_drop[i]     = l1_wtrans_drop[i];
            int_m0_awvalid[i]        = int_awvalid[i];
            
            int_m1_wtrans_accept[i]  = int_wtrans_accept[i];
            l1_m1_wtrans_drop[i]     = l1_wtrans_drop[i];
            int_m1_awvalid[i]        = int_awvalid[i];
         end    
    end // always_comb begin
  
  always_comb
    begin
       if (int_wmaster_select[i] == 1'b1)
         begin
            int_wtrans_sent[i]       = int_m1_wtrans_sent[i];
            int_awready[i]           = int_m1_awready[i];   
         end
       else
         begin
            int_wtrans_sent[i]       = int_m0_wtrans_sent[i];
            int_awready[i]           = int_m0_awready[i];
         end
    end            
  
  always_comb
    begin
       if (l2_master_select[i] == 1'b1)
         begin
            l2_m0_wtrans_accept[i]  = 1'b0;
            l2_m1_wtrans_accept[i]  = l2_wtrans_accept[i];
            
            l2_wtrans_sent[i]       = l2_m1_wtrans_sent[i];
         end
       else
         begin
            l2_m0_wtrans_accept[i]  = l2_wtrans_accept[i];
            l2_m1_wtrans_accept[i]  = 1'b0;
            
            l2_wtrans_sent[i]       = l2_m0_wtrans_sent[i];
         end  
    end // always_comb begin   
   // }}}

  // Write Data channel (dw) {{{
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
  axi4_w_buffer
    #(
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_w_inbuffer
    (
      .axi4_aclk     (Clk_CI),
      .axi4_arstn    (Rst_RBI),
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
      .m_axi4_wuser  (int_wuser [i])
    );
  
  axi4_w_sender
    #(
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH       ),
      .ENABLE_L2TLB   ( ENABLE_L2TLB[i]      ), 
      .L2BUFFER_DEPTH ( L2TLB_W_BUFFER_DEPTH )
      )
    u_w_sender_m0
    (
      .axi4_aclk       (Clk_CI),
      .axi4_arstn      (Rst_RBI),
      .l1_trans_accept (int_m0_wtrans_accept[i]),
      .l2_trans_accept (l2_m0_wtrans_accept[i]),                                     
      .l2_trans_drop   (l2_m0_wtrans_drop[i]),
      .l1_miss         (l1_m0_wtrans_drop[i]),                                     
      .stall_aw        (stall_aw_m0[i]),
      .wlast_received  (wlast_received[i]),
      .response_sent   (response_sent[i]),                                                                              
      .s_axi4_wdata    (int_wdata[i]),
      .s_axi4_wvalid   (int_m0_wvalid[i]),
      .s_axi4_wready   (int_m0_wready[i]),
      .s_axi4_wstrb    (int_wstrb[i]),
      .s_axi4_wlast    (int_wlast[i]),
      .s_axi4_wuser    (int_wuser[i]),
      .m_axi4_wdata    (m0_axi4_wdata[i]),
      .m_axi4_wvalid   (m0_axi4_wvalid[i]),
      .m_axi4_wready   (m0_axi4_wready[i]),
      .m_axi4_wstrb    (m0_axi4_wstrb[i]),
      .m_axi4_wlast    (m0_axi4_wlast[i]),
      .m_axi4_wuser    (m0_axi4_wuser[i])
    );
  
  axi4_w_sender
    #(
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH       ),
      .ENABLE_L2TLB   ( ENABLE_L2TLB[i]      ), 
      .L2BUFFER_DEPTH ( L2TLB_W_BUFFER_DEPTH )
      )
    u_w_sender_m1
    (
      .axi4_aclk       (Clk_CI),
      .axi4_arstn      (Rst_RBI),
      .l1_trans_accept (int_m1_wtrans_accept[i]),
      .l2_trans_accept (l2_m1_wtrans_accept[i]),                                     
      .l2_trans_drop   (l2_m1_wtrans_drop[i]),
      .l1_miss         (l1_m1_wtrans_drop[i]),                                     
      .stall_aw        (stall_aw_m1[i]),
      .wlast_received  (),
      .response_sent   (1'b0),                                                                              
      .s_axi4_wdata    (int_wdata[i]),
      .s_axi4_wvalid   (int_m1_wvalid[i]),
      .s_axi4_wready   (int_m1_wready[i]),
      .s_axi4_wstrb    (int_wstrb[i]),
      .s_axi4_wlast    (int_wlast[i]),
      .s_axi4_wuser    (int_wuser[i]),
      .m_axi4_wdata    (m1_axi4_wdata[i]),
      .m_axi4_wvalid   (m1_axi4_wvalid[i]),
      .m_axi4_wready   (m1_axi4_wready[i]),
      .m_axi4_wstrb    (m1_axi4_wstrb[i]),
      .m_axi4_wlast    (m1_axi4_wlast[i]),
      .m_axi4_wuser    (m1_axi4_wuser[i])
    );
  
  /*
   * To be able to switch between the two master ports for write data, we need to
   * store the master_select flags of the last write addresses in a FIFO, as
   * multiple data write requests might have been startet and the data can be
   * interleaved with the addresses. However the data has the same order as the
   * addresses. The FIFO is triggered by accept/drop from the rab_core on push
   * and by wlast for pop(data transaction finished)
   */
  axi_buffer_rab
    #(
      .DATA_WIDTH ( 2 )
      )
    u_master_select_fifo
    (
      .clk(Clk_CI),
      .rstn(Rst_RBI),
      .data_out({master_select_fifo_out[i],int_wtrans_was_accept[i]}),
      .valid_out(master_select_fifo_not_empty[i]),
      .ready_out(master_select_fifo_not_full[i]),
      .data_in({int_wmaster_select[i],int_wtrans_accept[i]}),
      .valid_in(w_new_rab_output[i]),
      .ready_in(int_wlast[i] && int_wready[i] && int_wvalid[i])
    );
  
  assign w_new_rab_output[i]       = int_wtrans_accept[i] | l1_wtrans_drop[i]; 
  assign int_dwch_master_select[i] = master_select_fifo_not_empty[i] & master_select_fifo_out[i];
  
  /* 
   * Multiplexer to switch between the two output master ports on the write data(dw) channel
   */
  // In case of L1 miss, signals are stored in both masters.
  // In case of L1 hit, send the signals to the correct master.
  // In case of L2 miss, drop the signals from both masters.
  // In case of L2 hit, send from the correct master, drop from other master.
  always_comb
    begin
      int_m0_wvalid[i] = 1'b0;
      int_m1_wvalid[i] = 1'b0;
      int_wready[i] = 1'b0;
      if((int_dwch_master_select[i] == 1'b0) && int_wtrans_was_accept[i] && master_select_fifo_not_empty[i])
        begin
          int_m0_wvalid[i] = int_wvalid[i];
          int_m1_wvalid[i] = 1'b0;
  
          int_wready[i]    = int_m0_wready[i];
        end
      else if ((int_dwch_master_select[i] == 1'b1) && int_wtrans_was_accept[i] && master_select_fifo_not_empty[i])
        begin
          int_m0_wvalid[i] = 1'b0;
          int_m1_wvalid[i] = int_wvalid[i];
  
          int_wready[i]    = int_m1_wready[i];
        end
      else if (master_select_fifo_not_empty[i])
        begin             
          if (ENABLE_L2TLB[i] == 1) begin
            int_m0_wvalid[i] = int_wvalid[i] && ~clr_m0_wvalid[i];
            int_m1_wvalid[i] = int_wvalid[i] && ~clr_m1_wvalid[i];
              
            int_wready[i]    = send_wready[i];
          end else begin
            int_m0_wvalid[i] = int_wvalid[i];
            int_m1_wvalid[i] = 1'b0;
              
            int_wready[i]    = int_m0_wready[i];
          end
        end             
    end // always_comb
     
  if (ENABLE_L2TLB[i] == 1) begin
    // wready FSM
    always_ff @(posedge Clk_CI) begin
      if (Rst_RBI == 0) begin
        wready_state[i] <= WREADY_IDLE;
      end else begin
        wready_state[i] <= wready_next_state[i];
      end
    end
  
    always_comb begin
      wready_next_state[i] = wready_state[i];
      send_wready[i] = 1'b0;
      clr_m0_wvalid[i] = 1'b0;
      clr_m1_wvalid[i] = 1'b0;
      case(wready_state[i])
        WREADY_IDLE :
          if (~int_wtrans_was_accept[i] && int_m0_wready[i] && int_m1_wready[i]) begin
            send_wready[i] = 1'b1;
          end else if (~int_wtrans_was_accept[i] && int_m0_wready[i] && ~int_m1_wready[i]) begin
            wready_next_state[i] = WREADY_WAIT_FOR_M1;
          end else if (~int_wtrans_was_accept[i] && ~int_m0_wready[i] && int_m1_wready[i]) begin
            wready_next_state[i] = WREADY_WAIT_FOR_M0;
          end
  
        WREADY_WAIT_FOR_M0 : begin
          clr_m1_wvalid[i] = 1'b1;
          if (int_m0_wready[i]) begin
            send_wready[i] = 1'b1;
            wready_next_state[i] = WREADY_IDLE;
          end
        end
        
        WREADY_WAIT_FOR_M1 : begin
          clr_m0_wvalid[i] = 1'b1;
          if (int_m1_wready[i]) begin
            send_wready[i] = 1'b1;
            wready_next_state[i] = WREADY_IDLE;
          end
        end
      endcase // case (wready_state)
    end // always_comb begin
  
  end // if (ENABLE_L2TLB[i] == 1)
       
  assign l2_m0_wtrans_drop[i] = l2_wtrans_drop[i] | (l2_wtrans_accept[i] && (l2_master_select[i] == 1'b1));
  assign l2_m1_wtrans_drop[i] = l2_wtrans_drop[i] | (l2_wtrans_accept[i] && (l2_master_select[i] == 1'b0));      

  // }}}
  
  // Write Response channel (rw) {{{
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
  axi4_b_buffer
    #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_b_buffer_m0
    ( 
      .axi4_aclk     ( Clk_CI             ),
      .axi4_arstn    ( Rst_RBI            ),
      .s_axi4_bid    ( int_m0_bid [i]     ),
      .s_axi4_bresp  ( int_m0_bresp [i]   ),
      .s_axi4_bvalid ( int_m0_bvalid [i]  ),
      .s_axi4_buser  ( int_m0_buser [i]   ),
      .s_axi4_bready ( int_m0_bready [i]  ),
      .m_axi4_bid    ( m0_axi4_bid [i]    ),
      .m_axi4_bresp  ( m0_axi4_bresp [i]  ),
      .m_axi4_bvalid ( m0_axi4_bvalid [i] ),
      .m_axi4_buser  ( m0_axi4_buser [i]  ),
      .m_axi4_bready ( m0_axi4_bready [i] )
    );
  
   axi4_b_buffer
    #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_b_buffer_m1
    (
      .axi4_aclk      ( Clk_CI             ),
      .axi4_arstn     ( Rst_RBI            ),
      .s_axi4_bid     ( int_m1_bid [i]     ),
      .s_axi4_bresp   ( int_m1_bresp [i]   ),
      .s_axi4_bvalid  ( int_m1_bvalid [i]  ),
      .s_axi4_buser   ( int_m1_buser [i]   ),
      .s_axi4_bready  ( int_m1_bready [i]  ),
      .m_axi4_bid     ( m1_axi4_bid [i]    ),
      .m_axi4_bresp   ( m1_axi4_bresp [i]  ),
      .m_axi4_bvalid  ( m1_axi4_bvalid [i] ),
      .m_axi4_buser   ( m1_axi4_buser [i]  ),
      .m_axi4_bready  ( m1_axi4_bready [i] )
    );
    
  axi4_b_sender
    #(
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH    ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH  ),
        .ENABLE_L2TLB   ( ENABLE_L2TLB[i] )
      )
    u_b_sender
    ( 
      .axi4_aclk      (Clk_CI),
      .axi4_arstn     (Rst_RBI),                          
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
      .m_axi4_bready  (int_bready[i])
    );
  
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

  // }}}
     
  // Read Address channel (ar) {{{
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
  axi4_ar_buffer 
    #(
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_ar_inbuffer
    (
      .axi4_aclk      (Clk_CI),
      .axi4_arstn     (Rst_RBI),
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
      .m_axi4_aruser  (int_aruser [i])
    );
  
    axi4_ar_sender
      #(
        .AXI_ADDR_WIDTH ( AXI_M_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH     ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH   ),
        .ENABLE_L2TLB   ( ENABLE_L2TLB[i]  )
        )
      u_ar_sender_m0
      (
        .axi4_aclk       (Clk_CI),
        .axi4_arstn      (Rst_RBI),
        .l1_trans_accept (int_m0_rtrans_accept[i]),
        .l1_trans_drop   (l1_m0_rtrans_drop[i]),
        .l1_trans_sent   (int_m0_rtrans_sent[i]),
        .l2_trans_accept (l2_m0_rtrans_accept[i]),
        .l2_busy         (l2_busy[i]),
        .l2_rtrans_sent  (l2_m0_rtrans_sent[i]),         
        .s_axi4_arid     (int_arid[i]),
        .l1_axi4_araddr  (int_rtrans_addr[i]), //gets the modified address
        .l2_axi4_araddr  (l2_rtrans_addr[i]),  //gets the modified address from L2                                  
        .s_axi4_arvalid  (int_m0_arvalid[i]),
        .s_axi4_arready  (int_m0_arready[i]),
        .s_axi4_arlen    (int_arlen[i]),
        .s_axi4_arsize   (int_arsize[i]),
        .s_axi4_arburst  (int_arburst[i]),
        .s_axi4_arlock   (int_arlock[i]),
        .s_axi4_arprot   (int_arprot[i]),
        .s_axi4_arcache  (int_arcache[i]),
        .s_axi4_aruser   (int_aruser[i]),
        .m_axi4_arid     (m0_axi4_arid[i]),
        .m_axi4_araddr   (m0_axi4_araddr[i]),
        .m_axi4_arvalid  (m0_axi4_arvalid[i]),
        .m_axi4_arready  (m0_axi4_arready[i]),
        .m_axi4_arlen    (m0_axi4_arlen[i]),
        .m_axi4_arsize   (m0_axi4_arsize[i]),
        .m_axi4_arburst  (m0_axi4_arburst[i]),
        .m_axi4_arlock   (m0_axi4_arlock[i]),
        .m_axi4_arprot   (m0_axi4_arprot[i]),
        .m_axi4_arcache  (m0_axi4_arcache[i]),
        .m_axi4_aruser   (m0_axi4_aruser[i])
      );
     
     axi4_ar_sender
      #(
        .AXI_ADDR_WIDTH ( AXI_M_ADDR_WIDTH ),
        .AXI_ID_WIDTH   ( AXI_ID_WIDTH     ),
        .AXI_USER_WIDTH ( AXI_USER_WIDTH   ),
        .ENABLE_L2TLB   ( ENABLE_L2TLB[i]  )
        )
      u_ar_sender_m1
      (
        .axi4_aclk       (Clk_CI),
        .axi4_arstn      (Rst_RBI),
        .l1_trans_accept (int_m1_rtrans_accept[i]),
        .l1_trans_drop   (l1_m1_rtrans_drop[i]),
        .l1_trans_sent   (int_m1_rtrans_sent[i]),
        .l2_trans_accept (l2_m1_rtrans_accept[i]),
        .l2_busy         (l2_busy[i]),
        .l2_rtrans_sent  (l2_m1_rtrans_sent[i]),         
        .s_axi4_arid     (int_arid[i]),
        .l1_axi4_araddr  (int_rtrans_addr[i]), //gets the modified address
        .l2_axi4_araddr  (l2_rtrans_addr[i]),  //gets the modified address from L2                                  
        .s_axi4_arvalid  (int_m1_arvalid[i]),
        .s_axi4_arready  (int_m1_arready[i]),
        .s_axi4_arlen    (int_arlen[i]),
        .s_axi4_arsize   (int_arsize[i]),
        .s_axi4_arburst  (int_arburst[i]),
        .s_axi4_arlock   (int_arlock[i]),
        .s_axi4_arprot   (int_arprot[i]),
        .s_axi4_arcache  (int_arcache[i]),
        .s_axi4_aruser   (int_aruser[i]),
        .m_axi4_arid     (m1_axi4_arid[i]),
        .m_axi4_araddr   (m1_axi4_araddr[i]),
        .m_axi4_arvalid  (m1_axi4_arvalid[i]),
        .m_axi4_arready  (m1_axi4_arready[i]),
        .m_axi4_arlen    (m1_axi4_arlen[i]),
        .m_axi4_arsize   (m1_axi4_arsize[i]),
        .m_axi4_arburst  (m1_axi4_arburst[i]),
        .m_axi4_arlock   (m1_axi4_arlock[i]),
        .m_axi4_arprot   (m1_axi4_arprot[i]),
        .m_axi4_arcache  (m1_axi4_arcache[i]),
        .m_axi4_aruser   (m1_axi4_aruser[i])
      );
  
  /* 
   * Multiplexer to switch between the two output master ports on the read address(ar) channel
   */
  
  // In case of L1 Hit, send the signals to the correct master.
  // In case of L1 Miss, send the signals to both masters. They will be stored till L2 outputs are available.
  always_comb
    begin
      if (int_rmaster_select[i] == 1'b0 && int_rtrans_accept[i])
        begin
          int_m0_rtrans_accept[i]  = int_rtrans_accept[i];
          l1_m0_rtrans_drop[i]     = l1_rtrans_drop[i];
          int_m0_arvalid[i]        = int_arvalid[i];
  
          int_m1_rtrans_accept[i]  = 1'b0;
          l1_m1_rtrans_drop[i]     = 1'b0;
          int_m1_arvalid[i]        = 1'b0;
        end
      else if (int_rmaster_select[i] == 1'b1 && int_rtrans_accept[i])
        begin
          int_m0_rtrans_accept[i]  = 1'b0;
          l1_m0_rtrans_drop[i]     = 1'b0;
          int_m0_arvalid[i]        = 1'b0;
          
          int_m1_rtrans_accept[i]  = int_rtrans_accept[i];
          l1_m1_rtrans_drop[i]     = l1_rtrans_drop[i];
          int_m1_arvalid[i]        = int_arvalid[i];
        end 
      else // L1 drop
        begin
          int_m0_rtrans_accept[i]  = int_rtrans_accept[i];
          l1_m0_rtrans_drop[i]     = l1_rtrans_drop[i];
          int_m0_arvalid[i]        = int_arvalid[i];
          
          int_m1_rtrans_accept[i]  = int_rtrans_accept[i];
          l1_m1_rtrans_drop[i]     = l1_rtrans_drop[i];
          int_m1_arvalid[i]        = int_arvalid[i];
        end    
    end // always_comb begin
  
  always_comb
    begin
      if(int_rmaster_select[i] == 1'b1)
        begin
          int_rtrans_sent[i]       = int_m1_rtrans_sent[i];
          int_arready[i]           = int_m1_arready[i];   
        end
      else
        begin
          int_rtrans_sent[i]       = int_m0_rtrans_sent[i];
          int_arready[i]           = int_m0_arready[i];
        end
    end          
     
  always_comb
    begin
       if (l2_master_select[i] == 1'b1)
         begin
            l2_m0_rtrans_accept[i]  = 1'b0;
            l2_m1_rtrans_accept[i]  = l2_rtrans_accept[i];
            
            l2_rtrans_sent[i]       = l2_m1_rtrans_sent[i];
         end
       else
         begin
            l2_m0_rtrans_accept[i]  = l2_rtrans_accept[i];
            l2_m1_rtrans_accept[i]  = 1'b0;
            
            l2_rtrans_sent[i]       = l2_m0_rtrans_sent[i];
         end  
    end // always_comb begin   

  // }}}
       
  // Read Response channel (rr) {{{
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
  axi4_r_buffer
    #(
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_r_buffer_m0
    (
      .axi4_aclk     (Clk_CI),
      .axi4_arstn    (Rst_RBI),
      .s_axi4_rid    (int_m0_rid [i]),
      .s_axi4_rresp  (int_m0_rresp [i]),
      .s_axi4_rdata  (int_m0_rdata [i]),
      .s_axi4_rlast  (int_m0_rlast [i]),
      .s_axi4_rvalid (int_m0_rvalid [i]),
      .s_axi4_ruser  (int_m0_ruser [i]),
      .s_axi4_rready (int_m0_rready [i]),
      .m_axi4_rid    (m0_axi4_rid [i]),
      .m_axi4_rresp  (m0_axi4_rresp [i]),
      .m_axi4_rdata  (m0_axi4_rdata [i]),
      .m_axi4_rlast  (m0_axi4_rlast [i]),
      .m_axi4_rvalid (m0_axi4_rvalid [i]),
      .m_axi4_ruser  (m0_axi4_ruser [i]),
      .m_axi4_rready (m0_axi4_rready [i])
    );
  
    axi4_r_buffer
    #(
      .AXI_DATA_WIDTH ( AXI_DATA_WIDTH ),
      .AXI_ID_WIDTH   ( AXI_ID_WIDTH   ),
      .AXI_USER_WIDTH ( AXI_USER_WIDTH )
      )
    u_r_buffer_m1
    (
      .axi4_aclk     (Clk_CI),
      .axi4_arstn    (Rst_RBI),
      .s_axi4_rid    (int_m1_rid [i]),
      .s_axi4_rresp  (int_m1_rresp [i]),
      .s_axi4_rdata  (int_m1_rdata [i]),
      .s_axi4_rlast  (int_m1_rlast [i]),
      .s_axi4_rvalid (int_m1_rvalid [i]),
      .s_axi4_ruser  (int_m1_ruser [i]),
      .s_axi4_rready (int_m1_rready [i]),
      .m_axi4_rid    (m1_axi4_rid [i]),
      .m_axi4_rresp  (m1_axi4_rresp [i]),
      .m_axi4_rdata  (m1_axi4_rdata [i]),
      .m_axi4_rlast  (m1_axi4_rlast [i]),
      .m_axi4_rvalid (m1_axi4_rvalid [i]),
      .m_axi4_ruser  (m1_axi4_ruser [i]),
      .m_axi4_rready (m1_axi4_rready [i])
    );   
  
  axi4_r_sender
    #(
      .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH  ),
      .AXI_ID_WIDTH    ( AXI_ID_WIDTH    ),
      .AXI_USER_WIDTH  ( AXI_USER_WIDTH  ),
      .ENABLE_L2TLB    ( ENABLE_L2TLB[i] )
      )
    u_r_sender
    (
      .axi4_aclk     (Clk_CI),
      .axi4_arstn    (Rst_RBI),
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
      .m_axi4_rready (int_rready[i])
    );
  
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

  // }}}

  endgenerate // BUF & SEND }}}

  // Log {{{

  AxiBramLogger
    #(
      .AXI_ID_BITW        (AXI_ID_WIDTH),
      .AXI_ADDR_BITW      (AXI_S_ADDR_WIDTH),
      .NUM_LOG_ENTRIES    (64*1024)
    )
    u_aw_logger
    (
      .Clk_CI           (Clk_CI),
      .TimestampClk_CI  (ClusterClk_CI),
      .Rst_RBI          (Rst_RBI),
      .AxiValid_SI      (s_axi4_awvalid[1]),
      .AxiReady_SI      (s_axi4_awready[1]),
      .AxiId_DI         (s_axi4_awid[1]),
      .AxiAddr_DI       (s_axi4_awaddr[1]),
      .AxiLen_DI        (s_axi4_awlen[1]),
      .Clear_SI         (AwLogClr_SI),
      .Full_SO          (int_aw_log_full),
      .Bram_PS          (AwBram_PS)
    );

  AxiBramLogger
    #(
      .AXI_ID_BITW        (AXI_ID_WIDTH),
      .AXI_ADDR_BITW      (AXI_S_ADDR_WIDTH),
      .NUM_LOG_ENTRIES    (64*1024)
    )
    u_ar_logger
    (
      .Clk_CI           (Clk_CI),
      .TimestampClk_CI  (ClusterClk_CI),
      .Rst_RBI          (Rst_RBI),
      .AxiValid_SI      (s_axi4_arvalid[1]),
      .AxiReady_SI      (s_axi4_arready[1]),
      .AxiId_DI         (s_axi4_arid[1]),
      .AxiAddr_DI       (s_axi4_araddr[1]),
      .AxiLen_DI        (s_axi4_arlen[1]),
      .Clear_SI         (ArLogClr_SI),
      .Full_SO          (int_ar_log_full),
      .Bram_PS          (ArBram_PS)
    );

  // }}}

// RAB Core {{{
// ██████╗  █████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
// ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
// ██████╔╝███████║██████╔╝    ██║     ██║   ██║██████╔╝█████╗  
// ██╔══██╗██╔══██║██╔══██╗    ██║     ██║   ██║██╔══██╗██╔══╝  
// ██║  ██║██║  ██║██████╔╝    ╚██████╗╚██████╔╝██║  ██║███████╗
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
//
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
     .N_PORTS             ( N_PORTS             ), 
     .AXI_DATA_WIDTH      ( AXI_DATA_WIDTH      ),
     .AXI_S_ADDR_WIDTH    ( AXI_S_ADDR_WIDTH    ),
     .AXI_M_ADDR_WIDTH    ( AXI_M_ADDR_WIDTH    ),
     .AXI_LITE_DATA_WIDTH ( AXI_LITE_DATA_WIDTH ),
     .AXI_LITE_ADDR_WIDTH ( AXI_LITE_ADDR_WIDTH ),
     .AXI_ID_WIDTH        ( AXI_ID_WIDTH        ),
     .AXI_USER_WIDTH      ( AXI_USER_WIDTH      )
    )
 u_rab_core
   (
    .Clk_CI              (Clk_CI),
    .Rst_RBI             (Rst_RBI),
    .s_axi_awaddr        (s_axi4lite_awaddr),
    .s_axi_awvalid       (s_axi4lite_awvalid),
    .s_axi_awready       (s_axi4lite_awready),
    .s_axi_wdata         (s_axi4lite_wdata),
    .s_axi_wstrb         (s_axi4lite_wstrb),
    .s_axi_wvalid        (s_axi4lite_wvalid),
    .s_axi_wready        (s_axi4lite_wready),
    .s_axi_bresp         (s_axi4lite_bresp),
    .s_axi_bvalid        (s_axi4lite_bvalid),
    .s_axi_bready        (s_axi4lite_bready),
    .s_axi_araddr        (s_axi4lite_araddr),
    .s_axi_arvalid       (s_axi4lite_arvalid),
    .s_axi_arready       (s_axi4lite_arready),
    .s_axi_rready        (s_axi4lite_rready),
    .s_axi_rdata         (s_axi4lite_rdata),
    .s_axi_rresp         (s_axi4lite_rresp),
    .s_axi_rvalid        (s_axi4lite_rvalid),
    .int_miss            (rab_miss),
    .int_multi           (rab_multi),
    .int_prot            (rab_prot),
    .int_mhr_full        (int_mhr_full),
    .port1_addr          (int_awaddr),
    .port1_id            (int_awid),                                                                                
    .port1_len           (int_awlen),
    .port1_size          (int_awsize),
    .port1_addr_valid    (int_awvalid),
    .port1_type          ('1),
    .port1_ctrl          (int_awuser),
    .port1_sent          (int_wtrans_sent),
    .port1_out_addr      (int_wtrans_addr),
    .port1_master_select (int_wmaster_select),      
    .port1_accept        (int_wtrans_accept),
    .port1_drop          (int_wtrans_drop),
    .port2_addr          (int_araddr),
    .port2_id            (int_arid),
    .port2_len           (int_arlen),
    .port2_size          (int_arsize),
    .port2_addr_valid    (int_arvalid),
    .port2_type          ('0),
    .port2_ctrl          (int_aruser),
    .port2_sent          (int_rtrans_sent),
    .port2_out_addr      (int_rtrans_addr),
    .port2_master_select (int_rmaster_select),      
    .port2_accept        (int_rtrans_accept),
    .port2_drop          (int_rtrans_drop),
    .miss_l2             (miss_l2),     
    .miss_addr_l2        (l2_in_addr_reg),
    .miss_id_l2          (trans_id_l2),  
    .wdata_tlb_l2        (wdata_tlb_l2),
    .waddr_tlb_l2        (waddr_tlb_l2),
    .wren_tlb_l2         (wren_tlb_l2)      
    );
// }}}

// L2 TLB {{{
// ██╗     ██████╗     ████████╗██╗     ██████╗ 
// ██║     ╚════██╗    ╚══██╔══╝██║     ██╔══██╗
// ██║      █████╔╝       ██║   ██║     ██████╔╝
// ██║     ██╔═══╝        ██║   ██║     ██╔══██╗
// ███████╗███████╗       ██║   ███████╗██████╔╝
// ╚══════╝╚══════╝       ╚═╝   ╚══════╝╚═════╝ 
//                                             
/*
 *
 * L2 TLB
 * 
 * Used to translate addresses. Slower than L1(rab_core).
 * L2 TLB is triggered on L1 miss. 
 * Only one translation at a time. If an L1 miss occurs when L2 is busy, it is stalled till the L2 is available.
 * 
 */

  generate for (i = 0; i < N_PORTS; i++) begin 
    if (ENABLE_L2TLB[i] == 1) begin  
      tlb_l2
        #(
          .AXI_S_ADDR_WIDTH       ( AXI_S_ADDR_WIDTH                                           ),   
          .AXI_M_ADDR_WIDTH       ( AXI_M_ADDR_WIDTH                                           ),   
          .AXI_LITE_DATA_WIDTH    ( AXI_LITE_DATA_WIDTH                                        ),   
          .AXI_LITE_ADDR_WIDTH    ( AXI_LITE_ADDR_WIDTH                                        ),
          .SET                    ( L2TLB_NUM_SETS                                             ),
          .NUM_OFFSET             ( L2TLB_NUM_ENTRIES_PER_SET/2/L2TLB_PARALLEL                 ), 
          .PARALLEL_NUM           ( L2TLB_PARALLEL                                             ),
          .HIT_OFFSET_STORE_WIDTH ( log2( (L2TLB_NUM_ENTRIES_PER_SET /2/ L2TLB_PARALLEL) - 1) )
          ) 
      u_tlb_l2
        (
          .clk_i            (Clk_CI),
          .rst_ni           (Rst_RBI),
          .in_addr          (l2_in_addr[i]),
          .rw_type          (l2_rw_type_comb[i]),
          .l1_miss          (l1_miss[i]),
          .we               (wren_tlb_l2[i]),
          .waddr            (waddr_tlb_l2[i]),
          .wdata            (wdata_tlb_l2[i]),
          .l2_trans_sent    (l2_trans_sent[i]),
          .miss_l2          (miss_l2[i]),
          .hit_l2           (hit_l2[i]),
          .multiple_hit_l2  (multi_l2[i]),
          .prot_l2          (prot_l2[i]),
          .l2_busy          (l2_busy[i]),
          .l2_master_select (l2_master_select[i]),
          .out_addr         (l2_out_addr[i])
        );
      
      /*
       *
       * Misc logic
       * 
       * The below logic is used to generate triggers for L2 appropriately.
       * It also stores the required signals if l2 is busy during a rab miss.
       * 
       */
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
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
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
         l1_wtrans_drop[i]         = 1'b0;
         l1_rtrans_drop[i]         = 1'b0;
         l1_multi_or_prot_next[i]  = 1'b0;
         update_id_next[i]         = 1'b0;
         unique case(l2_state[i])
           L2_IDLE : begin
              l2_in_addr[i]        = int_wtrans_drop[i] ? int_awaddr[i] :
                                     int_rtrans_drop[i] ? int_araddr[i] :
                                     0;
              l1_wtrans_drop[i]    = int_wtrans_drop[i];
              l1_rtrans_drop[i]    = int_rtrans_drop[i];
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
                 l2_next_state[i]  = L2_BUSY;
                 l1_miss[i]        = 1'b1;
                 l1_wtrans_drop[i] = l1_wtrans_drop_saved[i];
                 l1_rtrans_drop[i] = l1_rtrans_drop_saved[i];
                 update_id_next[i] = 1'b1;
              end
              l2_in_addr[i] = l1_wtrans_drop_saved[i] ? int_awaddr[i] :
                              l1_rtrans_drop_saved[i] ? int_araddr[i] :
                              0;
           end           
  
           L1_MULTI_PROT_WAITING : begin            
              if (~l2_busy[i]) begin
                 l2_next_state[i]  = L1_MULTI_PROT;
                 l1_wtrans_drop[i] = l1_wtrans_drop_saved[i];
                 l1_rtrans_drop[i] = l1_rtrans_drop_saved[i];
                 update_id_next[i] = 1'b1;
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
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            update_id[i] <= 1'b0;
         end else begin
            update_id[i] <= update_id_next[i];
         end
      end
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            l2_awid[i] <= 0;
            l2_arid[i] <= 0;            
         end else if (update_id) begin
            l2_awid[i] <= int_awid_d[i];
            l2_arid[i] <= int_arid_d[i];
         end
      end // always_ff @ (posedge Clk_CI)     
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            int_awid_d[i] <= 0;
            int_arid_d[i] <= 0;            
         end else begin
            int_awid_d[i] <= int_awid[i];
            int_arid_d[i] <= int_arid[i];
         end
      end // always_ff @ (posedge Clk_CI)             
      
      // Save drop status in flipflop
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
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
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            l1_multi_or_prot[i] <= 1'b0;
         end else begin
            l1_multi_or_prot[i] <= l1_multi_or_prot_next[i];
         end
      end // always_ff @ (posedge Clk_CI)
      
      // Read/Write
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            l2_rw_type[i] <= 1'b0;
         end else if (l1_wtrans_drop[i] || l1_rtrans_drop[i]) begin
            l2_rw_type[i] <= l1_wtrans_drop[i]; //write=1, read=0
         end
      end
      assign l2_rw_type_comb[i] = l1_wtrans_drop[i];
  
      // Store the l2 input address to write into MHR in case of miss.
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            l2_in_addr_reg[i] <= 0;
         end else if (l1_miss[i]) begin
            l2_in_addr_reg[i] <= l2_in_addr[i];
         end
      end      
      
      // In case of simultaneous L1 and L2 prot/multi, int_<prot/multi> needs to be asserted twice.
      assign double_prot_en[i]  = prot_l2[i]  && rab_prot[i];
      assign double_multi_en[i] = multi_l2[i] && rab_multi[i];
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
            double_prot[i]  <= 1'b0;
            double_multi[i] <= 1'b0;
         end else begin
            double_prot[i]  <= double_prot_en[i];
            double_multi[i] <= double_multi_en[i];
         end
      end
      assign int_prot_next[i]  = prot_l2[i]  || rab_prot[i]  || double_prot[i];
      assign int_multi_next[i] = multi_l2[i] || rab_multi[i] || double_multi[i]; 
      always_ff @(posedge Clk_CI) begin
         if (Rst_RBI == 0) begin
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
   
      assign miss_l2[i]          = 1'b0;
      assign l2_in_addr_reg[i]   = 0;

      assign l2_busy[i]          = 1'b0;
      assign l2_wtrans_accept[i] = 1'b0;
      assign l2_rtrans_accept[i] = 1'b0;
      assign l2_wtrans_drop[i]   = 1'b0;
      assign l2_rtrans_drop[i]   = 1'b0;
      assign l2_wtrans_addr[i]   = 0;
      assign l2_rtrans_addr[i]   = 0;
      assign trans_id_l2[i]      = 0;
      assign l2_master_select[i] = 1'b0;
      
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

// }}}

endmodule

// vim: ts=2 sw=2 sts=2 et nosmartindent autoindent foldmethod=marker

// ========================================================================== //
//                           COPYRIGHT NOTICE                                 //
// Copyright (C) 2017 ETH Zurich, University of Bologna                       //
// All rights reserved.                                                       //
//                                                                            //
// This code is under development and not yet released to the public.         //
// Until it is released, the code is under the copyright of ETH Zurich and    //
// the University of Bologna, and may contain confidential and/or unpublished //
// work. Any reuse/redistribution is strictly forbidden without written       //
// permission from ETH Zurich.                                                //
//                                                                            //
// Bug fixes and contributions will eventually be released under the          //
// SolderPad open hardware license in the context of the PULP platform        //
// (http://www.pulp-platform.org), under the copyright of ETH Zurich and the  //
// University of Bologna.                                                     //
//                                                                            //
// ========================================================================== //

// ============================================================================= //
// Company:        Multitherman Laboratory @ DEIS - University of Bologna        //
//                    Viale Risorgimento 2 40136                                 //
//                    Bologna - fax 0512093785 -                                 //
//                                                                               //
// Engineer:       Davide Rossi - davide.rossi@unibo.it                          //
//                                                                               //
//                                                                               //
// Additional contributions by:                                                  //
//                                                                               //
//                                                                               //
//                                                                               //
// Create Date:    01/02/2014                                                    //
// Design Name:    AXI 4 Verification IP                                         //
// Module Name:    TGEN_AXI_LITE                                                 //
// Project Name:   PULP                                                          //
// Language:       SystemVerilog                                                 //
//                                                                               //
// Description:    AXI LITE Traffic generator                                    //
//                                                                               //
// Revision:                                                                     //
// Revision v0.1 - 01/02/2014 : File Created                                     //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
//                                                                               //
// ============================================================================= //

`timescale 1ns/1ps
`define SOD 0.1


module TGEN_AXI_LITE_wrap 
#( 
      parameter AXI_ADDRESS_WIDTH = 32,
      parameter AXI_RDATA_WIDTH   = 32,
      parameter AXI_WDATA_WIDTH   = 32,
      parameter SRC_ID            = 0
)
(
    input  logic                  clk,
    input  logic                  rst_n,

    AXI_LITE_BUS.Master           cfg_port_master
);


TGEN_AXI_LITE 
#( 
      .AXI_ADDRESS_WIDTH ( AXI_ADDRESS_WIDTH ),
      .AXI_RDATA_WIDTH   ( AXI_RDATA_WIDTH   ),
      .AXI_WDATA_WIDTH   ( AXI_WDATA_WIDTH   ),
      .SRC_ID            ( SRC_ID            )
)
i_TGEN_AXI_LITE
(
    .clk       ( clk                         ),
    .rst_n     ( rst_n                       ),

    // ADDRESS WRITE CHANNEL
    .awaddr_o  ( cfg_port_master.awaddr      ),
    .awvalid_o ( cfg_port_master.awvalid     ),
    .awready_i ( cfg_port_master.awready     ),

    // ADDRESS READ CHANNEL
    .araddr_o  ( cfg_port_master.araddr      ),
    .arvalid_o ( cfg_port_master.arvalid     ),
    .arready_i ( cfg_port_master.arready     ),

    // ADDRESS WRITE CHANNEL
    .wdata_o   ( cfg_port_master.wdata       ),
    .wstrb_o   ( cfg_port_master.wstrb       ),
    .wvalid_o  ( cfg_port_master.wvalid      ),
    .wready_i  ( cfg_port_master.wready      ),

    // Backward write response
    .bready_o  ( cfg_port_master.bready      ),
    .bresp_i   ( cfg_port_master.bresp       ),
    .bvalid_i  ( cfg_port_master.bvalid      ),

     // RESPONSE READ CHANNEL
    .rdata_i   ( cfg_port_master.rdata       ),
    .rvalid_i  ( cfg_port_master.rvalid      ),
    .rready_o  ( cfg_port_master.rready      ),
    .rresp_i   ( cfg_port_master.rresp       )
);

endmodule
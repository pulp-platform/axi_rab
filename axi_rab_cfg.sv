// --=========================================================================--
// 
//  █████╗ ██╗  ██╗██╗    ██████╗  █████╗ ██████╗      ██████╗███████╗ ██████╗ 
// ██╔══██╗╚██╗██╔╝██║    ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██╔════╝██╔════╝ 
// ███████║ ╚███╔╝ ██║    ██████╔╝███████║██████╔╝    ██║     █████╗  ██║  ███╗
// ██╔══██║ ██╔██╗ ██║    ██╔══██╗██╔══██║██╔══██╗    ██║     ██╔══╝  ██║   ██║
// ██║  ██║██╔╝ ██╗██║    ██║  ██║██║  ██║██████╔╝    ╚██████╗██║     ╚██████╔╝
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝      ╚═════╝╚═╝      ╚═════╝ 
//
// 
// Author: Pirmin Vogel - vogelpi@iis.ee.ethz.ch
// 
// Purpose : AXI4-Lite configuration and miss handling interface for RAB
// 
// --=========================================================================--                                                                                                                  

`define log2(VALUE) ( (VALUE) == ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE)< (8) ? 3:(VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11: (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 :  (VALUE) < ( 1048576 ) ? 20 : -1)

module axi_rab_cfg
  #( 
    parameter N_PORTS         = 3,
    parameter N_REGS          = 196,
    parameter ADDR_WIDTH_PHYS = 40,
    parameter ADDR_WIDTH_VIRT = 32,
    parameter N_FLAGS         = 4,
    parameter AXI_DATA_WIDTH  = 64,
    parameter AXI_ADDR_WIDTH  = 32,
    parameter MISS_ID_WIDTH   = 10  // <= FIFO_WIDTH
    )
   (
    input  logic                                    Clk_CI,
    input  logic                                    Rst_RBI,

    // AXI Lite interface   
    input  logic [AXI_ADDR_WIDTH-1:0]               s_axi_awaddr,
    input  logic                                    s_axi_awvalid,
    output logic                                    s_axi_awready,
    input  logic [AXI_DATA_WIDTH/8-1:0][7:0]        s_axi_wdata,
    input  logic [AXI_DATA_WIDTH/8-1:0]             s_axi_wstrb,
    input  logic                                    s_axi_wvalid,
    output logic                                    s_axi_wready,
    output logic [1:0]                              s_axi_bresp,
    output logic                                    s_axi_bvalid,
    input  logic                                    s_axi_bready,
    input  logic [AXI_ADDR_WIDTH-1:0]               s_axi_araddr,
    input  logic                                    s_axi_arvalid,
    output logic                                    s_axi_arready,
    output logic [AXI_DATA_WIDTH-1:0]               s_axi_rdata,
    output logic [1:0]                              s_axi_rresp,
    output logic                                    s_axi_rvalid,
    input  logic                                    s_axi_rready,
           
    // Slice configuration       
    output logic [N_REGS-1:0][63:0]                 L1Cfg_DO,
        
    // Miss handling       
    input  logic [ADDR_WIDTH_VIRT-1:0]              MissAddr_DI,
    input  logic [MISS_ID_WIDTH-1:0]                MissId_DI,
    input  logic                                    Miss_SI,
    output logic                                    MhFifoFull_SO,

    // L2 TLB
    output logic [N_PORTS-1:0] [AXI_DATA_WIDTH-1:0] wdata_l2,
    output logic [N_PORTS-1:0] [AXI_ADDR_WIDTH-1:0] waddr_l2,
    output logic [N_PORTS-1:0]                      wren_l2
  );

  localparam ADDR_LSB = 3;
  localparam ADDR_MSB = `log2(N_REGS-1)+ADDR_LSB;
  
  localparam L2SINGLE_AMAP_SIZE = 16'h4000; // Maximum 2048 TLB entries in L2

  logic [AXI_DATA_WIDTH/8-1:0][7:0] L1Cfg_DP[N_REGS]; // [Byte][Bit]
  genvar j;

  //  █████╗ ██╗  ██╗██╗██╗  ██╗      ██╗     ██╗████████╗███████╗
  // ██╔══██╗╚██╗██╔╝██║██║  ██║      ██║     ██║╚══██╔══╝██╔════╝
  // ███████║ ╚███╔╝ ██║███████║█████╗██║     ██║   ██║   █████╗  
  // ██╔══██║ ██╔██╗ ██║╚════██║╚════╝██║     ██║   ██║   ██╔══╝  
  // ██║  ██║██╔╝ ██╗██║     ██║      ███████╗██║   ██║   ███████╗
  // ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝      ╚══════╝╚═╝   ╚═╝   ╚══════╝
  //    
  logic [AXI_ADDR_WIDTH-1:0]        awaddr_reg;
  logic                             awaddr_done_rise;
  logic                             awaddr_done_reg;
  logic                             awaddr_done_reg_dly;

  logic [AXI_DATA_WIDTH/8-1:0][7:0] wdata_reg;
  logic [AXI_DATA_WIDTH/8-1:0]      wstrb_reg;
  logic                             wdata_done_rise;
  logic                             wdata_done_reg;
  logic                             wdata_done_reg_dly;
  
  logic                             wresp_done_reg;
  logic                             wresp_running_reg;

  logic [AXI_ADDR_WIDTH-1:0]        araddr_reg;   
  logic                             araddr_done_reg;
  
  logic [AXI_DATA_WIDTH-1:0]        rdata_reg;
  logic                             rresp_done_reg;
  logic                             rresp_running_reg;
  
  logic                             awready;
  logic                             wready;
  logic                             bvalid;
  
  logic                             arready;
  logic                             rvalid;
  
  logic                             wren;
  logic                             wren_l1;
 
  assign wren = ( wdata_done_rise & awaddr_done_reg ) | ( awaddr_done_rise & wdata_done_reg );
  assign wdata_done_rise  = wdata_done_reg  & ~wdata_done_reg_dly;
  assign awaddr_done_rise = awaddr_done_reg & ~awaddr_done_reg_dly;
  
  // reg_dly
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            wdata_done_reg_dly  <= 1'b0;
            awaddr_done_reg_dly <= 1'b0;
         end
       else
         begin
            wdata_done_reg_dly  <= wdata_done_reg;
            awaddr_done_reg_dly <= awaddr_done_reg;
         end
    end
  
  // AW Channel
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            awaddr_done_reg <= 1'b0;
            awaddr_reg      <= '0;
            awready         <= 1'b1;
         end
       else
         begin
            if (awready && s_axi_awvalid)
              begin
                 awready         <= 1'b0;
                 awaddr_done_reg <= 1'b1;
                 awaddr_reg      <= s_axi_awaddr;
              end
            else if (awaddr_done_reg && wresp_done_reg)
              begin
                 awready         <= 1'b1;
                 awaddr_done_reg <= 1'b0;
              end
         end
    end

  // W Channel
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            wdata_done_reg <= 1'b0;
            wready         <= 1'b1;
            wdata_reg      <= '0;
            wstrb_reg      <= '0;
         end
       else
         begin
            if (wready && s_axi_wvalid)
              begin
                 wready         <= 1'b0;
                 wdata_done_reg <= 1'b1;
                 wdata_reg      <= s_axi_wdata;
                 wstrb_reg      <= s_axi_wstrb;
              end
            else if (wdata_done_reg && wresp_done_reg)
              begin
                 wready         <= 1'b1;
                 wdata_done_reg <= 1'b0;
              end
         end
    end

  // B Channel
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            bvalid            <= 1'b0;
            wresp_done_reg    <= 1'b0;
            wresp_running_reg <= 1'b0;
         end
       else
         begin
            if (awaddr_done_reg && wdata_done_reg && !wresp_done_reg)
              begin
                 if (!wresp_running_reg)
                   begin
                      bvalid            <= 1'b1;
                      wresp_running_reg <= 1'b1;
                   end
                 else if (s_axi_bready)
                   begin
                      bvalid            <= 1'b0;
                      wresp_done_reg    <= 1'b1;
                      wresp_running_reg <= 1'b0;
                   end
              end
            else
              begin
                 bvalid            <= 1'b0;
                 wresp_done_reg    <= 1'b0;
                 wresp_running_reg <= 1'b0;
              end
         end
    end

  // AR Channel
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            araddr_done_reg <= 1'b0;
            arready         <= 1'b1;
            araddr_reg       <= '0;
         end
       else
         begin
            if (arready && s_axi_arvalid)
              begin
                 arready         <= 1'b0;
                 araddr_done_reg <= 1'b1;
                 araddr_reg      <= s_axi_araddr;
              end
            else if (araddr_done_reg && rresp_done_reg)
              begin
                 arready         <= 1'b1;
                 araddr_done_reg <= 1'b0;
              end
         end
    end

  // R Channel
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
       if (!Rst_RBI)
         begin
            rresp_done_reg    <= 1'b0;
            rvalid            <= 1'b0;
            rresp_running_reg <= 1'b0;
         end
       else
         begin
            if (araddr_done_reg && !rresp_done_reg)
              begin
                 if (!rresp_running_reg)
                   begin
                      rvalid            <= 1'b1;
                      rresp_running_reg <= 1'b1;
                   end
                 else if (s_axi_rready)
                   begin
                      rvalid            <= 1'b0;
                      rresp_done_reg    <= 1'b1;
                      rresp_running_reg <= 1'b0;
                   end
              end
            else
              begin
                 rvalid            <= 1'b0;
                 rresp_done_reg    <= 1'b0;
                 rresp_running_reg <= 1'b0;
              end
         end
    end
  
  // ██╗     ██╗     ██████╗███████╗ ██████╗     ██████╗ ███████╗ ██████╗ 
  // ██║    ███║    ██╔════╝██╔════╝██╔════╝     ██╔══██╗██╔════╝██╔════╝ 
  // ██║    ╚██║    ██║     █████╗  ██║  ███╗    ██████╔╝█████╗  ██║  ███╗
  // ██║     ██║    ██║     ██╔══╝  ██║   ██║    ██╔══██╗██╔══╝  ██║   ██║
  // ███████╗██║    ╚██████╗██║     ╚██████╔╝    ██║  ██║███████╗╚██████╔╝
  // ╚══════╝╚═╝     ╚═════╝╚═╝      ╚═════╝     ╚═╝  ╚═╝╚══════╝ ╚═════╝ 
  //                                                                          
  assign wren_l1 = wren && (awaddr_reg < L2SINGLE_AMAP_SIZE);

  always @( posedge Clk_CI or negedge Rst_RBI )   
    begin
      var integer idx_reg, idx_byte;
      if ( Rst_RBI == 1'b0 )
        begin
          for ( idx_reg = 0; idx_reg < N_REGS; idx_reg++ )
            L1Cfg_DP[idx_reg] <= '0;
        end
      else if ( wren_l1 )
          begin
            // Mask unused bits -> Synthesizer should optimize away unused registers
            if ( awaddr_reg[ADDR_LSB+1] == 1'b0 ) begin // VIRT_ADDR
              for ( idx_byte = 0; idx_byte < ADDR_WIDTH_VIRT/8; idx_byte++ )
                if ( wstrb_reg[idx_byte] )
                  L1Cfg_DP[awaddr_reg[ADDR_MSB:ADDR_LSB]][idx_byte] <= wdata_reg[idx_byte];
              end
            else if ( awaddr_reg[ADDR_LSB+1:ADDR_LSB] == 2'b10 ) begin // PHYS_ADDR
              for ( idx_byte = 0; idx_byte < ADDR_WIDTH_PHYS/8; idx_byte++ )
                if ( wstrb_reg[idx_byte] )
                  L1Cfg_DP[awaddr_reg[ADDR_MSB:ADDR_LSB]][idx_byte] <= wdata_reg[idx_byte];
              end
            else begin // ( awaddr_reg[ADDR_LSB+1:ADDR_LSB] == 2'b11 ) // FLAGS
              if ( wstrb_reg[0] )
                  L1Cfg_DP[awaddr_reg[ADDR_MSB:ADDR_LSB]][0] <= wdata_reg[0] & { {{8-N_FLAGS}{1'b0}}, {{N_FLAGS}{1'b1}} };
              end
          end
    end // always @ ( posedge Clk_CI or negedge Rst_RBI )

  assign rdata_reg = L1Cfg_DP[araddr_reg[ADDR_MSB:ADDR_LSB]];

  generate
     for( j=0; j<N_REGS; j++ )
        assign L1Cfg_DO[j] = L1Cfg_DP[j];
  endgenerate

  assign s_axi_awready = awready;
  assign s_axi_wready  = wready;

  assign s_axi_bresp   = 2'b00;
  assign s_axi_bvalid  = bvalid;

  assign s_axi_arready = arready;
  assign s_axi_rresp   = 2'b00;
  assign s_axi_rvalid  = rvalid;

  // ██╗     ██████╗      ██████╗███████╗ ██████╗ 
  // ██║     ╚════██╗    ██╔════╝██╔════╝██╔════╝ 
  // ██║      █████╔╝    ██║     █████╗  ██║  ███╗
  // ██║     ██╔═══╝     ██║     ██╔══╝  ██║   ██║
  // ███████╗███████╗    ╚██████╗██║     ╚██████╔╝
  // ╚══════╝╚══════╝     ╚═════╝╚═╝      ╚═════╝ 
  //                                              
  generate
    for( j=0; j< N_PORTS; j++)
      begin
        always @( posedge Clk_CI or negedge Rst_RBI )   
          begin
            var integer idx_byte;
            if ( Rst_RBI == 1'b0 )
              begin
                wren_l2[j]  <= 1'b0;
                wdata_l2[j] <= '0;
              end
            else if (wren)
              begin
                if ( (awaddr_reg >= (j+1)*L2SINGLE_AMAP_SIZE) && (awaddr_reg < (j+2)*L2SINGLE_AMAP_SIZE) )
                  wren_l2[j] <= 1'b1;
                for ( idx_byte = 0; idx_byte < AXI_DATA_WIDTH/8; idx_byte++ )
                  if ( wstrb_reg[idx_byte] )
                    wdata_l2[j][idx_byte*8 +: 8] <= wdata_reg[idx_byte];
              end
            else
              wren_l2[j] <= 0;
          end // always @ ( posedge Clk_CI or negedge Rst_RBI )
    
      assign waddr_l2[j] = (awaddr_reg -(j+1)*L2SINGLE_AMAP_SIZE)/4;      
      
      end // for (j=0; j< N_PORTS; j++)
   endgenerate

  // ███╗   ███╗██╗  ██╗    ███████╗██╗███████╗ ██████╗ ███████╗
  // ████╗ ████║██║  ██║    ██╔════╝██║██╔════╝██╔═══██╗██╔════╝
  // ██╔████╔██║███████║    █████╗  ██║█████╗  ██║   ██║███████╗
  // ██║╚██╔╝██║██╔══██║    ██╔══╝  ██║██╔══╝  ██║   ██║╚════██║
  // ██║ ╚═╝ ██║██║  ██║    ██║     ██║██║     ╚██████╔╝███████║
  // ╚═╝     ╚═╝╚═╝  ╚═╝    ╚═╝     ╚═╝╚═╝      ╚═════╝ ╚══════╝
  //                                                                    
  logic [ADDR_WIDTH_VIRT-1:0] AddrFifoDin_D;
  logic                       AddrFifoWen_S;
  logic                       AddrFifoRen_S;               
  logic [ADDR_WIDTH_VIRT-1:0] AddrFifoDout_D;
  logic                       AddrFifoFull_S;
  logic                       AddrFifoEmpty_S;
  
  logic [MISS_ID_WIDTH-1:0] IdFifoDin_D;
  logic                     IdFifoWen_S;
  logic                     IdFifoRen_S;               
  logic [MISS_ID_WIDTH-1:0] IdFifoDout_D;
  logic                     IdFifoFull_S;
  logic                     IdFifoEmpty_S;

  logic [AXI_DATA_WIDTH-1:0] wdata_reg_vec;
  
  assign MhFifoFull_SO = (AddrFifoWen_S & AddrFifoFull_S) | (IdFifoWen_S & IdFifoFull_S);
  
  generate
     for ( j=0; j<AXI_DATA_WIDTH/8; j++ )
       assign wdata_reg_vec[(j+1)*8-1:j*8] = wdata_reg[j];
  endgenerate
  
  // write Address FIFO
  always_comb
    begin
       AddrFifoWen_S = 1'b0;
       AddrFifoDin_D = 'b0;
       if ( Miss_SI == 1'b1 ) // register a new miss
         begin
            AddrFifoWen_S = 1'b1;
            AddrFifoDin_D = MissAddr_DI;
         end
       else if ( (wren_l1 == 1'b1) && (awaddr_reg[ADDR_MSB-1:0] == '0) ) // write request from AXI interface
         begin
            AddrFifoWen_S = 1'b1;
            AddrFifoDin_D = wdata_reg_vec[ADDR_WIDTH_VIRT-1:0];
         end
    end
  
  // write ID FIFO
  always_comb
    begin
       IdFifoWen_S = 1'b0;
       IdFifoDin_D = 'b0;
       if ( Miss_SI == 1'b1 ) // register a new miss
         begin
            IdFifoWen_S                    = 1'b1;
            IdFifoDin_D[MISS_ID_WIDTH-1:0] = MissId_DI;
         end
       else if ( (wren_l1 == 1'b1) && (awaddr_reg == 4'h8) ) // write request from AXI interface
         begin
            IdFifoWen_S = 1'b1;
            IdFifoDin_D = wdata_reg_vec[MISS_ID_WIDTH-1:0];
         end
    end
  
  // AXI read data
  always_comb
    begin
       s_axi_rdata   = rdata_reg; // read L1 config
       AddrFifoRen_S = 1'b0;
       IdFifoRen_S   = 1'b0;
       if ( rvalid == 1'b1 )
         begin
            // read Addr FIFO
            if ( araddr_reg[ADDR_MSB-1:0] == 'b0 )
              begin
                s_axi_rdata[AXI_DATA_WIDTH-1]                                = AddrFifoEmpty_S;
                s_axi_rdata[AXI_DATA_WIDTH-2:AXI_DATA_WIDTH-ADDR_WIDTH_VIRT] = 'b0;
                s_axi_rdata[ADDR_WIDTH_VIRT-1:0]                             = AddrFifoDout_D;
                if ( AddrFifoEmpty_S == 1'b0 )
                  AddrFifoRen_S <= 1'b1;
              end
            // read Id FIFO
            else if ( araddr_reg[ADDR_MSB-1:0] == 'h4 )
              begin
                s_axi_rdata[AXI_DATA_WIDTH-1]               = IdFifoEmpty_S;
                s_axi_rdata[AXI_DATA_WIDTH-2:MISS_ID_WIDTH] = 'b0;
                s_axi_rdata[MISS_ID_WIDTH-1:0]              = IdFifoDout_D;
                if ( IdFifoEmpty_S == 1'b0 )
                  IdFifoRen_S <= 1'b1;                  
              end
         end // if ( rvalid == 1'b1 )
    end // always_comb begin
     
  xilinx_fifo_rab_mh_addr xilinx_fifo_addr_i
    (
     .clk  (Clk_CI     ), 
     .rst  (~Rst_RBI ), 
     .din  (AddrFifoDin_D  ),
     .wr_en(AddrFifoWen_S & ~AddrFifoFull_S),
     .rd_en(AddrFifoRen_S  ),
     .dout (AddrFifoDout_D ),
     .full (AddrFifoFull_S ),
     .empty(AddrFifoEmpty_S)
     );
  
  xilinx_fifo_rab_mh_id xilinx_fifo_id_i
    (
     .clk  (Clk_CI    ), 
     .rst  (~Rst_RBI), 
     .din  (IdFifoDin_D   ),
     .wr_en(IdFifoWen_S & ~IdFifoFull_S),
     .rd_en(IdFifoRen_S   ),
     .dout (IdFifoDout_D  ),
     .full (IdFifoFull_S  ),
     .empty(IdFifoEmpty_S )
     );
   
endmodule

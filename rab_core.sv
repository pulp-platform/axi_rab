// --=========================================================================--
//
// ██████╗  █████╗ ██████╗      ██████╗ ██████╗ ██████╗ ███████╗
// ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██╔═══██╗██╔══██╗██╔════╝
// ██████╔╝███████║██████╔╝    ██║     ██║   ██║██████╔╝█████╗  
// ██╔══██╗██╔══██║██╔══██╗    ██║     ██║   ██║██╔══██╗██╔══╝  
// ██║  ██║██║  ██║██████╔╝    ╚██████╗╚██████╔╝██║  ██║███████╗
// ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝      ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝
// 
// --=========================================================================-- 

`include "ulpsoc_defines.sv"
`define log2(VALUE) ( (VALUE) == ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE)< (8) ? 3:(VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11: (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 :  (VALUE) < ( 1048576 ) ? 20 : -1)

`define MY_ARRAY_SUM(MY_ARRAY,ARRAY_SIZE) ( (ARRAY_SIZE==1) ? MY_ARRAY[0] : (ARRAY_SIZE==2) ? MY_ARRAY[0] + MY_ARRAY[1] : (ARRAY_SIZE==3) ? MY_ARRAY[0] + MY_ARRAY[1] + MY_ARRAY[2] : (ARRAY_SIZE==4) ? MY_ARRAY[0] + MY_ARRAY[1] + MY_ARRAY[2] + MY_ARRAY[3] : 0 )

module rab_core
  #(
    parameter N_PORTS             = 3,
    parameter AXI_DATA_WIDTH      = 64,
    parameter AXI_S_ADDR_WIDTH    = 32,
    parameter AXI_M_ADDR_WIDTH    = 40,
    parameter AXI_LITE_DATA_WIDTH = 64,
    parameter AXI_LITE_ADDR_WIDTH = 32,
    parameter AXI_ID_WIDTH        = 8,
    parameter AXI_USER_WIDTH      = 6
    )
   (
    input  logic                                         Clk_CI,
    input  logic                                         Rst_RBI,

    input  logic               [AXI_LITE_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  logic                                         s_axi_awvalid,
    output logic                                         s_axi_awready,

    input  logic               [AXI_LITE_DATA_WIDTH-1:0] s_axi_wdata,
    input  logic             [AXI_LITE_DATA_WIDTH/8-1:0] s_axi_wstrb,
    input  logic                                         s_axi_wvalid,
    output logic                                         s_axi_wready,

    input  logic               [AXI_LITE_ADDR_WIDTH-1:0] s_axi_araddr,
    input  logic                                         s_axi_arvalid,
    output logic                                         s_axi_arready,

    input  logic                                         s_axi_rready,
    output logic               [AXI_LITE_DATA_WIDTH-1:0] s_axi_rdata,
    output logic                                   [1:0] s_axi_rresp,
    output logic                                         s_axi_rvalid,

    output logic                                   [1:0] s_axi_bresp,
    output logic                                         s_axi_bvalid,
    input  logic                                         s_axi_bready,
         
    output logic [N_PORTS-1:0]                           int_miss,
    output logic [N_PORTS-1:0]                           int_prot,
    output logic [N_PORTS-1:0]                           int_multi,
    output logic                                         int_mhr_full, 
 
    input  logic [N_PORTS-1:0]    [AXI_S_ADDR_WIDTH-1:0] port1_addr,
    input  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] port1_id,
    input  logic [N_PORTS-1:0]                     [7:0] port1_len,
    input  logic [N_PORTS-1:0]                     [2:0] port1_size,
    input  logic [N_PORTS-1:0]                           port1_addr_valid,
    input  logic [N_PORTS-1:0]                           port1_type,
    input  logic [N_PORTS-1:0]      [AXI_USER_WIDTH-1:0] port1_ctrl,
    input  logic [N_PORTS-1:0]                           port1_sent,
    output logic [N_PORTS-1:0]    [AXI_M_ADDR_WIDTH-1:0] port1_out_addr,
    output logic [N_PORTS-1:0]                           port1_master_select,
    output logic [N_PORTS-1:0]                           port1_accept,
    output logic [N_PORTS-1:0]                           port1_drop,
 
    input  logic [N_PORTS-1:0]    [AXI_S_ADDR_WIDTH-1:0] port2_addr,
    input  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] port2_id,
    input  logic [N_PORTS-1:0]                     [7:0] port2_len,
    input  logic [N_PORTS-1:0]                     [2:0] port2_size,
    input  logic [N_PORTS-1:0]                           port2_addr_valid,
    input  logic [N_PORTS-1:0]                           port2_type,
    input  logic [N_PORTS-1:0]      [AXI_USER_WIDTH-1:0] port2_ctrl,
    input  logic [N_PORTS-1:0]                           port2_sent,
    output logic [N_PORTS-1:0]    [AXI_M_ADDR_WIDTH-1:0] port2_out_addr,
    output logic [N_PORTS-1:0]                           port2_master_select,
    output logic [N_PORTS-1:0]                           port2_accept,
    output logic [N_PORTS-1:0]                           port2_drop,
 
    input  logic [N_PORTS-1:0]                           miss_l2,
    input  logic [N_PORTS-1:0]                    [31:0] miss_addr_l2,
    input  logic [N_PORTS-1:0]        [AXI_ID_WIDTH-1:0] miss_id_l2,  

    output logic [N_PORTS-1:0] [AXI_LITE_DATA_WIDTH-1:0] wdata_tlb_l2,
    output logic [N_PORTS-1:0] [AXI_LITE_ADDR_WIDTH-1:0] waddr_tlb_l2,
    output logic [N_PORTS-1:0]                           wren_tlb_l2      
    );

  // ███████╗██╗ ██████╗ ███╗   ██╗ █████╗ ██╗     ███████╗
  // ██╔════╝██║██╔════╝ ████╗  ██║██╔══██╗██║     ██╔════╝
  // ███████╗██║██║  ███╗██╔██╗ ██║███████║██║     ███████╗
  // ╚════██║██║██║   ██║██║╚██╗██║██╔══██║██║     ╚════██║
  // ███████║██║╚██████╔╝██║ ╚████║██║  ██║███████╗███████║
  // ╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝╚══════╝╚══════╝
  //

  localparam integer ENABLE_L2TLB[N_PORTS-1:0] = `EN_L2TLB_ARRAY;

  localparam integer N_SLICES[N_PORTS-1:0]     = `N_SLICES_ARRAY;
  localparam         N_SLICES_TOT              = `MY_ARRAY_SUM(N_SLICES,N_PORTS);
  localparam         N_SLICES_MAX              = `N_SLICES_MAX;
  
  localparam N_REGS                            = 4*N_SLICES_TOT + 4;
  localparam AXI_SIZE_WIDTH                    = `log2(AXI_DATA_WIDTH/8-1);

  localparam PORT_ID_WIDTH                     = (N_PORTS < 3) ? 1 : `log2(N_PORTS-1);
  
  logic [N_PORTS-1:0]                      [15:0] p1_burst_size;
  logic [N_PORTS-1:0]                      [15:0] p2_burst_size;
    
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] p1_align_addr;
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] p2_align_addr;
    
  logic [N_PORTS-1:0]        [AXI_SIZE_WIDTH-1:0] p1_mask;
  logic [N_PORTS-1:0]        [AXI_SIZE_WIDTH-1:0] p2_mask;
      
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] p1_max_addr;
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] p2_max_addr;
     
  logic [N_PORTS-1:0]                             p1_skip;
  logic [N_PORTS-1:0]                             p2_skip;
      
  logic [N_PORTS-1:0]                             int_rw;   
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] int_addr_min;
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] int_addr_max;
  logic [N_PORTS-1:0]          [AXI_ID_WIDTH-1:0] int_id;
       
  logic [N_PORTS-1:0]                             no_hit;
  logic [N_PORTS-1:0]                             no_prot;
    
  logic [N_PORTS-1:0]          [N_SLICES_MAX-1:0] hit;
  logic [N_PORTS-1:0]          [N_SLICES_MAX-1:0] prot;
      
  logic [N_PORTS-1:0]      [AXI_M_ADDR_WIDTH-1:0] out_addr;
  logic [N_PORTS-1:0]      [AXI_M_ADDR_WIDTH-1:0] out_addr_reg;
      
  logic [N_PORTS-1:0]                             master_select;
  logic [N_PORTS-1:0]                             master_select_reg;
     
  logic [N_PORTS-1:0]                             select;
  reg   [N_PORTS-1:0]                             curr_priority;
     
  reg   [N_PORTS-1:0]                             multiple_hit;
     
  logic [N_PORTS-1:0]                             miss_valid_mhr;
  logic [N_PORTS-1:0]      [AXI_S_ADDR_WIDTH-1:0] miss_addr_mhr;
  logic [N_PORTS-1:0]          [AXI_ID_WIDTH-1:0] miss_id_mhr;

  logic [N_REGS-1:0]                       [63:0] int_cfg_regs; 
  logic [N_PORTS-1:0] [4*N_SLICES_MAX-1:0] [63:0] int_cfg_regs_slices; 

  genvar z;

  //  █████╗ ███████╗███████╗██╗ ██████╗ ███╗   ██╗███╗   ███╗███████╗███╗   ██╗████████╗███████╗
  // ██╔══██╗██╔════╝██╔════╝██║██╔════╝ ████╗  ██║████╗ ████║██╔════╝████╗  ██║╚══██╔══╝██╔════╝
  // ███████║███████╗███████╗██║██║  ███╗██╔██╗ ██║██╔████╔██║█████╗  ██╔██╗ ██║   ██║   ███████╗
  // ██╔══██║╚════██║╚════██║██║██║   ██║██║╚██╗██║██║╚██╔╝██║██╔══╝  ██║╚██╗██║   ██║   ╚════██║
  // ██║  ██║███████║███████║██║╚██████╔╝██║ ╚████║██║ ╚═╝ ██║███████╗██║ ╚████║   ██║   ███████║
  // ╚═╝  ╚═╝╚══════╝╚══════╝╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝     ╚═╝╚══════╝╚═╝  ╚═══╝   ╚═╝   ╚══════╝
  //

  always_comb
    begin
      var integer idx;
  
      for (idx=0; idx<N_PORTS; idx++) begin

        // select = 1 -> port1 active
        // select = 0 -> port2 active
        select[idx] = (curr_priority[idx] & port1_addr_valid[idx]) | ~port2_addr_valid[idx];
        
        p1_burst_size[idx] = (port1_len[idx] + 1) << port1_size[idx];
        p2_burst_size[idx] = (port2_len[idx] + 1) << port2_size[idx];

        // align min addr for max addr computation to allow for smart AXI bursts around the 4k boundary 
        if      (port1_size[idx] == 3'b001)
          p1_mask[idx] = 3'b110;
        else if (port1_size[idx] == 3'b010)
          p1_mask[idx] = 3'b100;
        else if (port1_size[idx] == 3'b011)
          p1_mask[idx] = 3'b000;
        else 
          p1_mask[idx] = 3'b111;

        p1_align_addr[idx][AXI_S_ADDR_WIDTH-1:AXI_SIZE_WIDTH] = port1_addr[idx][AXI_S_ADDR_WIDTH-1:AXI_SIZE_WIDTH];
        p1_align_addr[idx][AXI_SIZE_WIDTH-1:0]                = port1_addr[idx][AXI_SIZE_WIDTH-1:0] & p1_mask[idx];
         
        if      (port2_size[idx] == 3'b001)
          p2_mask[idx] = 3'b110;
        else if (port2_size[idx] == 3'b010)
          p2_mask[idx] = 3'b100;
        else if (port2_size[idx] == 3'b011)
          p2_mask[idx] = 3'b000;
        else 
          p2_mask[idx] = 3'b111;

        if (port1_ctrl[idx] == {AXI_USER_WIDTH{1'b1}})
          p1_skip[idx] = 1'b1;
        else
          p1_skip[idx] = 1'b0;

        if (port2_ctrl[idx] == {AXI_USER_WIDTH{1'b1}})
          p2_skip[idx] = 1'b1;
        else
          p2_skip[idx] = 1'b0;
         
        p2_align_addr[idx][AXI_S_ADDR_WIDTH-1:AXI_SIZE_WIDTH] = port2_addr[idx][AXI_S_ADDR_WIDTH-1:AXI_SIZE_WIDTH];
        p2_align_addr[idx][AXI_SIZE_WIDTH-1:0]                = port2_addr[idx][AXI_SIZE_WIDTH-1:0] & p2_mask[idx];
        
        p1_max_addr[idx]  = p1_align_addr[idx] + p1_burst_size[idx] - 1;
        p2_max_addr[idx]  = p2_align_addr[idx] + p2_burst_size[idx] - 1;

        int_addr_min[idx] = select[idx] ? port1_addr[idx]  : port2_addr[idx];
        int_addr_max[idx] = select[idx] ? p1_max_addr[idx] : p2_max_addr[idx];
        int_rw[idx]       = select[idx] ? port1_type[idx]  : port2_type[idx];
        int_id[idx]       = select[idx] ? ( port1_id[idx] & {AXI_ID_WIDTH{!p1_skip[idx]}}) : ( port2_id[idx] & {AXI_ID_WIDTH{!p2_skip[idx]}});
        
        no_hit [idx]      = ~| hit [idx];
        no_prot[idx]      = ~| prot[idx];

        port1_out_addr[idx] = out_addr_reg[idx];
        port2_out_addr[idx] = out_addr_reg[idx];

      `ifdef EN_ACP
        port1_master_select[idx] = master_select_reg[idx];
        port2_master_select[idx] = master_select_reg[idx];
      `else
        port1_master_select[idx] = 1'b0;
        port2_master_select[idx] = 1'b0;
      `endif 
      end
    end   

  always_comb
    begin
      var integer idx_port, idx_slice;
      var integer reg_num;
      reg_num=0;
      for ( idx_port = 0; idx_port < N_PORTS; idx_port++ ) begin
        for ( idx_slice = 0; idx_slice < 4*N_SLICES[idx_port]; idx_slice++ ) begin
          int_cfg_regs_slices[idx_port][idx_slice] = int_cfg_regs[4+reg_num];
          reg_num++;
        end
        // int_cfg_regs_slices[idx_port][N_SLICES_MAX:N_SLICES[idx_port]] will be dangling
        // Fix to zero. Synthesis will remove these signals.
        // int_cfg_regs_slices[idx_port][4*N_SLICES_MAX-1:4*N_SLICES[idx_port]] = 0;
      end   
  end
   
  always @(posedge Clk_CI or negedge Rst_RBI)
    begin
      var integer idx;
      if (Rst_RBI == 1'b0)
        curr_priority = 'h0;
      else
        begin
          for (idx=0; idx<N_PORTS; idx++) begin
            if (port1_accept[idx] || port1_drop[idx])
              curr_priority[idx] = 1'b1;
            else if (port2_accept[idx] || port2_drop[idx])
              curr_priority[idx] = 1'b0;
        end
      end
    end
   
  // find port that misses
  logic [PORT_ID_WIDTH-1:0] PortIdx_D; // index of the first missing port
  var integer               idx_miss;
  always_comb
    begin
      PortIdx_D = 'b0; 
      for (idx_miss = 0; idx_miss < N_PORTS; idx_miss++)
        begin
          if (miss_valid_mhr[idx_miss] == 1'b1)
            begin
              PortIdx_D = idx_miss;
              break;
            end
        end
    end // always_comb begin

  //  █████╗ ██╗  ██╗██╗    ██████╗  █████╗ ██████╗      ██████╗███████╗ ██████╗ 
  // ██╔══██╗╚██╗██╔╝██║    ██╔══██╗██╔══██╗██╔══██╗    ██╔════╝██╔════╝██╔════╝ 
  // ███████║ ╚███╔╝ ██║    ██████╔╝███████║██████╔╝    ██║     █████╗  ██║  ███╗
  // ██╔══██║ ██╔██╗ ██║    ██╔══██╗██╔══██║██╔══██╗    ██║     ██╔══╝  ██║   ██║
  // ██║  ██║██╔╝ ██╗██║    ██║  ██║██║  ██║██████╔╝    ╚██████╗██║     ╚██████╔╝
  // ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝    ╚═╝  ╚═╝╚═╝  ╚═╝╚═════╝      ╚═════╝╚═╝      ╚═════╝ 
  // 
  axi_rab_cfg
    #(
      .N_PORTS         ( N_PORTS                    ),
      .N_REGS          ( N_REGS                     ),
      .ADDR_WIDTH_PHYS ( AXI_M_ADDR_WIDTH           ),
      .ADDR_WIDTH_VIRT ( AXI_S_ADDR_WIDTH           ),
      .N_FLAGS         ( 4                          ),       
      .AXI_DATA_WIDTH  ( AXI_LITE_DATA_WIDTH        ),
      .AXI_ADDR_WIDTH  ( AXI_LITE_ADDR_WIDTH        ),
      .MISS_ID_WIDTH   ( PORT_ID_WIDTH+AXI_ID_WIDTH )
      ) 
  u_axi_rab_cfg
    (
      .Clk_CI        (Clk_CI),
      .Rst_RBI       (Rst_RBI),
      .s_axi_awaddr  (s_axi_awaddr),
      .s_axi_awvalid (s_axi_awvalid),
      .s_axi_wdata   (s_axi_wdata),
      .s_axi_wstrb   (s_axi_wstrb),
      .s_axi_wvalid  (s_axi_wvalid),
      .s_axi_bready  (s_axi_bready),
      .s_axi_araddr  (s_axi_araddr),
      .s_axi_arvalid (s_axi_arvalid),
      .s_axi_rready  (s_axi_rready),
      .s_axi_arready (s_axi_arready),
      .s_axi_rdata   (s_axi_rdata),
      .s_axi_rresp   (s_axi_rresp),
      .s_axi_rvalid  (s_axi_rvalid),
      .s_axi_wready  (s_axi_wready),
      .s_axi_bresp   (s_axi_bresp),
      .s_axi_bvalid  (s_axi_bvalid),
      .s_axi_awready (s_axi_awready),
      .L1Cfg_DO      (int_cfg_regs),
      .MissAddr_DI   (miss_addr_mhr[PortIdx_D]),
      .MissId_DI     ({PortIdx_D,miss_id_mhr[PortIdx_D]}),
      .Miss_SI       (miss_valid_mhr[PortIdx_D]),
      .MhFifoFull_SO (int_mhr_full),
      .wdata_l2      (wdata_tlb_l2),
      .waddr_l2      (waddr_tlb_l2),
      .wren_l2       (wren_tlb_l2)
   );

  generate
    for (z = 0; z < N_PORTS; z++)
      begin
         if (ENABLE_L2TLB[z] == 1) begin // L2 TLB is enabled
            assign miss_valid_mhr[z] = miss_l2[z];
            assign miss_addr_mhr[z] = miss_addr_l2[z];
            assign miss_id_mhr[z] = miss_id_l2[z];
         end else begin// L2 TLB is disabled
            assign miss_valid_mhr[z] = int_miss[z];
            assign miss_addr_mhr[z] = int_addr_min[z];
            assign miss_id_mhr[z] = int_id[z];
         end
      end
  endgenerate

  // ███████╗██╗     ██╗ ██████╗███████╗    ████████╗ ██████╗ ██████╗ 
  // ██╔════╝██║     ██║██╔════╝██╔════╝    ╚══██╔══╝██╔═══██╗██╔══██╗
  // ███████╗██║     ██║██║     █████╗         ██║   ██║   ██║██████╔╝
  // ╚════██║██║     ██║██║     ██╔══╝         ██║   ██║   ██║██╔═══╝ 
  // ███████║███████╗██║╚██████╗███████╗       ██║   ╚██████╔╝██║     
  // ╚══════╝╚══════╝╚═╝ ╚═════╝╚══════╝       ╚═╝    ╚═════╝ ╚═╝     
  //                                                                  
  generate
    for (z = 0; z < N_PORTS; z++)
      begin
        slice_top 
          #(
            .N_SLICES        ( N_SLICES[z]      ),
            .N_REGS          ( 4*N_SLICES[z]    ),
            .ADDR_WIDTH_PHYS ( AXI_M_ADDR_WIDTH ),
            .ADDR_WIDTH_VIRT ( AXI_S_ADDR_WIDTH )
            )
        u_slice_top
          (
           .int_cfg_regs  ( int_cfg_regs_slices[z][4*N_SLICES[z]-1:0] ),
           .int_rw        ( int_rw[z]                                 ),
           .int_addr_min  ( int_addr_min[z]                           ),
           .int_addr_max  ( int_addr_max[z]                           ),
           .out_addr      ( out_addr[z]                               ),
           .multiple_hit  ( multiple_hit[z]                           ),      
           .prot          ( prot[z][N_SLICES[z]-1:0]                  ),
           .hit           (  hit[z][N_SLICES[z]-1:0]                  ),
           .master_select ( master_select[z]                          )
           );
        // hit[N_SLICES_MAX-1:N_SLICES_MAX-N_SLICES[z]] will be dangling
        // prot[N_SLICES_MAX-1:N_SLICES_MAX-N_SLICES[z]] will be dangling
        // Fix to zero. Synthesis will remove these signals.
        if ( N_SLICES[z] < N_SLICES_MAX ) begin
          assign hit[z][N_SLICES_MAX-1:N_SLICES[z]]  = 0;
          assign prot[z][N_SLICES_MAX-1:N_SLICES[z]] = 0;     
        end
      end // for (z = 0; z < N_PORTS; z++)
   endgenerate
   
  // ███████╗███████╗███╗   ███╗
  // ██╔════╝██╔════╝████╗ ████║
  // █████╗  ███████╗██╔████╔██║
  // ██╔══╝  ╚════██║██║╚██╔╝██║
  // ██║     ███████║██║ ╚═╝ ██║
  // ╚═╝     ╚══════╝╚═╝     ╚═╝
  //                            
  generate
    for (z = 0; z < N_PORTS; z++)
      begin
        fsm
          #(
            )
          u_fsm
          (
            .Clk_CI            (Clk_CI),
            .Rst_RBI           (Rst_RBI),
            .port1_addr_valid  (port1_addr_valid[z]),
            .port2_addr_valid  (port2_addr_valid[z]),
            .port1_skip        (p1_skip[z]),
            .port2_skip        (p2_skip[z]),
            .port1_sent        (port1_sent[z]),
            .port2_sent        (port2_sent[z]),
            .select            (select[z]),        
            .no_hit            (no_hit[z]),   
            .multiple_hit      (multiple_hit[z]),
            .no_prot           (no_prot[z]),
            .out_addr          (out_addr[z]),
            .master_select     (master_select[z]),
            .port1_accept      (port1_accept[z]),
            .port1_drop        (port1_drop[z]),  
            .port2_accept      (port2_accept[z]), 
            .port2_drop        (port2_drop[z]),
            .out_addr_reg      (out_addr_reg[z]),
            .master_select_reg (master_select_reg[z]),
            .int_miss          (int_miss[z]),    
            .int_multi         (int_multi[z]),  
            .int_prot          (int_prot[z])
          );
      end
  endgenerate

endmodule

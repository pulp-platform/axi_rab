module rab_core
  
     #(   RAB_ENTRIES      = 16,
          C_AXI_DATA_WIDTH = 32,
          N_PORTS          = 3)

  (
 
      input    logic                            s_axi_aclk,
      input    logic                            s_axi_aresetn,

      input    logic                    [31:0]  s_axi_awaddr,
      input    logic                            s_axi_awvalid,
      output   logic                            s_axi_awready,

      input    logic    [C_AXI_DATA_WIDTH-1:0]  s_axi_wdata,
      input    logic  [C_AXI_DATA_WIDTH/8-1:0]  s_axi_wstrb,
      input    logic                            s_axi_wvalid,
      output   logic                            s_axi_wready,

      input    logic                    [31:0]  s_axi_araddr,
      input    logic                            s_axi_arvalid,
      output   logic                            s_axi_arready,

      input    logic                            s_axi_rready,
      output   logic    [C_AXI_DATA_WIDTH-1:0]  s_axi_rdata,
      output   logic                     [1:0]  s_axi_rresp,
      output   logic                            s_axi_rvalid,

      output   logic                     [1:0]  s_axi_bresp,
      output   logic                            s_axi_bvalid,
      input    logic                            s_axi_bready,

      output   logic    [N_PORTS-1:0]  int_miss,
      output   logic    [N_PORTS-1:0]  int_prot,
      output   logic    [N_PORTS-1:0]  int_multi,

      input    logic    [N_PORTS-1:0]    [31:0]  port1_addr,
      input    logic    [N_PORTS-1:0]     [7:0]  port1_len,
      input    logic    [N_PORTS-1:0]     [2:0]  port1_size,
      input    logic    [N_PORTS-1:0]            port1_addr_valid,
      input    logic    [N_PORTS-1:0]            port1_type,
      input    logic    [N_PORTS-1:0]            port1_sent,
      output   logic    [N_PORTS-1:0]    [31:0]  port1_out_addr,
      output   logic    [N_PORTS-1:0]            port1_accept,
      output   logic    [N_PORTS-1:0]            port1_drop,

      input    logic    [N_PORTS-1:0]    [31:0]  port2_addr,
      input    logic    [N_PORTS-1:0]     [7:0]  port2_len,
      input    logic    [N_PORTS-1:0]     [2:0]  port2_size,
      input    logic    [N_PORTS-1:0]            port2_addr_valid,
      input    logic    [N_PORTS-1:0]            port2_type,
      input    logic    [N_PORTS-1:0]            port2_sent,
      output   logic    [N_PORTS-1:0]    [31:0]  port2_out_addr,
      output   logic    [N_PORTS-1:0]            port2_accept,
      output   logic    [N_PORTS-1:0]            port2_drop);
   
  localparam  REG_ENTRIES = 4*RAB_ENTRIES*N_PORTS + 4;

  logic             [N_PORTS-1:0]                  [14:0]  p1_burst_size;
  logic             [N_PORTS-1:0]                  [14:0]  p2_burst_size;

  logic             [N_PORTS-1:0]                  [31:0]  p1_max_addr;
  logic             [N_PORTS-1:0]                  [31:0]  p2_max_addr;
  
  logic             [N_PORTS-1:0]                          int_rw;   
  logic             [N_PORTS-1:0]                  [31:0]  int_addr_min;
  logic             [N_PORTS-1:0]                  [31:0]  int_addr_max;
   
  logic             [N_PORTS-1:0]                          no_hit; //   mi interessa solo sapere se c'e` stato hit,
  logic             [N_PORTS-1:0]                          no_prot;//    vedi lunghezze diverse con hit e prot 

  logic              [N_PORTS-1:0]       [RAB_ENTRIES-1:0]  hit;
  logic              [N_PORTS-1:0]       [RAB_ENTRIES-1:0]  prot;
   
  logic              [N_PORTS-1:0]                     [31:0]  out_addr;
  logic              [N_PORTS-1:0]                     [31:0]  out_addr_reg; 
  logic                              [REG_ENTRIES-1:0] [31:0] int_cfg_regs; 
  logic              [N_PORTS-1:0] [4*RAB_ENTRIES-1:0] [31:0] int_cfg_regs_slices; 

  logic             [N_PORTS-1:0]   select;
  reg               [N_PORTS-1:0]   curr_priority;

  reg               [N_PORTS-1:0]   multiple_hit;

   
  genvar  z;
  integer j, k,idx_slices,idx_ports;
 
  localparam  REGS_SLICE = 4 * 32; // stesso numero di reg da considerare come offset iniziale (top level) per la config
  localparam  REGS_CH    = REGS_SLICE * RAB_ENTRIES;// reg per ogni porta

//-----------------------------------------------------------------------------------
     
 always_comb
   begin
      
           for (k = 0; k < N_PORTS; k++) begin

              // select = 0 -> port1 active
              // select = 1 -> port2 active
              select[k] = (curr_priority[k] & port1_addr_valid[k]) | ~port2_addr_valid[k];
              
              p1_burst_size[k] = port1_len[k] << port1_size[k];
              p2_burst_size[k] = port2_len[k] << port2_size[k];

              p1_max_addr[k] = port1_addr[k] + p1_burst_size[k];
              p2_max_addr[k] = port2_addr[k] + p2_burst_size[k];

              int_addr_min[k] = select[k] ? port1_addr[k]  : port2_addr[k];
              int_addr_max[k] = select[k] ? p1_max_addr[k] : p2_max_addr[k];
              int_rw[k]       = select[k] ? port1_type[k]  : port2_type[k];  

              no_hit [k]      = ~| hit [k];
              no_prot[k]      = ~| prot[k];

              port1_out_addr[k] = out_addr_reg[k];
              port2_out_addr[k] = out_addr_reg[k];
              
           end
  end   

 always_comb
   begin
      
     for (idx_ports = 0; idx_ports < N_PORTS; idx_ports++) begin
       for (idx_slices=0; idx_slices< 4*RAB_ENTRIES; idx_slices++) begin
	int_cfg_regs_slices[idx_ports][idx_slices] =  int_cfg_regs[4+4*RAB_ENTRIES*idx_ports+idx_slices]; 
	end
     end   
end   

    
   always @(posedge s_axi_aclk or negedge s_axi_aresetn)
     begin

        if (s_axi_aresetn == 1'b0)
          curr_priority = 'h0;
        else
        begin
          for (j = 0; j < N_PORTS; j++) begin
            if (port1_accept[j] || port1_drop[j])
             curr_priority[j] = 1'b1;
            else if (port2_accept[j] || port2_drop[j])
             curr_priority[j] = 1'b0;
          end
        end

     end // always @ (posedge s_axi_aclk or negedge s_axi_aresetn)


   
  //--------------------  REG_TOP  ------------------------------- 
  
  axi_regs_top_rab #(REG_ENTRIES) u_axi_regs(
                                          .s_axi_aclk(s_axi_aclk),
                                          .s_axi_aresetn(s_axi_aresetn),
                                          .s_axi_awaddr(s_axi_awaddr),
                                          .s_axi_awvalid(s_axi_awvalid),
                                          .s_axi_wdata(s_axi_wdata),
                                          .s_axi_wstrb(s_axi_wstrb),
                                          .s_axi_wvalid(s_axi_wvalid),
                                          .s_axi_bready(s_axi_bready),
                                          .s_axi_araddr(s_axi_araddr),
                                          .s_axi_arvalid(s_axi_arvalid),
                                          .s_axi_rready(s_axi_rready),
                                          .s_axi_arready(s_axi_arready),
                                          .s_axi_rdata(s_axi_rdata),
                                          .s_axi_rresp(s_axi_rresp),
                                          .s_axi_rvalid(s_axi_rvalid),
                                          .s_axi_wready(s_axi_wready),
                                          .s_axi_bresp(s_axi_bresp),
                                          .s_axi_bvalid(s_axi_bvalid),
                                          .s_axi_awready(s_axi_awready),
                                          .cfg_regs(int_cfg_regs));
 

   //--------------------  SLICE_TOP ------------------------------- 

 generate for (z = 0; z < N_PORTS; z++) begin
 
     
    slice_top #(RAB_ENTRIES) u_slice_top (
                                          .int_cfg_regs(int_cfg_regs_slices[z]),
                                          .int_rw(int_rw[z]),
                                          .int_addr_min(int_addr_min[z]),
                                          .int_addr_max(int_addr_max[z]),
                                          .out_addr(out_addr[z]),
                                          .multiple_hit(multiple_hit[z]),      
                                          .prot(prot[z]),
                                          .hit(hit[z]));
 end
  endgenerate


   
   //------------------   FSM   --------------------------------
      
generate for (z = 0; z < N_PORTS; z++) begin
   
   fsm   u_fsm  (
                 .s_axi_aclk (s_axi_aclk),
                 .s_axi_aresetn (s_axi_aresetn),
                 .port1_addr_valid (port1_addr_valid[z]),
                 .port2_addr_valid (port2_addr_valid[z]),
                 .port1_sent (port1_sent[z]),
                 .port2_sent (port2_sent[z]),
                 .select (select[z]),        
                 .no_hit (no_hit[z]),   
                 .multiple_hit (multiple_hit[z]),
                 .no_prot (no_prot[z]),
                 .out_addr (out_addr[z]),   
                 .port1_accept (port1_accept[z]),
                 .port1_drop  (port1_drop[z]),  
                 .port2_accept (port2_accept[z]), 
                 .port2_drop (port2_drop[z]),  
                 .out_addr_reg  (out_addr_reg[z]),
                 .int_miss (int_miss[z]),    
                 .int_multi (int_multi[z]),  
                 .int_prot (int_prot[z]));
   
    end // for (z = 0; z < N_PORTS; z++)
  endgenerate

endmodule




`define log2(VALUE) ( (VALUE) == ( 1 ) ? 0 : (VALUE) < ( 2 ) ? 1 : (VALUE) < ( 4 ) ? 2 : (VALUE)< (8) ? 3:(VALUE) < ( 16 )  ? 4 : (VALUE) < ( 32 )  ? 5 : (VALUE) < ( 64 )  ? 6 : (VALUE) < ( 128 ) ? 7 : (VALUE) < ( 256 ) ? 8 : (VALUE) < ( 512 ) ? 9 : (VALUE) < ( 1024 ) ? 10 : (VALUE) < ( 2048 ) ? 11: (VALUE) < ( 4096 ) ? 12 : (VALUE) < ( 8192 ) ? 13 : (VALUE) < ( 16384 ) ? 14 : (VALUE) < ( 32768 ) ? 15 : (VALUE) < ( 65536 ) ? 16 : (VALUE) < ( 131072 ) ? 17 : (VALUE) < ( 262144 ) ? 18 : (VALUE) < ( 524288 ) ? 19 :  (VALUE) < ( 1048576 ) ? 20 : -1)

module axi_regs_top_rab
#( 
      parameter REG_ENTRIES         = 196,
      parameter C_AXICFG_DATA_WIDTH = 32
)
(             
         input   logic          		        s_axi_aclk,
         input   logic        		                s_axi_aresetn,
         input   logic [31:0]       	 	        s_axi_awaddr,
         input   logic         		                s_axi_awvalid,
         output  logic         		                s_axi_awready,
         input   logic [C_AXICFG_DATA_WIDTH/8-1:0][7:0] s_axi_wdata,
         input   logic [C_AXICFG_DATA_WIDTH/8-1:0]      s_axi_wstrb,
         input   logic         		                s_axi_wvalid,
         output  logic         		                s_axi_wready,
         output  logic [1:0]                            s_axi_bresp,
         output  logic         		                s_axi_bvalid,
         input   logic         		                s_axi_bready,
         input   logic [31:0]                           s_axi_araddr,
         input   logic         		                s_axi_arvalid,
         output  logic         		                s_axi_arready,
         output  logic [C_AXICFG_DATA_WIDTH-1:0]        s_axi_rdata,
         output  logic [1:0]                            s_axi_rresp,
         output  logic           		        s_axi_rvalid,
         input   logic           		        s_axi_rready,
         output  logic [REG_ENTRIES-1:0] [31:0]         cfg_regs
);

  localparam  ADDR_REG_MSB = `log2(REG_ENTRIES-1)+2-1;
  
  logic                               awaddr_done_reg;
  logic                               awaddr_done_reg_dly;
  logic                               wdata_done_reg;
  logic                               wdata_done_reg_dly;
  logic                               wresp_done_reg;
  logic                               wresp_running_reg;

  logic                               araddr_done_reg;
  logic                               rresp_done_reg;
  logic                               rresp_running_reg;

  logic                               awready;
  logic                               wready;
  logic                               bvalid;

  logic                               arready;
  logic                               rvalid;

  logic                        [31:0]    waddr_reg;
  logic [C_AXICFG_DATA_WIDTH/8-1:0][7:0] wdata_reg;
  logic                         [3:0]    wstrb_reg;

  logic                        [31:0] raddr_reg;
  logic                        [31:0] data_out_reg;

  logic                              write_en;

  int unsigned                           byte_index;
  int unsigned                           reg_index;
  int unsigned				 i;
  genvar 				 j;

  
  logic [3:0][7:0]     CONFIGURATION_REGISTERS [REG_ENTRIES];
  
  logic wdata_done_rise;
  logic awaddr_done_rise;
  assign write_en = (wdata_done_rise & awaddr_done_reg) | (awaddr_done_rise & wdata_done_reg);
  assign wdata_done_rise = wdata_done_reg & ~wdata_done_reg_dly;
  assign awaddr_done_rise = awaddr_done_reg & ~awaddr_done_reg_dly;

  
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      wdata_done_reg_dly  <= 0;
      awaddr_done_reg_dly <= 0;
    end
    else
    begin
      wdata_done_reg_dly  <= wdata_done_reg;
      awaddr_done_reg_dly <= awaddr_done_reg;
    end
  end
  
  
  // WRITE ADDRESS CHANNEL logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      awaddr_done_reg <= 0;
      waddr_reg       <= 0;
      awready         <= 1;
    end
    else
    begin
      if (awready && s_axi_awvalid)
      begin
        awready   <= 0;
        awaddr_done_reg <= 1;
        waddr_reg <= s_axi_awaddr;
      end
      else if (awaddr_done_reg && wresp_done_reg)
      begin
        awready   <= 1;
        awaddr_done_reg <= 0;
      end
    end
  end

  // WRITE DATA CHANNEL logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      wdata_done_reg <= 0;
      wready         <= 1;
      wdata_reg      <= '0;
      wstrb_reg      <= 0;
    end
    else
    begin
      if (wready && s_axi_wvalid)
      begin
        wready   <= 0;
        wdata_done_reg <= 1;
        wdata_reg <= s_axi_wdata;
        wstrb_reg <= s_axi_wstrb;
      end
      else if (wdata_done_reg && wresp_done_reg)
      begin
        wready   <= 1;
        wdata_done_reg <= 0;
      end
    end
  end

  // WRITE RESPONSE CHANNEL logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      bvalid            <= 0;
      wresp_done_reg    <= 0;
      wresp_running_reg <= 0;
    end
    else
    begin
      if (awaddr_done_reg && wdata_done_reg && !wresp_done_reg)
      begin
        if (!wresp_running_reg)
        begin
          bvalid         <= 1;
          wresp_running_reg <= 1;
        end
        else if (s_axi_bready)
        begin
          bvalid         <= 0;
          wresp_done_reg <= 1;
          wresp_running_reg <= 0;
        end
      end
      else
      begin
        bvalid         <= 0;
        wresp_done_reg <= 0;
        wresp_running_reg <= 0;
      end
    end
  end

  // READ ADDRESS CHANNEL logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      araddr_done_reg <= 0;
      arready         <= 1;
      raddr_reg       <= 0;
    end
    else
    begin
      if (arready && s_axi_arvalid)
      begin
        arready   <= 0;
        araddr_done_reg <= 1;
        raddr_reg <= s_axi_araddr;
      end
      else if (araddr_done_reg && rresp_done_reg)
      begin
        arready   <= 1;
        araddr_done_reg <= 0;
      end
    end
  end

  // READ RESPONSE CHANNEL logic
  always @(posedge s_axi_aclk or negedge s_axi_aresetn)
  begin
    if (!s_axi_aresetn)
    begin
      rresp_done_reg    <= 0;
      rvalid            <= 0;
      rresp_running_reg <= 0;
    end
    else
    begin
      if (araddr_done_reg && !rresp_done_reg)
      begin
        if (!rresp_running_reg)
        begin
          rvalid            <= 1;
          rresp_running_reg <= 1;
        end
        else if (s_axi_rready)
        begin
          rvalid            <= 0;
          rresp_done_reg    <= 1;
          rresp_running_reg <= 0;
        end
      end
      else
      begin
        rvalid         <= 0;
        rresp_done_reg <= 0;
        rresp_running_reg <= 0;
      end
    end
  end


  always @( posedge s_axi_aclk or negedge s_axi_aresetn )
  begin
      if ( s_axi_aresetn == 1'b0 )
      begin
	for(i=0;i<REG_ENTRIES; i++)
	begin
	  CONFIGURATION_REGISTERS[i] <= '0;
	end
      end
      else if (write_en)
      begin
            for ( byte_index = 0; byte_index < C_AXICFG_DATA_WIDTH/8; byte_index = byte_index+1 )
              if ( wstrb_reg[byte_index])
                CONFIGURATION_REGISTERS[waddr_reg[ADDR_REG_MSB:2]][byte_index] <= wdata_reg[byte_index];
      end
  end // SLAVE_REG_WRITE_PROC

    
    
  assign data_out_reg = CONFIGURATION_REGISTERS[raddr_reg[ADDR_REG_MSB:2]];
  

  generate
    for(j=0;j<REG_ENTRIES;j++)
    begin
      assign cfg_regs[j] = CONFIGURATION_REGISTERS[j];
    end
  endgenerate
  
 
  
  // implement slave model register read mux
// -------> FIXME IGOR COMMENT_ON
//   always @( raddr_reg or cfg_regs )
//   begin
//       data_out_reg = 'hDEADBEEF;
//       for ( reg_index = 0; reg_index < REG_ENTRIES; reg_index = reg_index+1 )
//         if (reg_index == raddr_reg[11:2])
//           data_out_reg = cfg_regs[raddr_reg[11:2]];
//   end // SLAVE_REG_READ_PROC
// ------>  FIXME IGOR COMMENT_OFF
  
  
  assign s_axi_awready = awready;
  assign s_axi_wready = wready;

  assign s_axi_bresp = 2'b00;
  assign s_axi_bvalid = bvalid;

  assign s_axi_arready = arready;
  assign s_axi_rresp = 2'b00;
  assign s_axi_rvalid = rvalid;
  assign s_axi_rdata = data_out_reg;

endmodule

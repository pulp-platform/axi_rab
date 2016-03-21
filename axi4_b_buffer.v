module axi4_b_buffer (axi4_aclk,
                      axi4_arstn,
                      s_axi4_bid,
                      s_axi4_bresp,
                      s_axi4_bvalid,
                      s_axi4_buser,
                      s_axi4_bready,
                      m_axi4_bid,
                      m_axi4_bresp,
                      m_axi4_bvalid,
                      m_axi4_buser,
                      m_axi4_bready);

  parameter  AXI_ID_WIDTH   = 4;
  parameter  AXI_USER_WIDTH = 4;

  input                       axi4_aclk;
  input                       axi4_arstn;

  output   [AXI_ID_WIDTH-1:0] s_axi4_bid;
  output                [1:0] s_axi4_bresp;
  output         		          s_axi4_bvalid;
  output [AXI_USER_WIDTH-1:0] s_axi4_buser;
  input          		          s_axi4_bready;

  input    [AXI_ID_WIDTH-1:0] m_axi4_bid;
  input                 [1:0] m_axi4_bresp;
  input         		          m_axi4_bvalid;
  input  [AXI_USER_WIDTH-1:0] m_axi4_buser;
  output          		        m_axi4_bready;

  wire [AXI_ID_WIDTH+AXI_USER_WIDTH+1:0] data_in;
  wire [AXI_ID_WIDTH+AXI_USER_WIDTH+1:0] data_out;

  assign data_in                                         [1:0] = m_axi4_bresp;
  assign data_in                            [AXI_ID_WIDTH+1:2] = m_axi4_bid;
  assign data_in[AXI_ID_WIDTH+AXI_USER_WIDTH+1:AXI_ID_WIDTH+2] = m_axi4_buser;

  assign s_axi4_buser  = data_out[AXI_ID_WIDTH+AXI_USER_WIDTH+1:AXI_ID_WIDTH+2];
  assign s_axi4_bid    = data_out[AXI_ID_WIDTH+1:2];
  assign s_axi4_bresp  = data_out[1:0];

  axi_buffer_rab
  #(
    .DATA_WIDTH( AXI_ID_WIDTH+AXI_USER_WIDTH+2 )
    )
  u_buffer
  (
    .clk(axi4_aclk), 
    .rstn(axi4_arstn), 
    .valid_out(s_axi4_bvalid), 
    .data_out(data_out), 
    .ready_in(s_axi4_bready), 
    .valid_in(m_axi4_bvalid), 
    .data_in(data_in), 
    .ready_out(m_axi4_bready)
  );

endmodule

module rab_wrap (
  input logic clk_i,
  input logic rst_ni,
  AXI_LITE.in config_in,
  AXI_BUS.in master_in,
  AXI_BUS.out slave_out
  );

`ifndef SYNTHESIS
  initial begin
    assert(slave_out.AXI_ADDR_WIDTH == master_in.AXI_ADDR_WIDTH);
    assert(slave_out.AXI_DATA_WIDTH == master_in.AXI_DATA_WIDTH);
  end
`endif

  AXI_BUS #(
    .AXI_ADDR_WIDTH(slave_out.AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(slave_out.AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(slave_out.AXI_ID_WIDTH),
    .AXI_USER_WIDTH(slave_out.AXI_USER_WIDTH)
    ) unused_slave();

  AXI_BUS #(
    .AXI_ADDR_WIDTH(slave_out.AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(slave_out.AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(slave_out.AXI_ID_WIDTH),
    .AXI_USER_WIDTH(slave_out.AXI_USER_WIDTH)
    ) unused_slave_acp();

  AXI_BUS #(
    .AXI_ADDR_WIDTH(master_in.AXI_ADDR_WIDTH),
    .AXI_DATA_WIDTH(master_in.AXI_DATA_WIDTH),
    .AXI_ID_WIDTH(master_in.AXI_ID_WIDTH),
    .AXI_USER_WIDTH(master_in.AXI_USER_WIDTH)
    ) unused_master();

  // NOTE: not used at the moment
  logic intr_mhf_full, intr_prot, intr_multi, intr_miss;

  axi_rab_wrap
    #(
      .N_PORTS             ( 2                        ),
      .N_L2_SETS           ( 32                       ),
      .N_L2_SET_ENTRIES    ( 32                       ),
      .AXI_DATA_WIDTH      ( master_in.AXI_DATA_WIDTH ),
      .AXI_USER_WIDTH      ( master_in.AXI_USER_WIDTH ),
      .AXI_INT_ADDR_WIDTH  ( master_in.AXI_ADDR_WIDTH ),
      .AXI_EXT_ADDR_WIDTH  ( slave_out.AXI_ADDR_WIDTH ),
      // .AXI_ID_WIDTH        ( master_in.AXI_ID_WIDTH   ),
      .AXI_LITE_DATA_WIDTH ( config_in.AXI_DATA_WIDTH ),
      .AXI_LITE_ADDR_WIDTH ( config_in.AXI_ADDR_WIDTH )
    ) i_axi_rab_wrap (
      .clk_i               ( clk_i      ),
      .non_gated_clk_i     ( clk_i ),
      .rst_ni              ( rst_ni     ),
      .rab_lite            ( config_in  ),
      .rab_master          ( slave_out ),
      .rab_acp             ( unused_slave_acp ),
      .rab_slave           ( unused_master ),
      .rab_to_socbus       ( unused_slave ),
      .socbus_to_rab       ( master_in ),
      .intr_mhf_full_o     ( intr_mhf_full),
      .intr_prot_o         ( intr_prot),
      .intr_multi_o        ( intr_multi),
      .intr_miss_o         ( intr_miss)
   );
endmodule

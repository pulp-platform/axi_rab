module tb_all;
  localparam AW = 32;
  localparam DW = 32;
  localparam SIW = 6;
  localparam MIW = 10;
  localparam UW = 8;
  localparam CK = 1ns;
  localparam TA = CK * 1 / 4;
  localparam TT = CK * 3 / 4;

  logic clk;
  logic done = 0;

  AXI_BUS_DV
    #(
      .AXI_ADDR_WIDTH(AW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH(SIW),
      .AXI_USER_WIDTH(UW)
      ) axi_slave_dv(clk);

  AXI_BUS_DV
    #(
      .AXI_ADDR_WIDTH(AW),
      .AXI_DATA_WIDTH(DW),
      .AXI_ID_WIDTH(MIW),
      .AXI_USER_WIDTH(UW)
      ) axi_master_dv(clk);

  AXI_LITE_DV
    #(
      .AXI_ADDR_WIDTH(AW),
      .AXI_DATA_WIDTH(DW)
      ) axi_config_dv(clk);

  base_tb
    #(
      .AW(AW),
      .DW(DW),
      .SIW(SIW),
      .MIW(MIW),
      .UW(UW),
      .CK(CK),
      .TA(TA),
      .TT(TT)
      )
  i_base_tb
    (
     .master_dv_in(axi_master_dv),
     .slave_dv_out(axi_slave_dv),
     .config_dv_in(axi_config_dv),
     .done_i(done),
     .clk_o(clk)
     );

  axi_test::axi_lite_driver #(.AW(AW), .DW(DW), .TT(TT), .TA(TA)) axi_config_drv = new(axi_config_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(SIW), .UW(UW), .TA(TA), .TT(TT)) axi_slave_drv = new(axi_slave_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(MIW), .UW(UW), .TA(TA), .TT(TT)) axi_master_drv = new(axi_master_dv);

  initial begin
    automatic axi_test::axi_ax_beat #(.AW(AW), .IW(MIW), .UW(UW)) ax_beat = new;
    automatic axi_test::axi_w_beat #(.DW(DW), .UW(UW)) w_beat = new;
    automatic axi_test::axi_b_beat  #(.IW(MIW), .UW(UW)) b_beat;
    axi_master_drv.reset_master();
    @(posedge clk);
    repeat (1) begin
      @(posedge clk);
      void'(randomize(ax_beat));
      axi_master_drv.send_aw(ax_beat);
      w_beat.w_data = 'hcafebabe;
      w_beat.w_last = 'b1;
      axi_master_drv.send_w(w_beat);
    end

    repeat (1) axi_master_drv.recv_b(b_beat);
    $display("RESULT %d", b_beat.b_resp);

    done = 1;
  end

  initial begin
    automatic axi_test::axi_ax_beat #(.AW(AW), .IW(SIW), .UW(UW)) ax_beat;
    automatic axi_test::axi_w_beat #(.DW(DW), .UW(UW)) w_beat;
    automatic axi_test::axi_b_beat #(.IW(SIW), .UW(UW)) b_beat = new;
    axi_slave_drv.reset_slave();
    axi_slave_drv.axi.aw_ready = 1'b1;
    axi_slave_drv.axi.w_ready  = 1'b1;
  end

  initial begin
    axi_config_drv.reset_master();
  end

endmodule

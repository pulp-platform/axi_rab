`include "axi/assign.svh"

module tb_invalidate;

  timeunit      1ps;
  timeprecision 1ps;

  parameter AW = 32;
  parameter DW = 32;
  parameter IW = 8;
  parameter UW = 8;
  localparam tCK = 1ns;
  localparam TA = tCK * 1 / 4;
  localparam TT = tCK * 3 / 4;

  logic clk = 0;
  logic rst = 1;
  logic done = 0;

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(IW),
    .AXI_USER_WIDTH(UW)
    ) axi_slave_dv(clk);

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(IW),
    .AXI_USER_WIDTH(UW)
    ) axi_slave();

  `AXI_ASSIGN(axi_slave_dv, axi_slave);

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(IW),
    .AXI_USER_WIDTH(UW)
    ) axi_master_dv(clk);

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(IW),
    .AXI_USER_WIDTH(UW)
    ) axi_master();

  `AXI_ASSIGN(axi_master, axi_master_dv);

  AXI_LITE_DV #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW)
    ) axi_config_dv(clk);

  AXI_LITE #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW)
    ) axi_config();

  `AXI_LITE_ASSIGN(axi_config, axi_config_dv);

  rab_wrap i_dut (
    .clk_i      ( clk        ),
    .rst_ni     ( rst        ),
    .config_in  ( axi_config ),
    .master_in  ( axi_master ),
    .slave_out  ( axi_slave  )
    );

  axi_test::axi_lite_driver #(.AW(AW), .DW(DW), .TT(TT), .TA(TA)) axi_config_drv = new(axi_config_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(IW), .UW(UW), .TA(TA), .TT(TT)) axi_slave_drv = new(axi_slave_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(IW), .UW(UW), .TA(TA), .TT(TT)) axi_master_drv = new(axi_master_dv);

  initial begin
    #tCK;
    rst <= 0;
    #tCK;
    rst <= 1;
    #tCK;
    while (!done) begin
      clk <= 1;
      #(tCK/2);
      clk <= 0;
      #(tCK/2);
    end
    $stop;
  end

  initial begin
    automatic axi_test::axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ax_beat = new;
    automatic axi_test::axi_w_beat #(.DW(DW), .UW(UW)) w_beat = new;
    automatic axi_test::axi_b_beat  #(.IW(IW), .UW(UW)) b_beat;
    axi_master_drv.reset_master();
    @(posedge clk);
    repeat (1) begin
      @(posedge clk);
      void'(randomize(ax_beat));
      ax_beat.ax_size = 8'h04;
      axi_master_drv.send_aw(ax_beat);
      w_beat.w_data = 'hcafebabe;
      w_beat.w_last = 'b1;
      axi_master_drv.send_w(w_beat);
    end

    // done = 1;

    repeat (1) axi_master_drv.recv_b(b_beat);

    done = 1;
  end

  initial begin
    automatic axi_test::axi_ax_beat #(.AW(AW), .IW(IW), .UW(UW)) ax_beat;
    automatic axi_test::axi_w_beat #(.DW(DW), .UW(UW)) w_beat;
    automatic axi_test::axi_b_beat #(.IW(IW), .UW(UW)) b_beat = new;
    axi_slave_drv.reset_slave();
  end

  initial begin
    axi_config_drv.reset_master();
  end

endmodule

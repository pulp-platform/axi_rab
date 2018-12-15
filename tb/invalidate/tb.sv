`include "axi/assign.svh"

module tb_invalidate;

  timeunit      1ps;
  timeprecision 1ps;

  parameter AW = 32;
  parameter DW = 32;
  parameter SIW = 6;
  parameter MIW = 10;
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
    .AXI_ID_WIDTH(SIW),
    .AXI_USER_WIDTH(UW)
    ) axi_slave_dv(clk);

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(SIW),
    .AXI_USER_WIDTH(UW)
    ) axi_slave();

  `AXI_ASSIGN(axi_slave_dv, axi_slave);

  AXI_BUS_DV #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(MIW),
    .AXI_USER_WIDTH(UW)
    ) axi_master_dv(clk);

  AXI_BUS #(
    .AXI_ADDR_WIDTH(AW),
    .AXI_DATA_WIDTH(DW),
    .AXI_ID_WIDTH(MIW),
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

  rab_wrap
    #(
      .TA(TA),
      .TT(TT)
     )
    i_dut
     (
      .clk_i      ( clk        ),
      .rst_ni     ( rst        ),
      .config_in  ( axi_config ),
      .master_in  ( axi_master ),
      .slave_out  ( axi_slave  )
     );

  axi_test::axi_lite_driver #(.AW(AW), .DW(DW), .TT(TT), .TA(TA)) axi_config_drv = new(axi_config_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(SIW), .UW(UW), .TA(TA), .TT(TT)) axi_slave_drv = new(axi_slave_dv);
  axi_test::axi_driver #(.AW(AW), .DW(DW), .IW(MIW), .UW(UW), .TA(TA), .TT(TT)) axi_master_drv = new(axi_master_dv);

  initial begin
    #tCK;
    rst <= 0;
    // a clock cycle is needed as the rab has some synchronous resets
    clk <= 1;
    #(tCK/2);
    clk <= 0;
    #(tCK/2);
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
    automatic axi_test::axi_ax_beat #(.AW(AW), .IW(MIW), .UW(UW)) ax_beat = new;
    automatic axi_test::axi_w_beat #(.DW(DW), .UW(UW)) w_beat = new;
    automatic axi_test::axi_b_beat  #(.IW(MIW), .UW(UW)) b_beat;
    axi_master_drv.reset_master();
    @(posedge clk);
    repeat (1) begin
      @(posedge clk);
      void'(randomize(ax_beat));
      // ax_beat.ax_size = 8'h04;
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
    axi_slave_drv.axi.w_ready = 1'b1;
  end

endmodule

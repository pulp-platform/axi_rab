// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module axi4_b_sender
  #(
    parameter AXI_ID_WIDTH   = 10,
    parameter AXI_USER_WIDTH = 4
  )
  (
    input  logic                      axi4_aclk,
    input  logic                      axi4_arstn,

    input  logic                      drop_i,
    output logic                      done_o,
    input  logic   [AXI_ID_WIDTH-1:0] id_i,
    input  logic                      prefetch_i,
    input  logic                      hit_i,

    output logic   [AXI_ID_WIDTH-1:0] s_axi4_bid,
    output logic                [1:0] s_axi4_bresp, 
    output logic                      s_axi4_bvalid,
    output logic [AXI_USER_WIDTH-1:0] s_axi4_buser,
    input  logic                      s_axi4_bready,

    input  logic   [AXI_ID_WIDTH-1:0] m_axi4_bid,
    input  logic                [1:0] m_axi4_bresp,
    input  logic                      m_axi4_bvalid,
    input  logic [AXI_USER_WIDTH-1:0] m_axi4_buser,
    output logic                      m_axi4_bready
  );

  logic                    fifo_valid;
  logic                    fifo_pop;
  logic                    fifo_push;
  logic                    fifo_ready;
  logic [AXI_ID_WIDTH-1:0] id;
  logic                    prefetch;
  logic                    hit;

  logic                    dropping;

  axi_buffer_rab
    #(
      .DATA_WIDTH   ( 2+AXI_ID_WIDTH  ),
      .BUFFER_DEPTH ( 4               )
      )
    u_fifo
      (
        .clk       ( axi4_aclk                 ),
        .rstn      ( axi4_arstn                ),
        // Pop
        .data_out  ( {prefetch,   hit,   id}   ),
        .valid_out ( fifo_valid                ),
        .ready_in  ( fifo_pop                  ),
        // Push
        .valid_in  ( fifo_push                 ),
        .data_in   ( {prefetch_i, hit_i, id_i} ),
        .ready_out ( fifo_ready                )
      );

  assign fifo_push = drop_i & fifo_ready;
  assign done_o    = fifo_push;

  assign fifo_pop  = dropping & s_axi4_bready;

  always @ (posedge axi4_aclk or negedge axi4_arstn) begin
    if (axi4_arstn == 1'b0) begin
      dropping <= 1'b0;
    end else begin
      if (fifo_valid && ~dropping)
        dropping <= 1'b1;
      else if (fifo_pop)
        dropping <= 1'b0;
    end
  end

  assign s_axi4_buser  = dropping ? {AXI_USER_WIDTH{1'b0}} : m_axi4_buser;
  assign s_axi4_bid    = dropping ? id : m_axi4_bid;

  assign s_axi4_bresp  = (dropping & prefetch & hit) ? 2'b00 : // prefetch hit, mutli, prot
                         (dropping & prefetch      ) ? 2'b10 : // prefetch miss
                         (dropping            & hit) ? 2'b10 : // non-prefetch multi, prot
                         (dropping                 ) ? 2'b10 : // non-prefetch miss
                         m_axi4_bresp;

  assign s_axi4_bvalid =  dropping | m_axi4_bvalid;
  assign m_axi4_bready = ~dropping & s_axi4_bready;

endmodule

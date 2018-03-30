// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

import CfMath::log2;

module axi_buffer_rab_bram
  #(
    parameter DATA_WIDTH       =  32,
    parameter BUFFER_DEPTH     = 512,
    parameter LOG_BUFFER_DEPTH =   9
    )
   (
    input logic                   clk,
    input logic                   rstn,

    // Downstream port
    output logic [DATA_WIDTH-1:0] data_out,
    output logic                  valid_out,
    input  logic                  ready_in,

    // Upstream port
    input  logic                  valid_in,
    input  logic [DATA_WIDTH-1:0] data_in,
    output logic                  ready_out,

    // Status and flush control
    output logic                  almost_full,
    input  logic                  flush_entries
    );

  // The BRAM needs to be in "write-first" mode for first-word fall-through FIFO behavior.
  // To still push and pop simultaneously if the buffer is full, we internally increase the
  // buffer depth by 1.
  localparam ACT_BUFFER_DEPTH     = BUFFER_DEPTH+1;
  localparam ACT_LOG_BUFFER_DEPTH = log2(ACT_BUFFER_DEPTH);

  // Internal data structures
  logic [ACT_LOG_BUFFER_DEPTH-1:0] pointer_in;       // location to which we last wrote
  logic [ACT_LOG_BUFFER_DEPTH-1:0] pointer_out;      // location from which we last sent
  logic [ACT_LOG_BUFFER_DEPTH-1:0] pointer_out_bram; // required for first-word fall-through behavior
  logic   [ACT_LOG_BUFFER_DEPTH:0] elements;         // number of elements in the buffer

  logic           [DATA_WIDTH-1:0] data_out_bram, data_out_q;
  logic                            valid_out_q;

  logic full;

  assign almost_full = (elements == BUFFER_DEPTH-1);
  assign full        = (elements == BUFFER_DEPTH);

  always @(posedge clk)
    begin: elements_sequential
      if      ( rstn == 1'b0 )
        elements <= 0;
      else if ( flush_entries == 1'b1 )
        elements <= 0;
      begin
        // ------------------
        // Are we filling up?
        // ------------------
        // One out, none in
        if (ready_in && valid_out && (!valid_in || full))
          elements <= elements - 1;
        // None out, one in
        else if ((!valid_out || !ready_in) && valid_in && !full)
          elements <= elements + 1;
        // Else, either one out and one in, or none out and none in - stays unchanged
      end
    end

  always @(posedge clk)
    begin: sequential
      if      ( rstn == 1'b0 )
      begin
        pointer_out <= 0;
        pointer_in  <= 0;
      end
      else if ( flush_entries == 1'b1 )
      begin
        pointer_out <= 0;
        pointer_in  <= 0;
      end
      else
      begin
        // ------------------------------------
        // Check what to do with the input side
        // ------------------------------------
        // We have some input, increase by 1 the input pointer
        if (valid_in && !full)
        begin
          if ( pointer_in == (ACT_BUFFER_DEPTH - 1) )
            pointer_in <= 0;
          else
            pointer_in <= pointer_in + 1;
        end
        // Else we don't have any input, the input pointer stays the same

        // -------------------------------------
        // Check what to do with the output side
        // -------------------------------------
        // We had pushed one flit out, we can try to go for the next one
        if (ready_in && valid_out)
        begin
          if ( pointer_out == (ACT_BUFFER_DEPTH - 1) )
            pointer_out <= 0;
          else
            pointer_out <= pointer_out + 1;
        end
        // Else stay on the same output location
      end
    end

  // Update output ports
  assign valid_out = (elements != 0);
  assign ready_out = ~full;

  // The BRAM has a read latency of one cycle
  // -> apply new address one cycle earlier for first-word fall-through FIFO behavior
  always_comb begin
    if (ready_in && valid_out) begin
      if ( pointer_out == (ACT_BUFFER_DEPTH - 1) ) begin
        pointer_out_bram <= 0;
      end else begin
        pointer_out_bram <= pointer_out + 1;
      end
    end else begin
      pointer_out_bram   <= pointer_out;
    end
  end

  ram_tp_write_first #(
    .ADDR_WIDTH ( ACT_LOG_BUFFER_DEPTH ),
    .DATA_WIDTH ( DATA_WIDTH           )
  )
  ram_tp_write_first_0
  (
    .clk   ( clk              ),
    .we    ( valid_in & ~full ),
    .addr0 ( pointer_in       ),
    .addr1 ( pointer_out_bram ),
    .d_i   ( data_in          ),
    .d0_o  (                  ),
    .d1_o  ( data_out_bram    )
  );

  // When reading from/writing two the same address on both ports ("Write-Read Collision"),
  // the data on the read port is invalid (during the write cycle). In this implementation,
  // this can happen only when the buffer is empty. Thus, we forward the data from an
  // register in this case.
  always @(posedge clk) begin
    if (rstn == 1'b0) begin
      data_out_q <= 'b0;
    end else if ( (pointer_out_bram == pointer_in) && (valid_in && !full) ) begin
      data_out_q <= data_in;
    end
  end

  always @(posedge clk) begin
    if (rstn == 1'b0) begin
      valid_out_q <= 'b0;
    end else begin
      valid_out_q <= valid_out;
    end
  end

  // Drive output data
  always_comb begin
    if (valid_out && !valid_out_q) begin // We have just written to an empty FIFO
      data_out = data_out_q;
    end else begin
      data_out = data_out_bram;
    end
  end

endmodule

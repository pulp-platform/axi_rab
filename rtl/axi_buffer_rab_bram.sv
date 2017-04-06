/* Copyright (C) 2017 ETH Zurich, University of Bologna
 * All rights reserved.
 *
 * This code is under development and not yet released to the public.
 * Until it is released, the code is under the copyright of ETH Zurich and
 * the University of Bologna, and may contain confidential and/or unpublished 
 * work. Any reuse/redistribution is strictly forbidden without written
 * permission from ETH Zurich.
 *
 * Bug fixes and contributions will eventually be released under the
 * SolderPad open hardware license in the context of the PULP platform
 * (http://www.pulp-platform.org), under the copyright of ETH Zurich and the
 * University of Bologna.
 */

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

    input  logic                  flush_entries
    );

  // Internal data structures
  logic [LOG_BUFFER_DEPTH-1:0] pointer_in;       // location to which we last wrote
  logic [LOG_BUFFER_DEPTH-1:0] pointer_out;      // location from which we last sent
  logic [LOG_BUFFER_DEPTH-1:0] pointer_out_bram; // required for first-word fall-through behavior
  logic   [LOG_BUFFER_DEPTH:0] elements;         // number of elements in the buffer

  logic full;

  assign full = (elements == BUFFER_DEPTH);

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
          if ( pointer_in == (BUFFER_DEPTH - 1) )
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
          if ( pointer_out == (BUFFER_DEPTH - 1) )
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

  // BRAM (ram) has a read latency of one cycle
  // -> apply new address one cycle earlier for first-word fall-through FIFO behavior
  always_comb
    begin
      if (ready_in && valid_out)
      begin
        if ( pointer_out == (BUFFER_DEPTH - 1) )
          pointer_out_bram <= 0;
        else
          pointer_out_bram <= pointer_out + 1;
      end
      else
        pointer_out_bram <= pointer_out;
    end

  ram #(
    .ADDR_WIDTH ( LOG_BUFFER_DEPTH ),
    .DATA_WIDTH ( DATA_WIDTH       )
  )
  ram_0
  (
    .clk   ( clk              ),
    .we    ( valid_in         ),
    .addr0 ( pointer_in       ),
    .addr1 ( pointer_out_bram ),
    .d_i   ( data_in          ),
    .d0_o  (                  ),
    .d1_o  ( data_out         )
  );

endmodule

// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

module rab_slice
 #(
    parameter ADDR_WIDTH_PHYS = 40,
    parameter ADDR_WIDTH_VIRT = 32
    )
   (
    input  logic [ADDR_WIDTH_VIRT-1:0] cfg_min,
    input  logic [ADDR_WIDTH_VIRT-1:0] cfg_max,
    input  logic [ADDR_WIDTH_PHYS-1:0] cfg_offset,
    input  logic                       cfg_wen,
    input  logic                       cfg_ren,
    input  logic                       cfg_en,
    input  logic                       in_trans_type,
    input  logic [ADDR_WIDTH_VIRT-1:0] in_addr_min,
    input  logic [ADDR_WIDTH_VIRT-1:0] in_addr_max,
    output logic                       out_hit,
    output logic                       out_prot,
    output logic [ADDR_WIDTH_PHYS-1:0] out_addr
  );

  wire min_above_min;
  wire min_below_max;
  wire max_below_max;

  assign min_above_min = (in_addr_min >= cfg_min) ? 1'b1 : 1'b0;
  assign min_below_max = (in_addr_min <= cfg_max) ? 1'b1 : 1'b0;
  assign max_below_max = (in_addr_max <= cfg_max) ? 1'b1 : 1'b0;

  assign out_hit  = cfg_en & min_above_min & min_below_max & max_below_max;
  assign out_prot = out_hit & ((in_trans_type & ~cfg_wen) | (~in_trans_type & ~cfg_ren));
  assign out_addr = in_addr_min - cfg_min + cfg_offset;

endmodule

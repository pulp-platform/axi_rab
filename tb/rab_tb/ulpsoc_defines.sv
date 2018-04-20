// Copyright 2018 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the "License"); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.

`ifndef ULPSOC_DEFINES_SV
`define ULPSOC_DEFINES_SV

// define if the 0x0000_0000 to 0x0040_0000 is the alias of the current cluster address space (eg cluster 0 is from  0x1000_0000 to 0x1040_0000)
`define CLUSTER_ALIAS

// To use new icache use this define
//`define USE_ICACHE_NEW

// Hardware Accelerator selection
//`define HWCRYPT

// Uncomment if the SCM is not present (it will still be in the memory map)
`define NO_SCM

// uncomment if you want to place the DEMUX peripherals (EU, MCHAN) rigth before the Test and set region. 
// This will steal 16KB from the 1MB TCDM reegion. 
// EU is mapped           from 0x10100000 - 0x400
// MCHAN regs are mapped  from 0x10100000 - 0x800
// remember to change the defines in the pulp.h as well to be coherent with this approach
//`define DEM_PER_BEFORE_TCDM_TS

// uncomment if FPGA emulator
// `define PULP_FPGA_EMUL 1
// uncomment if using Vivado for ulpcluster synthesis
`define VIVADO

// Enables memory mapped register and counters to extract statistic on instruction cache
`define FEATURE_ICACHE_STAT

`ifdef PULP_FPGA_EMUL
  // `undef  FEATURE_ICACHE_STAT
  `define SCM_BASED_ICACHE
`endif

//PARAMETRES
`ifndef PULP_FPGA_EMUL
   `define NB_CLUSTERS   1
   `define NB_CORES      8
   `define NB_DMAS       4
   `define NB_MPERIPHS   1
   `define NB_SPERIPHS   8
`else
   `define NB_CLUSTERS   4
   `define NB_CORES      8
   `define NB_DMAS       4
   `define NB_MPERIPHS   1
   `define NB_SPERIPHS   8
`endif

// DEFINES
`define MPER_EXT_ID   0

`define SPER_EOC_ID      0
`define SPER_TIMER_ID    1
`define SPER_BBMUX_ID    2
`define SPER_RPIPE_ID    3
`define SPER_MMU_ID      4 
`define SPER_ICACHE_CTRL 5
`define SPER_HWCE_ID     6
`define SPER_EXT_ID      7

`define RVT 0
`define LVT 1

`ifndef PULP_FPGA_EMUL
  `define LEVEL_SHIFTER
`endif

// Comment to use bheavioral memories, uncomment to use stdcell latches. If uncommented, simulations slowdown occuor
`ifdef SYNTHESIS
 `define SCM_IMPLEMENTED
 `define SCM_BASED_ICACHE
`endif

// Width of byte enable for a given data width
`define EVAL_BE_WIDTH(DATAWIDTH) (DATAWIDTH/8)

/* Interfaces have been moved to pulp_interfaces.sv. Sorry :) */

`include "fp_defines.sv"

// RAB defines
`define EN_L2TLB_ARRAY          {1}  // Port 1, Port 0
`define N_SLICES_ARRAY         {32}
`define N_SLICES_MAX            32
`define EN_ACP                   1

`define RAB_N_PORTS              2
`define RAB_L2_N_SETS           32
`define RAB_L2_N_SET_ENTRIES    32
`define RAB_L2_N_PAR_VA_RAMS     4

`include "pulp_interfaces.sv"

`endif // ULPSOC_DEFINES_SV

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


//Choose the technology (ASIC synthesis Only) --> 8T : CMOS28FDSOI_8T    or 12T UWVR : CMOS28FDSOI_12T_UWVR
//`define CMOS28FDSOI_12T_UWVR
//`define CMOS28FDSOI_8T


// PE selection (only for non-FPGA - otherwise selected via PULP_CORE env variable)
// -> define RISCV for RISC-V processor
//`define RISCV
`ifndef PULP_FPGA_EMUL
//  `define RISCV
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
//////////////////////
// MMU DEFINES
//
// switch for including implementation of MMUs
//`define MMU_IMPLEMENTED
// number of logical TCDM banks (regarding interleaving)
`define MMU_TCDM_BANKS 8
// switch to enable local copy registers of
// the control signals in every MMU
//`define MMU_LOCAL_COPY_REGS
//
//////////////////////

// Width of byte enable for a given data width
`define EVAL_BE_WIDTH(DATAWIDTH) (DATAWIDTH/8)

/* Interfaces have been moved to pulp_interfaces.sv. Sorry :) */

`include "fp_defines.sv"

// RAB defines
`define EN_L2TLB_ARRAY {1}  // Port 1, Port 0
`define N_SLICES_ARRAY {32}
`define N_SLICES_MAX   32
`define EN_ACP         1

`endif // ULPSOC_DEFINES_SV
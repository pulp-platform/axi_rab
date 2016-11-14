#! /bin/tcsh -x

## set variables
set VER=10.4c
set LIB=rtl
set DESIGN=rab
set LOG=${DESIGN}.log

set PULP_BASE_PATH=~/scratch/juno/big.pulp

## ATTENTION: Make sure ulpsoc_defines.sv has defines for a single RAB port. The tb supports only 0 port.
set ULPSOC_DEFINES_PATH=
set PULP_INTERFACE_PATH=${PULP_BASE_PATH}/fe/rtl/components
set FP_DEFINES_PATH=${PULP_BASE_PATH}/fe/rtl/includes

# Path for all RAB components
set IPS_SOURCE_PATH=${PULP_BASE_PATH}/fe/ips
set ULPSOC_SOURCE_PATH=${PULP_BASE_PATH}/fe/rtl/ulpsoc
set FPGA_IPS_SOURCE_PATH=${PULP_BASE_PATH}/fpga/ips

set INC_PATHS=${ULPSOC_DEFINES_PATH}+${PULP_INTERFACE_PATH}+${IPS_SOURCE_PATH}/axi/axi_rab+${FP_DEFINES_PATH}

## clean up the library before recompiling
if (-e $LIB) then
 rm -rf $LIB
endif
 
## make new library
vlib-${VER} $LIB

## start the log file  (deletes old log file)
echo -n "** Compilation using modelsim version: $VER of ${DESIGN} from: " >> ${LOG}
date                                                                      >> ${LOG}
 
## compile sourcecode(s)
# generic FIFO
vlog-${VER}  -work $LIB +incdir+${INC_PATHS} +define+PULP_FPGA_EMUL=1 ${IPS_SOURCE_PATH}/common_cells/generic_fifo.sv >> ${LOG}

# Packages
vlog-${VER}  -work $LIB ${PULP_BASE_PATH}/fe/rtl/packages/CfMath.sv                               >> ${LOG}

# ID remap
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_id_remap/ID_Gen_4.sv     >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_id_remap/ID_Gen_16.sv    >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_id_remap/ID_Gen_64.sv    >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_id_remap/axi_id_remap.sv >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${ULPSOC_SOURCE_PATH}/axi_id_remap_wrap.sv          >> ${LOG}

# RAB
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/rab_slice.sv                          >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/slice_top.sv                          >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/fsm.sv                                >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi_rab_cfg.sv                        >> ${LOG}

vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi_rab_cfg.sv                        >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi_buffer_rab.sv                     >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi_buffer_rab_bram.sv                >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_ar_buffer.sv                     >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_aw_buffer.sv                     >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_w_buffer.sv                      >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_r_buffer.sv                      >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_b_buffer.sv                      >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_aw_sender.sv>> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_ar_sender.sv>> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_w_sender.sv >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_r_sender.sv >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi4_b_sender.sv >> ${LOG}

vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/ram.sv                                >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/check_ram.sv                          >> ${LOG}
vlog-${VER}  -work $LIB  ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/tlb_l2.sv                             >> ${LOG}

vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/fpga-support/rtl/BramPort.sv      >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/fpga-support/rtl/TdpBramArray.sv  >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/fpga-support/rtl/BramDwc.sv       >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/fpga-support/rtl/BramLogger.sv    >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/fpga-support/rtl/AxiBramLogger.sv >> ${LOG}

vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/rab_core.sv      >> ${LOG}
vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ${IPS_SOURCE_PATH}/axi/axi_rab/rtl/axi_rab_top.sv   >> ${LOG}

vlog-${VER}  -work $LIB  +incdir+${INC_PATHS} ./axi_rab_wrap_tb.sv                            >> ${LOG}
 
# traffic generators
vlog-${VER}  -work $LIB ../axi4lite_vip/verification_ip/axi4lite_m_if.sv                                             >> ${LOG}
vlog-${VER}  -work $LIB ../axi4lite_vip/verification_ip/axi4lite_m.sv                                                >> ${LOG}
vlog-${VER}  -work $LIB ../axi4lite_vip/examples/testbench/packet.sv                                                 >> ${LOG}
vlog-${VER}  -work $LIB +incdir+../TGEN_RAB/TGEN/traffic_pattern ../TGEN_RAB/TGEN/TGEN.sv                            >> ${LOG}
vlog-${VER}  -work $LIB +incdir+../TGEN_RAB/TGEN/traffic_pattern +incdir+${INC_PATHS}  ../TGEN_RAB/TGEN/TGEN_wrap.sv >> ${LOG}

# AXI memory
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_slice/axi_ar_buffer.sv >> ${LOG}
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_slice/axi_aw_buffer.sv >> ${LOG}
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_slice/axi_b_buffer.sv  >> ${LOG}
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_slice/axi_r_buffer.sv  >> ${LOG}
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_slice/axi_w_buffer.sv  >> ${LOG}

vlog-${VER}  -work $LIB ${PULP_BASE_PATH}/fe/rtl/components/memory_models.sv
vlog-${VER}  -work $LIB ${IPS_SOURCE_PATH}/axi/axi_mem_if/axi_mem_if.sv
vlog-${VER}  -work $LIB ${ULPSOC_SOURCE_PATH}/axi_mem_if_wrap.sv
vlog-${VER}  -work $LIB +incdir+${INC_PATHS} ${PULP_BASE_PATH}/fpga/rtl/l2_generic.sv
vlog-${VER}  -work $LIB +define+PULP_HSA_SIM=1 ${ULPSOC_SOURCE_PATH}/l2_ram.sv

# testbench
vlog-${VER}  -work $LIB +incdir+${INC_PATHS}  ./test.sv         >> ${LOG}
vlog-${VER}  -work $LIB +incdir+${INC_PATHS}  ./${DESIGN}_tb.sv >> ${LOG}

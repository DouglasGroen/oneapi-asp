# Copyright 2022 Intel Corporation
# SPDX-License-Identifier: MIT
#

set THIS_DIR [file dirname [info script]]
post_message "bsp-design-files.tcl: THIS_DIR is $THIS_DIR"
#--------------------
# IPs
#--------------------
#source "${THIS_DIR}/../../build/afu_ip.qsf"
set_global_assignment -name QSYS_FILE "${THIS_DIR}/board.qsys"
set_global_assignment -name QSYS_FILE "${THIS_DIR}/ddr_channel.qsys"
set_global_assignment -name QSYS_FILE "${THIS_DIR}/ddr_board.qsys"

#--------------------
# DMA controller
#--------------------
set THIS_DIR [file dirname [info script]]
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE  "${THIS_DIR}/rtl/dma/par/dma_controller_filelist.tcl"

#--------------------
# MPF VTP files
#--------------------
set THIS_DIR [file dirname [info script]]
set_global_assignment -name SOURCE_TCL_SCRIPT_FILE  "${THIS_DIR}/mpf_vtp.tcl"

#--------------------
# BSP RTL files
#--------------------
set THIS_DIR [file dirname [info script]]
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/ofs_plat_afu.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/afu.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/mem_if_vtp.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/kernel_wrapper.v"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/bsp_logic.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/dc_bsp_interfaces.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/dc_bsp_pkg.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/bsp_host_mem_if_mux.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/avmm_wr_ack_gen.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/avmm_wr_ack_burst_to_word.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/rtl/avmm_wr_ack_tracker.sv"

#--------------------
# Search paths (for headers, etc)
#--------------------
set_global_assignment -name SEARCH_PATH "${THIS_DIR}/rtl/"

#--------------------
# SDC
#--------------------
set_global_assignment -name SDC_FILE "${THIS_DIR}/opencl_bsp.sdc"

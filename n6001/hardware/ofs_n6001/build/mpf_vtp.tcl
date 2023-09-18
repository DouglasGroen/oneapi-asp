# Copyright 2022 Intel Corporation
# SPDX-License-Identifier: MIT

set THIS_DIR [file dirname [info script]]

set_global_assignment -name SEARCH_PATH "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims"
set_global_assignment -name SEARCH_PATH "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims/common"
set_global_assignment -name SEARCH_PATH "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate"
set_global_assignment -name SEARCH_PATH "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/ccip"

set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims/mpf_vtp_svc_ofs_avalon_mem_rdwr.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims/mpf_vtp_svc_ofs_axi_mem.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims/mpf_vtp_svc_ofs_ccip.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/svc_shims/common/mpf_vtp_svc_mmio.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/mpf_vtp_translate_chan.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/mpf_vtp_translate_ofs_avalon_mem.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/mpf_vtp_translate_ofs_avalon_mem_rdwr.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/mpf_vtp_translate_ofs_axi_mem.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/ccip/mpf_vtp_translate_ofs_ccip.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/ccip/mpf_vtp_translate_ofs_ccip_c0.sv"
set_global_assignment -name SYSTEMVERILOG_FILE "${THIS_DIR}/ip/BBB_mpf_vtp/hw/rtl/translate/ccip/mpf_vtp_translate_ofs_ccip_c1.sv"

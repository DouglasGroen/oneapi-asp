// Copyright 2020 Intel Corporation.
//
// THIS SOFTWARE MAY CONTAIN PREPRODUCTION CODE AND IS PROVIDED BY THE
// COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
// WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
// DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
// BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
// WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
// OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
// EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

`include "platform_if.vh"
`include "fpga_defines.vh"
`include "opencl_bsp.vh"

// kernel_wrapper
// Using kernel wrapper instead of kernel_system, since kernel_system is auto generated.
// kernel_system introduces boundary ports that are not used, and in PR they get preserved

module kernel_wrapper (
    input       clk,
    input       clk2x,
    input       reset_n,
    
    opencl_kernel_control_intf.kw opencl_kernel_control,
    kernel_mem_intf.ker kernel_mem[dc_bsp_pkg::BSP_NUM_LOCAL_MEM_BANKS]
    `ifdef INCLUDE_USM_SUPPORT
        , ofs_plat_avalon_mem_if.to_sink kernel_svm
    `endif
);

kernel_mem_intf mem_avmm_bridge [dc_bsp_pkg::BSP_NUM_LOCAL_MEM_BANKS-1:0] ();
opencl_kernel_control_intf kernel_cra_avmm_bridge ();

always_comb begin
    opencl_kernel_control.kernel_irq                = kernel_cra_avmm_bridge.kernel_irq;
end

//add pipeline stages to the memory interfaces
genvar m;
generate 
    for (m = 0; m<dc_bsp_pkg::BSP_NUM_LOCAL_MEM_BANKS; m=m+1) begin : mem_pipes
    
        //pipeline bridge from the kernel to board.qsys
        acl_avalon_mm_bridge_s10 #(
            .DATA_WIDTH                     ( dc_bsp_pkg::OPENCL_BSP_KERNEL_DATA_WIDTH ),
            .SYMBOL_WIDTH                   ( 8   ),
            .HDL_ADDR_WIDTH                 ( dc_bsp_pkg::OPENCL_QSYS_ADDR_WIDTH ),
            .BURSTCOUNT_WIDTH               ( dc_bsp_pkg::OPENCL_BSP_KERNEL_BURSTCOUNT_WIDTH   ),
            .SYNCHRONIZE_RESET              ( 1   ),
            .DISABLE_WAITREQUEST_BUFFERING  ( dc_bsp_pkg::KERNELWRAPPER_MEM_PIPELINE_DISABLEWAITREQBUFFERING),
            .READDATA_PIPE_DEPTH            ( dc_bsp_pkg::KERNELWRAPPER_MEM_PIPELINE_STAGES_RDDATA)
        ) avmm_pipeline_inst (
            .clk               (clk),
            .reset             (!reset_n),
            .s0_waitrequest    (mem_avmm_bridge[m].waitrequest  ),
            .s0_readdata       (mem_avmm_bridge[m].readdata     ),
            .s0_readdatavalid  (mem_avmm_bridge[m].readdatavalid),
            .s0_burstcount     (mem_avmm_bridge[m].burstcount   ),
            .s0_writedata      (mem_avmm_bridge[m].writedata    ),
            .s0_address        (mem_avmm_bridge[m].address      ),
            .s0_write          (mem_avmm_bridge[m].write        ),
            .s0_read           (mem_avmm_bridge[m].read         ),
            .s0_byteenable     (mem_avmm_bridge[m].byteenable   ),
            .m0_waitrequest    (kernel_mem[m].waitrequest  ),
            .m0_readdata       (kernel_mem[m].readdata     ),
            .m0_readdatavalid  (kernel_mem[m].readdatavalid),
            .m0_burstcount     (kernel_mem[m].burstcount   ),
            .m0_writedata      (kernel_mem[m].writedata    ),
            .m0_address        (kernel_mem[m].address      ),
            .m0_write          (kernel_mem[m].write        ),
            .m0_read           (kernel_mem[m].read         ),
            .m0_byteenable     (kernel_mem[m].byteenable   )
        );
        
    end : mem_pipes
endgenerate

`ifdef INCLUDE_USM_SUPPORT
    logic [dc_bsp_pkg::OPENCL_MEMORY_BYTE_OFFSET-1:0] svm_addr_shift;
    logic kernel_system_svm_read, kernel_system_svm_write;
    
    ofs_plat_avalon_mem_if
    # (
        .ADDR_WIDTH (dc_bsp_pkg::OPENCL_SVM_QSYS_ADDR_WIDTH),
        .DATA_WIDTH (dc_bsp_pkg::OPENCL_BSP_KERNEL_SVM_DATA_WIDTH),
        .BURST_CNT_WIDTH (dc_bsp_pkg::OPENCL_BSP_KERNEL_SVM_BURSTCOUNT_WIDTH)
    ) svm_avmm_bridge ();
    
    always_comb begin
        kernel_svm.user  = 'b0;
    end
    
    acl_avalon_mm_bridge_s10 #(
        .DATA_WIDTH                     ( dc_bsp_pkg::OPENCL_BSP_KERNEL_SVM_DATA_WIDTH ),
        .SYMBOL_WIDTH                   ( 8   ),
        .HDL_ADDR_WIDTH                 ( dc_bsp_pkg::OPENCL_SVM_QSYS_ADDR_WIDTH ),
        .BURSTCOUNT_WIDTH               ( dc_bsp_pkg::OPENCL_BSP_KERNEL_SVM_BURSTCOUNT_WIDTH),
        .SYNCHRONIZE_RESET              ( 1   ),
        .DISABLE_WAITREQUEST_BUFFERING  ( 1   ),
        .READDATA_PIPE_DEPTH            ( dc_bsp_pkg::KERNELWRAPPER_SVM_PIPELINE_STAGES_RDDATA   )
    )  kernel_mem_acl_avalon_mm_bridge_s10 (
        .clk                          (clk),
        .reset                        (!reset_n),
        .s0_waitrequest               (svm_avmm_bridge.waitrequest),
        .s0_readdata                  (svm_avmm_bridge.readdata),
        .s0_readdatavalid             (svm_avmm_bridge.readdatavalid),
        .s0_burstcount                (svm_avmm_bridge.burstcount),
        .s0_writedata                 (svm_avmm_bridge.writedata),
        .s0_address                   (svm_avmm_bridge.address),
        .s0_write                     (svm_avmm_bridge.write),
        .s0_read                      (svm_avmm_bridge.read),
        .s0_byteenable                (svm_avmm_bridge.byteenable),
        .m0_waitrequest               (kernel_svm.waitrequest),
        .m0_readdata                  (kernel_svm.readdata),
        .m0_readdatavalid             (kernel_svm.readdatavalid),
        .m0_burstcount                (kernel_svm.burstcount),
        .m0_writedata                 (kernel_svm.writedata),
        .m0_address                   (kernel_svm.address),
        .m0_write                     (kernel_svm.write),
        .m0_read                      (kernel_svm.read),
        .m0_byteenable                (kernel_svm.byteenable)
    );
`endif

//avmm pipeline for kernel cra
acl_avalon_mm_bridge_s10 #(
    .DATA_WIDTH                     ( dc_bsp_pkg::OPENCL_BSP_KERNEL_CRA_DATA_WIDTH ),
    .SYMBOL_WIDTH                   ( 8   ),
    .HDL_ADDR_WIDTH                 ( dc_bsp_pkg::OPENCL_BSP_KERNEL_CRA_ADDR_WIDTH  ),
    .BURSTCOUNT_WIDTH               ( 1   ),
    .SYNCHRONIZE_RESET              ( 1   ),
    .DISABLE_WAITREQUEST_BUFFERING  ( dc_bsp_pkg::KERNELWRAPPER_CRA_PIPELINE_DISABLEWAITREQBUFFERING),
    .READDATA_PIPE_DEPTH            ( dc_bsp_pkg::KERNELWRAPPER_CRA_PIPELINE_STAGES_RDDATA)
) kernel_cra_avalon_mm_bridge_s10 (
    .clk               (clk),
    .reset             (!reset_n),
    .s0_waitrequest    (opencl_kernel_control.kernel_cra_waitrequest  ),
    .s0_readdata       (opencl_kernel_control.kernel_cra_readdata     ),
    .s0_readdatavalid  (opencl_kernel_control.kernel_cra_readdatavalid),
    .s0_burstcount     (opencl_kernel_control.kernel_cra_burstcount   ),
    .s0_writedata      (opencl_kernel_control.kernel_cra_writedata    ),
    .s0_address        (opencl_kernel_control.kernel_cra_address      ),
    .s0_write          (opencl_kernel_control.kernel_cra_write        ),
    .s0_read           (opencl_kernel_control.kernel_cra_read         ),
    .s0_byteenable     (opencl_kernel_control.kernel_cra_byteenable   ),
    .m0_waitrequest    (kernel_cra_avmm_bridge.kernel_cra_waitrequest  ),
    .m0_readdata       (kernel_cra_avmm_bridge.kernel_cra_readdata     ),
    .m0_readdatavalid  (kernel_cra_avmm_bridge.kernel_cra_readdatavalid),
    .m0_burstcount     (kernel_cra_avmm_bridge.kernel_cra_burstcount   ),
    .m0_writedata      (kernel_cra_avmm_bridge.kernel_cra_writedata    ),
    .m0_address        (kernel_cra_avmm_bridge.kernel_cra_address      ),
    .m0_write          (kernel_cra_avmm_bridge.kernel_cra_write        ),
    .m0_read           (kernel_cra_avmm_bridge.kernel_cra_read         ),
    .m0_byteenable     (kernel_cra_avmm_bridge.kernel_cra_byteenable   )
);

//the pretty SV interfaces need to be expanded here because kernel_system is verbosely generated by Quartus.
//=======================================================
//  kernel_system instantiation
//=======================================================
kernel_system kernel_system_inst (
    .clock_reset_clk              (clk),
    .clock_reset2x_clk            (clk2x),
    .clock_reset_reset_reset_n    (reset_n),
    
    `ifdef PAC_BSP_ENABLE_DDR4_BANK1
        .kernel_ddr4a_waitrequest     (mem_avmm_bridge[0].waitrequest  ),
        .kernel_ddr4a_readdata        (mem_avmm_bridge[0].readdata     ),
        .kernel_ddr4a_readdatavalid   (mem_avmm_bridge[0].readdatavalid),
        .kernel_ddr4a_burstcount      (mem_avmm_bridge[0].burstcount   ),
        .kernel_ddr4a_writedata       (mem_avmm_bridge[0].writedata    ),
        .kernel_ddr4a_address         (mem_avmm_bridge[0].address      ),
        .kernel_ddr4a_write           (mem_avmm_bridge[0].write        ),
        .kernel_ddr4a_read            (mem_avmm_bridge[0].read         ),
        .kernel_ddr4a_byteenable      (mem_avmm_bridge[0].byteenable   ),
    `endif
    `ifdef PAC_BSP_ENABLE_DDR4_BANK2
        .kernel_ddr4b_waitrequest     (mem_avmm_bridge[1].waitrequest  ),
        .kernel_ddr4b_readdata        (mem_avmm_bridge[1].readdata     ),
        .kernel_ddr4b_readdatavalid   (mem_avmm_bridge[1].readdatavalid),
        .kernel_ddr4b_burstcount      (mem_avmm_bridge[1].burstcount   ),
        .kernel_ddr4b_writedata       (mem_avmm_bridge[1].writedata    ),
        .kernel_ddr4b_address         (mem_avmm_bridge[1].address      ),
        .kernel_ddr4b_write           (mem_avmm_bridge[1].write        ),
        .kernel_ddr4b_read            (mem_avmm_bridge[1].read         ),
        .kernel_ddr4b_byteenable      (mem_avmm_bridge[1].byteenable   ),
    `endif
    `ifdef PAC_BSP_ENABLE_DDR4_BANK3
        .kernel_ddr4c_waitrequest     (mem_avmm_bridge[2].waitrequest  ),
        .kernel_ddr4c_readdata        (mem_avmm_bridge[2].readdata     ),
        .kernel_ddr4c_readdatavalid   (mem_avmm_bridge[2].readdatavalid),
        .kernel_ddr4c_burstcount      (mem_avmm_bridge[2].burstcount   ),
        .kernel_ddr4c_writedata       (mem_avmm_bridge[2].writedata    ),
        .kernel_ddr4c_address         (mem_avmm_bridge[2].address      ),
        .kernel_ddr4c_write           (mem_avmm_bridge[2].write        ),
        .kernel_ddr4c_read            (mem_avmm_bridge[2].read         ),
        .kernel_ddr4c_byteenable      (mem_avmm_bridge[2].byteenable   ),
    `endif
    `ifdef PAC_BSP_ENABLE_DDR4_BANK4
        .kernel_ddr4d_waitrequest     (mem_avmm_bridge[3].waitrequest  ),
        .kernel_ddr4d_readdata        (mem_avmm_bridge[3].readdata     ),
        .kernel_ddr4d_readdatavalid   (mem_avmm_bridge[3].readdatavalid),
        .kernel_ddr4d_burstcount      (mem_avmm_bridge[3].burstcount   ),
        .kernel_ddr4d_writedata       (mem_avmm_bridge[3].writedata    ),
        .kernel_ddr4d_address         (mem_avmm_bridge[3].address      ),
        .kernel_ddr4d_write           (mem_avmm_bridge[3].write        ),
        .kernel_ddr4d_read            (mem_avmm_bridge[3].read         ),
        .kernel_ddr4d_byteenable      (mem_avmm_bridge[3].byteenable   ),
    `endif

    .kernel_irq_irq                 (kernel_cra_avmm_bridge.kernel_irq),
    .kernel_cra_waitrequest         (kernel_cra_avmm_bridge.kernel_cra_waitrequest),
    .kernel_cra_readdata            (kernel_cra_avmm_bridge.kernel_cra_readdata),
    .kernel_cra_readdatavalid       (kernel_cra_avmm_bridge.kernel_cra_readdatavalid),
    .kernel_cra_burstcount          (kernel_cra_avmm_bridge.kernel_cra_burstcount),
    .kernel_cra_writedata           (kernel_cra_avmm_bridge.kernel_cra_writedata),
    .kernel_cra_address             (kernel_cra_avmm_bridge.kernel_cra_address),
    .kernel_cra_write               (kernel_cra_avmm_bridge.kernel_cra_write),
    .kernel_cra_read                (kernel_cra_avmm_bridge.kernel_cra_read),
    .kernel_cra_byteenable          (kernel_cra_avmm_bridge.kernel_cra_byteenable),
    .kernel_cra_debugaccess         (kernel_cra_avmm_bridge.kernel_cra_debugaccess)
    
    `ifdef INCLUDE_USM_SUPPORT
        ,.kernel_mem_waitrequest    (svm_avmm_bridge.waitrequest),
        .kernel_mem_readdata        (svm_avmm_bridge.readdata),
        .kernel_mem_readdatavalid   (svm_avmm_bridge.readdatavalid),
        .kernel_mem_burstcount      (svm_avmm_bridge.burstcount),
        .kernel_mem_writedata       (svm_avmm_bridge.writedata),
        .kernel_mem_address         ({svm_avmm_bridge.address,svm_addr_shift}),
        .kernel_mem_write           (kernel_system_svm_write),
        .kernel_mem_read            (kernel_system_svm_read),
        .kernel_mem_byteenable      (svm_avmm_bridge.byteenable)
    `endif
);

`ifdef INCLUDE_USM_SUPPORT
    // Higher-level interfaces don't like 'X' during simulation. Drive 0's when not 
    // driven by the kernel-system.
    always_comb begin
        //drive with the value from the kernel-system by default
        svm_avmm_bridge.write = kernel_system_svm_write;
        svm_avmm_bridge.read  = kernel_system_svm_read;
        //drive with the modified version during simulation
    // synthesis translate off
        svm_avmm_bridge.write = kernel_system_svm_write === 'X ? 'b0 : kernel_system_svm_write;
        svm_avmm_bridge.read  = kernel_system_svm_read  === 'X ? 'b0 : kernel_system_svm_read;
    // synthesis translate on
    end
`endif

endmodule : kernel_wrapper
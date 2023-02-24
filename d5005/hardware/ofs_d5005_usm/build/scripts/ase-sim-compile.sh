#!/bin/bash

# (C) 2017 Intel Corporation. All rights reserved.
# Your use of Intel Corporation's design tools, logic functions and other
# software and tools, and its AMPP partner logic functions, and any output
# files any of the foregoing (including device programming or simulation
# files), and any associated documentation or information are expressly subject
# to the terms and conditions of the Intel Program License Subscription
# Agreement, Intel MegaCore Function License Agreement, or other applicable
# license agreement, including, without limitation, that your use is for the
# sole purpose of programming logic devices manufactured by Intel and sold by
# Intel or its authorized distributors.  Please refer to the applicable
# agreement for further details.

echo "Start of sim_compile.sh"

rm -fr sim_files
mkdir sim_files

PROJECT_REVISION="afu_flat"

qsys-generate --synthesis=VERILOG -qpf=d5005 -c=$PROJECT_REVISION board.qsys
#qsys-less flow needs to parse the kernel_system.qip file and grab the files listed therein
KERNEL_SYSTEM_QIP_FILE="./kernel_system.qip"
while IFS= read -r line
do
    ACL_FILE_TO_COPY=$(echo $line | awk '{ print $7 }' | sed 's/"//g' | sed "s|^.*INTELFPGAOCLSDKROOT)|$INTELFPGAOCLSDKROOT|g" | sed 's/]//g')
    cp $ACL_FILE_TO_COPY ./sim_files
done < "$KERNEL_SYSTEM_QIP_FILE"


for this_ip in board kernel_system ddr_board ddr_channel msgdma_bbb ase cci_interface
do
    echo "this-ip is $this_ip"
    find $this_ip -name synth | xargs -n1 -IAAA find AAA -name "*.v" -o -name "*.sv" -o -name "*.iv" | xargs cp -t ./sim_files
    find ip/$this_ip -name synth | xargs -n1 -IAAA find AAA -name "*.v" -o -name "*.sv" -o -name "*.iv" | xargs cp -t ./sim_files
done

find kernel_hdl -type f | xargs cp -t ./sim_files

find . -name "*.vhd" -type f | grep dspba | xargs cp -t ./sim_files
find . -name "*vh" -type f | xargs cp -t  ./sim_files
find ./rtl/ -name "*v" -type f | xargs cp -t  ./sim_files

cp -rf ./ip/*v ./sim_files
#cp -rf ./rtl/*v ./sim_files
cp -fr ./ip/BBB_* sim_files/

cp -rf mem_sim_model.sv ./sim_files/mem_sim_model.sv

find *.sv  | xargs cp -t ./sim_files

cp -rf ./*v ./sim_files/
rm simulation.tar.gz
tar -hzcvf simulation.tar.gz sim_files sys_description.hex *.hex 
cp -rf simulation.tar.gz fpga.bin

#copy fpga.bin to parent directory so aoc flow can find it
cp fpga.bin ../

echo "end of sim_compile.sh"
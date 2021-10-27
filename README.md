# RISC-V_pipelined_cpu

A RISC-V cpu with pipelined datapath supporting most RISC-V ISAs


## Description

The datapath design features a 5-stage pipeline structure : \
Instruction Fetch - Instruction decode - Execution - Memory access and memory writeback 

The memroy access hierachy include a L1-L2 cache setup:
L1 caches - Instruction cacche and Data cache \
L2 cache - a single cache with write eviction buffer \
two L1 caches and the L2 cache are connected by an arbiter 

Their orientation are shown below:


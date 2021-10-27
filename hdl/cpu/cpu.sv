`ifndef CPU_SV
`define CPU_SV

import rv32i_types::*;

module cpu(
    input clk,
    input rst,
    // from i-cache
    input rv32i_word icache_rdata,
    input icache_resp,
    // to i-cache
    output [31:0] icache_addr,
    output icache_read,
    // from d-cache
    input rv32i_word dcache_rdata,
    input dcache_resp,
    // to d-cache
    output [31:0] dcache_addr,
    output dcache_read,
    output dcache_write,
    output [3:0] dcache_byte_en,
    output rv32i_word dcache_wdata
);

// internal signals
// from control to datapath
rv32i_control_word ctl_word;
// from datapath to control
rv32i_funct_word fd_word;
rv32i_funct_word de_word;
rv32i_funct_word em_word;
rv32i_funct_word mw_word;

// instantiate datapath here
datapath DATAPATH(.*);

// instantiate control here
control CONTROL(.*);

endmodule : cpu

`endif
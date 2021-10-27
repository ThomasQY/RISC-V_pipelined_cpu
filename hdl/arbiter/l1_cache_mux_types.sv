`ifndef L1_CACHE_MUX_TYPES_SV
`define L1_CACHE_MUX_TYPES_SV

package arbitermux;
typedef enum bit[1:0]{
    icache  = 2'b00
    ,dcache = 2'b01
    // ,prefetch = 2'b11
} arbitermux_sel_t;
endpackage

package metamux;
typedef enum bit[1:0]{
    nothing  = 2'b00
    ,whit    = 2'b01
    ,wb      = 2'b10
    ,rp      = 2'b11
} metamux_sel_t;
endpackage

`endif

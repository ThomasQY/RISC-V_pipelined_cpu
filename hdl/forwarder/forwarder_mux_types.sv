`ifndef FORWARDER_MUX_TYPES_SV
`define FORWARDER_MUX_TYPES_SV

package forwardermux; 
// NOTE {fd_rs1 == em_rd, fd_rs1 == de_rd}
typedef enum bit [1:0] {
    no_hazard      = 2'b00
    ,ex_hazard     = 2'b01
    ,mem_hazard    = 2'b10
    ,double_hazard = 2'b11
} forwardermux_sel_t;
endpackage

`endif
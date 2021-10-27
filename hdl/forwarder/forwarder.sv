`ifndef FORWARDER_SV
`define FORWARDER_SV

`define BAD_MUX_SEL $fatal("%0t %s %0d: Illegal mux select", $time, `__FILE__, `__LINE__)
import rv32i_types::*;
import forwardermux::*;

module forwarder(
    input [31:0] de_rs1_latch_out, de_rs2_latch_out,
    input [31:0] em_alu_latch_out,
    input [31:0] regfilemux_out, // FIXME use regfilemux_out instead
    input [4:0] de_rs1, de_rs2,
    input [4:0] em_rd, mw_rd,
    // NOTE store and branch does not load regfile
    input rv32i_opcode em_opcode, mw_opcode,
    // NOTE only forward from valid instructions
    input em_valid_out, mw_valid_out,
    output logic [31:0] rs1_forwarder_out,
    output logic [31:0] rs2_forwarder_out
);

always_comb
begin
    rs1_forwarder_out = de_rs1_latch_out;
    case ({de_rs1 == mw_rd && mw_valid_out &&
           !(mw_opcode == op_br || mw_opcode == op_store || mw_rd == '0),
           de_rs1 == em_rd && em_valid_out &&
           !(em_opcode == op_br || em_opcode == op_store || em_rd == '0)})
        forwardermux::no_hazard:
            rs1_forwarder_out = de_rs1_latch_out;
        forwardermux::ex_hazard:
            rs1_forwarder_out = em_alu_latch_out;
        forwardermux::mem_hazard:
            rs1_forwarder_out = regfilemux_out;
        forwardermux::double_hazard:
            rs1_forwarder_out = em_alu_latch_out;
    endcase

    rs2_forwarder_out = de_rs2_latch_out;
    case ({de_rs2 == mw_rd && mw_valid_out &&
           !(mw_opcode == op_br || mw_opcode == op_store || mw_rd == '0),
           de_rs2 == em_rd && em_valid_out &&
           !(em_opcode == op_br || em_opcode == op_store || em_rd == '0)})
        forwardermux::no_hazard:
            rs2_forwarder_out = de_rs2_latch_out;
        forwardermux::ex_hazard:
            rs2_forwarder_out = em_alu_latch_out;
        forwardermux::mem_hazard:
            rs2_forwarder_out = regfilemux_out;
        forwardermux::double_hazard:
            rs2_forwarder_out = em_alu_latch_out;
    endcase
end



endmodule : forwarder

`endif
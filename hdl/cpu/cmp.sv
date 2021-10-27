`ifndef CMP_SV
`define CMP_SV

import rv32i_types::*;

module cmp
(
    input branch_funct3_t cmpop,
    input [31:0] a, b,
    output logic br_en
);

always_comb
begin
    unique case (cmpop)
        beq:   br_en = (a == b) ? 1'b1:1'b0;
        bne:   br_en = (a != b) ? 1'b1:1'b0;
        blt:   br_en = ($signed(a) <  $signed(b)) ? 1'b1:1'b0;
        bge:   br_en = ($signed(a) >= $signed(b)) ? 1'b1:1'b0;
        bltu:  br_en = (a <  b) ? 1'b1:1'b0;
        bgeu:  br_en = (a >= b) ? 1'b1:1'b0;
        default: br_en = 1'bx;
    endcase
end

endmodule : cmp
`endif

`ifndef CONTROL_SV
`define CONTROL_SV

import rv32i_types::*;

module control(
    // from cache
    input icache_resp,
    input dcache_resp,
    // from datapath
    input rv32i_funct_word fd_word,
    input rv32i_funct_word de_word,
    input rv32i_funct_word em_word,
    input rv32i_funct_word mw_word,
    // to datapath
    output rv32i_control_word ctl_word
);

// internal signals

// instantiate 4 intermediate structs between stages
// if_id_struct, id_ex_struct, ex_mem_struct, mem_wb_struct
function void set_default();
    ctl_word.load_latch = 1'b1;
    // IF stage
    ctl_word.icache_read = 1'b0;
    ctl_word.load_pc = 1'b0;
    // ID stage
    // EX stage
    ctl_word.aluop = alu_add;
    ctl_word.alumux1_sel = alumux::rs1_out;
    ctl_word.alumux2_sel = alumux::rs2_out;
    ctl_word.cmpop = beq;
    ctl_word.cmpmux_sel = cmpmux::rs2_out;
    ctl_word.arithmux_sel = alumux::alu_out;
    ctl_word.iaddrmux_sel = iaddrmux::always_pc;
    // MEM stage
    ctl_word.dcache_write = 1'b0;
    ctl_word.dcache_read = 1'b0;
    // WB stage
    ctl_word.regfilemux_sel = regfilemux::alu_out;
    ctl_word.load_regfile = 1'b0;
endfunction

// TODO IF stage comb function
function void if_stage();
    // TODO control icache_read
   ctl_word.icache_read = 1'b1;
   ctl_word.load_pc     = 1'b1;
endfunction

// TODO ID stage comb function
function void id_stage(rv32i_funct_word fd_word);

endfunction

// TODO EX stage comb function
function void set_imm(arith_funct3_t funct3, logic bit30);
    case(arith_funct3_t'(funct3))
        slt:  ctl_word.cmpop = blt;
        sltu: ctl_word.cmpop = bltu;
        sr: begin //check bit30 for logical/arithmetic
            if(bit30) //SRA
                ctl_word.aluop = alu_sra;
            else //SRL
                ctl_word.aluop = alu_srl;
        end
        add, sll, axor, aor, aand:
            ctl_word.aluop = alu_ops'(funct3);
    endcase
endfunction

function void set_reg(arith_funct3_t funct3, logic bit30);
    case(arith_funct3_t'(funct3))
        slt:  ctl_word.cmpop = blt;
        sltu: ctl_word.cmpop = bltu;
        sr: begin //check bit30 for logical/arithmetic
            if(bit30) //SRA
                ctl_word.aluop = alu_sra;
            else //SRL
                ctl_word.aluop = alu_srl;
        end
        add: begin //check bit30 for sub if op_reg opcode
            if(bit30) // SUB
                ctl_word.aluop = alu_sub;
            else // ADD
                ctl_word.aluop = alu_add;
        end
        sll, axor, aor, aand:
            ctl_word.aluop = alu_ops'(funct3);
    endcase
endfunction

function void ex_stage(rv32i_funct_word de_word);
    if(!de_word.word_valid) return; // invalid, use default value
    case(de_word.opcode)
        op_lui: begin
            // nothing to do
        end
        op_auipc: begin
            ctl_word.alumux1_sel = alumux::pc_out;
            ctl_word.alumux2_sel = alumux::u_imm;
            ctl_word.aluop = alu_add;
        end
        op_jal: begin
            ctl_word.alumux1_sel = alumux::pc_out;
            ctl_word.alumux2_sel = alumux::j_imm;
            ctl_word.aluop = alu_add;
            ctl_word.iaddrmux_sel = iaddrmux::always_alu;
            // NOTE jmp target prediction needs to be added in future
            // ctl_word.fd_valid_ctl = '0;
            // ctl_word.de_valid_ctl = '0;
        end
        op_jalr: begin
            ctl_word.alumux1_sel = alumux::rs1_out;
            ctl_word.alumux2_sel = alumux::i_imm;
            ctl_word.aluop = alu_add;
            ctl_word.iaddrmux_sel = iaddrmux::always_alu;
            // NOTE jmp target prediction needs to be added in future
            // NOTE return target prediction needs to be added in future
            // ctl_word.fd_valid_ctl = '0;
            // ctl_word.de_valid_ctl = '0;
        end
        op_br: begin
            ctl_word.alumux1_sel = alumux::pc_out;
            ctl_word.alumux2_sel = alumux::b_imm;
            ctl_word.aluop = alu_add;
            ctl_word.iaddrmux_sel = iaddrmux::br_en;
            ctl_word.cmpmux_sel = cmpmux::rs2_out;
            ctl_word.cmpop = branch_funct3_t'(de_word.funct3);
            // ctl_word.fd_valid_ctl = '0;
            // ctl_word.de_valid_ctl = '0;
            // NOTE will set branch predictor at this point
        end
        op_load: begin
            ctl_word.alumux1_sel = alumux::rs1_out;
            ctl_word.alumux2_sel = alumux::i_imm;
            ctl_word.aluop = alu_add;
        end
        op_store: begin
            ctl_word.alumux1_sel = alumux::rs1_out;
            ctl_word.alumux2_sel = alumux::s_imm;
            ctl_word.aluop = alu_add;
        end
        op_imm: begin
            ctl_word.alumux1_sel = alumux::rs1_out;
            ctl_word.alumux2_sel = alumux::i_imm;
            ctl_word.cmpmux_sel = cmpmux::i_imm;
            set_imm(arith_funct3_t'(de_word.funct3), de_word.funct7[5]);
            if((arith_funct3_t'(de_word.funct3) == slt)
            || (arith_funct3_t'(de_word.funct3) == sltu))
                ctl_word.arithmux_sel = alumux::cmp_out;
        end
        op_reg: begin
            ctl_word.alumux1_sel = alumux::rs1_out;
            ctl_word.alumux2_sel = alumux::rs2_out;
            ctl_word.cmpmux_sel = cmpmux::rs2_out;
            set_reg(arith_funct3_t'(de_word.funct3), de_word.funct7[5]);
            if((arith_funct3_t'(de_word.funct3) == slt)
            || (arith_funct3_t'(de_word.funct3) == sltu))
                ctl_word.arithmux_sel = alumux::cmp_out;
        end
        // op_csr: begin

        // end
        default:;
    endcase
endfunction

// TODO MEM stage comb function
function void mem_stage(rv32i_funct_word em_word);
    if(!em_word.word_valid) return; // invalid, use default value
    case(em_word.opcode)
        op_store: ctl_word.dcache_write = 1'b1;
        op_load:  ctl_word.dcache_read  = 1'b1;
        default:;
    endcase
endfunction

// TODO WB stage comb function
function void wb_stage(rv32i_funct_word mw_word);
    if(!mw_word.word_valid) return; // invalid, use default value
    case(mw_word.opcode)
        op_lui: begin
            ctl_word.regfilemux_sel = regfilemux::u_imm;
            ctl_word.load_regfile = 1'b1;
        end
        op_auipc: begin
            ctl_word.regfilemux_sel = regfilemux::alu_out;
            ctl_word.load_regfile = 1'b1;
        end
        op_jal, op_jalr: begin
            ctl_word.regfilemux_sel = regfilemux::pc_plus4;
            ctl_word.load_regfile = 1'b1;
        end
        op_load: begin
            unique case(load_funct3_t'(mw_word.funct3))
                lb : ctl_word.regfilemux_sel = regfilemux::lb;
                lh : ctl_word.regfilemux_sel = regfilemux::lh;
                lw : ctl_word.regfilemux_sel = regfilemux::lw;
                lbu: ctl_word.regfilemux_sel = regfilemux::lbu;
                lhu: ctl_word.regfilemux_sel = regfilemux::lhu;
            endcase
            ctl_word.load_regfile = 1'b1;
        end
        op_imm, op_reg: begin
            ctl_word.regfilemux_sel = regfilemux::alu_out;
            ctl_word.load_regfile = 1'b1;
        end
        // op_br
        // op_store
        // op_csr
        default:;
    endcase
endfunction

always_comb begin
    // send control signals according to each stage's struct
    // NOTE use functions, and do nothing if struct is invalidate, unless it's IF stage
    set_default();
    // TODO IF stage
    if_stage();
    // TODO ID stage
    // NOTE will do branch prediction in this stage
    // NOTE will change pc according to prediction when this stage is finished

    // TODO EX stage
    // NOTE will change pc if prediction is wrong
    // NOTE will invalidate previous structs is prediction is wrong
    ex_stage(de_word);

    // TODO MEM stage
    mem_stage(em_word);

    // TODO WB stage
    wb_stage(mw_word);

    // stalling the pipeline when cache does not respond
    if((!icache_resp && ctl_word.icache_read) || (!dcache_resp && (ctl_word.dcache_read || ctl_word.dcache_write))) begin
        ctl_word.load_latch   = 1'b0;
        ctl_word.load_pc      = 1'b0;
        ctl_word.load_regfile = 1'b0;
    end
end

endmodule : control

`endif

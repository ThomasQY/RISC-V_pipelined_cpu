`ifndef ILATCH_SV
`define ILATCH_SV

import rv32i_types::*;

module ilatch
(
    input clk,
    input rst,
    input load,
    input valid_in, // from previous latch
    input valid_ctl, // from control
    input [31:0] instr_latch_in,
    input [31:0] pc_latch_in,
    input [31:0] rs1_latch_in,
    input [31:0] rs2_latch_in,
    input [31:0] alu_latch_in,
    input [31:0] dc_latch_in,

    // decoded output
    output [2:0] funct3,
    output [6:0] funct7,
    output rv32i_opcode opcode,
    output [31:0] i_imm,
    output [31:0] s_imm,
    output [31:0] b_imm,
    output [31:0] u_imm,
    output [31:0] j_imm,
    output [4:0] rs1,
    output [4:0] rs2,
    output [4:0] rd,

    // pass to next latch
    output valid_out,
    output [31:0] instr_latch_out,
    output [31:0] pc_latch_out,
    output [31:0] rs1_latch_out,
    output [31:0] rs2_latch_out,
    output [31:0] alu_latch_out,
    output [31:0] dc_latch_out
);

logic valid_hold;
logic [31:0] instr_data, pc_data, rs1_data, rs2_data, alu_data, dc_data;

// decode logic
assign funct3 = instr_data[14:12];
assign funct7 = instr_data[31:25];
assign opcode = rv32i_opcode'(instr_data[6:0]);
assign i_imm = {{21{instr_data[31]}}, instr_data[30:20]};
assign s_imm = {{21{instr_data[31]}}, instr_data[30:25], instr_data[11:7]};
assign b_imm = {{20{instr_data[31]}}, instr_data[7], instr_data[30:25], instr_data[11:8], 1'b0};
assign u_imm = {instr_data[31:12], 12'h000};
assign j_imm = {{12{instr_data[31]}}, instr_data[19:12], instr_data[20], instr_data[30:21], 1'b0};
assign rs1 = instr_data[19:15];
assign rs2 = instr_data[24:20];
assign rd = instr_data[11:7];

// pass to next latch
assign valid_out = valid_hold;
assign instr_latch_out = instr_data;
assign pc_latch_out = pc_data;
assign rs1_latch_out = rs1_data;
assign rs2_latch_out = rs2_data;
assign alu_latch_out = alu_data;
assign dc_latch_out = dc_data;

// hold logic
always_ff @(posedge clk)
begin
    // NOTE to invalidate a latch, need valid_in to be
    // valid_out from previous latch && valid from control
    if (rst)
    begin
        valid_hold <= '0;
        instr_data <= '0;
        pc_data <= '0;
        rs1_data <= '0;
        rs2_data <= '0;
        alu_data <= '0;
        dc_data <= '0;
    end
    else if (load == 1)
    begin
        valid_hold <= valid_in & valid_ctl;
        instr_data <= instr_latch_in;
        pc_data <= pc_latch_in;
        rs1_data <= rs1_latch_in;
        rs2_data <= rs2_latch_in;
        alu_data <= alu_latch_in;
        dc_data <= dc_latch_in;
    end
    else
    begin
        valid_hold <= valid_hold;
        instr_data <= instr_data;
        pc_data <= pc_data;
        rs1_data <= rs1_data;
        rs2_data <= rs2_data;
        alu_data <= alu_data;
        dc_data <= dc_data;
    end
end

endmodule : ilatch

`endif
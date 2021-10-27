import rv32i_types::*;
module mp3_tb;
`timescale 1ns/10ps

/********************* Do not touch for proper compilation *******************/
// Instantiate Interfaces
tb_itf itf();
rvfi_itf rvfi(itf.clk, itf.rst);

// Instantiate Testbench
source_tb tb(
    .magic_mem_itf(itf),
    .mem_itf(itf),
    .sm_itf(itf),
    .tb_itf(itf),
    .rvfi(rvfi)
);
/****************************** End do not touch *****************************/

/************************ Signals necessary for monitor **********************/
// This section not required until CP3
logic trap;
logic [3:0] rmask, wmask;
logic [1:0] mem_select;
rv32i_opcode opcode;
logic [31:0] mem_rdata, mem_wdata;

branch_funct3_t branch_funct3;
store_funct3_t store_funct3;
load_funct3_t load_funct3;
arith_funct3_t arith_funct3;

assign arith_funct3 = arith_funct3_t'(dut.CPU.DATAPATH.mw_funct3);
assign branch_funct3 = branch_funct3_t'(dut.CPU.DATAPATH.mw_funct3);
assign load_funct3 = load_funct3_t'(dut.CPU.DATAPATH.mw_funct3);
assign store_funct3 = store_funct3_t'(dut.CPU.DATAPATH.mw_funct3);
assign opcode = dut.CPU.DATAPATH.mw_opcode;
assign mem_select = dut.CPU.DATAPATH.mw_alu_latch_out[1:0];

always_comb
begin : trap_check
    trap = 0;
    rmask = '0;
    wmask = '0;
    mem_rdata = dut.CPU.DATAPATH.mw_dc_latch_out;
    mem_wdata = dut.CPU.DATAPATH.mw_rs2_latch_out;

    case (opcode)
        op_lui, op_auipc, op_imm, op_reg, op_jal, op_jalr:;

        op_br: begin
            case (branch_funct3)
                beq, bne, blt, bge, bltu, bgeu:;
                default: trap = 1;
            endcase
        end

        op_load: begin
            case (load_funct3)
                lw: rmask = 4'b1111;
                lh:
                case(mem_select[1])
                    1'b0: rmask = 4'b0011;
                    1'b1: begin
                        rmask = 4'b1100;
                        mem_rdata = mem_rdata >>> 16;
                    end
                endcase
                lhu:
                case(mem_select[1])
                    1'b0: rmask = 4'b0011;
                    1'b1: begin
                        rmask = 4'b1100;
                        mem_rdata = mem_rdata >> 16;
                    end
                endcase
                lb:
                case(mem_select)
                    2'b00: rmask = 4'b0001;
                    2'b01: begin
                        rmask = 4'b0010;
                        mem_rdata = mem_rdata >>> 8;
                    end
                    2'b10: begin
                        rmask = 4'b0100;
                        mem_rdata = mem_rdata >>> 16;
                    end
                    2'b11: begin
                        rmask = 4'b1000;
                        mem_rdata = mem_rdata >>> 24;
                    end
                endcase
                lbu:
                case(mem_select)
                    2'b00: rmask = 4'b0001;
                    2'b01: begin
                        rmask = 4'b0010;
                        mem_rdata = mem_rdata >> 8;
                    end
                    2'b10: begin
                        rmask = 4'b0100;
                        mem_rdata = mem_rdata >> 16;
                    end
                    2'b11: begin
                        rmask = 4'b1000;
                        mem_rdata = mem_rdata >> 24;
                    end
                endcase
                default: trap = 1;
            endcase
        end

        op_store: begin
            case (store_funct3)
                sw: wmask = 4'b1111;
                sh:// wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                case(mem_select[1])
                    1'b0: wmask = 4'b0011;
                    1'b1: begin
                        wmask = 4'b1100;
                        mem_wdata = mem_wdata << 16;
                    end
                endcase
                sb:// wmask = 4'bXXXX /* Modify for MP1 Final */ ;
                case(mem_select)
                    2'b00: wmask = 4'b0001;
                    2'b01: begin
                        wmask = 4'b0010;
                        mem_wdata = mem_wdata << 8;
                    end
                    2'b10: begin
                        wmask = 4'b0100;
                        mem_wdata = mem_wdata << 16;
                    end
                    2'b11: begin
                        wmask = 4'b1000;
                        mem_wdata = mem_wdata << 24;
                    end
                endcase
                default: trap = 1;
            endcase
        end

        default: trap = 1;
    endcase
end

logic [31:0] pc_mem, pc_wb;
//pcmux_out
always @(posedge itf.clk iff dut.CPU.ctl_word.load_latch ) begin
    pc_mem <= dut.CPU.DATAPATH.pcmux_out;
    pc_wb  <= pc_mem;
end

assign rvfi.clk = itf.clk;
assign rvfi.rst = itf.rst;
assign rvfi.commit = dut.CPU.DATAPATH.mw_valid_out &
                     dut.CPU.ctl_word.load_latch; // Set high when a valid instruction is modifying regfile or PC
// FIXME potential wrong halt in very small loop
assign rvfi.halt = dut.CPU.DATAPATH.ctl_word.load_pc
                        &(dut.CPU.DATAPATH.fd_pc_latch_out == dut.CPU.DATAPATH.mw_pc_latch_out)
                        &(dut.CPU.DATAPATH.fd_pc_latch_out != '0);   // Set high when you detect an infinite loop
initial rvfi.order = 0;
always @(posedge itf.clk iff rvfi.commit) rvfi.order <= rvfi.order + 1; // Modify for OoO
assign rvfi.inst = dut.CPU.DATAPATH.mw_instr_latch_out;
assign rvfi.trap = trap; // FIXME
assign rvfi.rs1_addr = dut.CPU.DATAPATH.mw_rs1;
assign rvfi.rs2_addr = dut.CPU.DATAPATH.mw_rs2;
assign rvfi.rs1_rdata = dut.CPU.DATAPATH.mw_rs1_latch_out;
assign rvfi.rs2_rdata = dut.CPU.DATAPATH.mw_rs2_latch_out;
assign rvfi.load_regfile = dut.CPU.ctl_word.load_regfile;
assign rvfi.rd_addr = dut.CPU.DATAPATH.mw_rd;
assign rvfi.rd_wdata = dut.CPU.DATAPATH.mw_rd?
    dut.CPU.DATAPATH.regfilemux_out:'0;
assign rvfi.pc_rdata = dut.CPU.DATAPATH.mw_pc_latch_out;
assign rvfi.pc_wdata = dut.CPU.DATAPATH.em_valid_out? dut.CPU.DATAPATH.em_pc_latch_out:
    (dut.CPU.DATAPATH.de_valid_out? dut.CPU.DATAPATH.de_pc_latch_out :dut.CPU.DATAPATH.fd_pc_latch_out); // FIXME
assign rvfi.mem_addr = dut.CPU.DATAPATH.mw_alu_latch_out; // FIXME for dcache only?
assign rvfi.mem_rmask = rmask; // FIXME
assign rvfi.mem_wmask = wmask; // FIXME
assign rvfi.mem_rdata = dut.CPU.DATAPATH.mw_dc_latch_out; // FIXME for dcache only?
assign rvfi.mem_wdata = mem_wdata; // FIXME for dcache only?

/**************************** End RVFIMON signals ****************************/

/********************* Assign Shadow Memory Signals Here *********************/
// This section not required until CP2
assign itf.inst_read = dut.CPU.icache_read;
assign itf.inst_addr = dut.CPU.icache_addr;
assign itf.inst_resp = dut.ICACHE.mem_resp & dut.CPU.ctl_word.load_pc;
assign itf.inst_rdata = dut.ICACHE.mem_rdata;

assign itf.data_read = dut.CPU.dcache_read;
assign itf.data_write = dut.CPU.dcache_write;
assign itf.data_mbe = dut.CPU.dcache_byte_en;
assign itf.data_addr = dut.CPU.dcache_addr;
assign itf.data_wdata = dut.CPU.dcache_wdata;
assign itf.data_resp = dut.DCACHE.mem_resp & dut.CPU.ctl_word.load_pc;
assign itf.data_rdata = dut.DCACHE.mem_rdata;

/*********************** End Shadow Memory Assignments ***********************/

// Set this to the proper value
assign itf.registers = dut.CPU.DATAPATH.REGFILE.data;
bit halt;
assign halt = dut.CPU.DATAPATH.ctl_word.load_pc&(dut.CPU.DATAPATH.de_pc_latch_out == dut.CPU.DATAPATH.pcmux_out);
bit clk;
assign clk = itf.clk;

/*********************** Instantiate your design here ************************/
mp3 dut(
    .clk            (itf.clk),
    .rst            (itf.rst),
    .pmem_rdata64   (itf.mem_rdata),
    .pmem_resp      (itf.mem_resp),
    .pmem_read      (itf.mem_read),
    .pmem_write     (itf.mem_write),
    .pmem_address   (itf.mem_addr),
    .pmem_wdata64   (itf.mem_wdata)
);
/***************************** End Instantiation *****************************/

endmodule
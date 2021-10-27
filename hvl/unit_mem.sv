module unit_mem
(
    input  clk,
    input  rst,
    output logic [255:0] pmem_rdata,
    input  [255:0] pmem_wdata,
    input  [31:0] pmem_address,
    input  pmem_read,
    input  pmem_write,
    output logic pmem_resp
);

localparam bits = 8;
logic [255:0] data [2**bits]; // cover all addresses
logic [255:0] data_out;

assign pmem_rdata = data_out;

enum int unsigned {
    IDEL, READ, WRITE, DONE
} state_crt, state_nxt;

always_comb
begin
    pmem_resp = 1'b0;
    state_nxt = state_crt;
    unique case(state_crt)
    IDEL: begin
        if(pmem_read) state_nxt = READ;
        if(pmem_write) state_nxt = WRITE;
    end
    READ, WRITE: begin
        state_nxt = DONE;
    end
    DONE: begin
        pmem_resp = 1'b1;
        state_nxt = IDEL;
    end
	 endcase
end

always_ff @(posedge clk)
begin
    state_crt <= state_nxt;
    if(state_crt==READ) data_out <= data[pmem_address[31:5]];
    if(state_crt==WRITE) data[pmem_address[31:5]] <= pmem_wdata;
    if (rst) begin
        state_crt <= IDEL;
        for (int i = 0; i < 2**bits; ++i)
            for (int j = 0; j < 8; ++j)
                data[i][(j*32+31)-:32] <= $urandom();
    end
end

endmodule
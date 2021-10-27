`ifndef EW_BUFFER_SV
`define EW_BUFFER_SV

import l1_cache_types::*;

module ew_buffer(
    input clk,
    input rst,
    // interface l2 cache
    input  l1_cache_request  l2cache_request,
    output l1_cache_feedback l2cache_feedback,
    // interface cacheline adapter
    output l1_cache_request  ewb_request,
    input  l1_cache_feedback ewb_feedback
);

logic[255:0] data_line;
logic[ 31:0] data_addr;
enum logic [2:0] {
    IDLE, DREAD, WRESP, WREAD, WRITE
} state;

always_ff @(posedge clk) begin
    unique case(state)
        IDLE: begin
            l2cache_feedback.mem_resp <= '0;
            if(l2cache_request.mem_read) begin
                state <= DREAD;
                ewb_request <= l2cache_request;
            end
            else if(l2cache_request.mem_write) begin
                state <= WRESP;
                data_line <= l2cache_request.mem_wdata256;
                data_addr <= l2cache_request.mem_addr;
                l2cache_feedback.mem_resp <= 1'b1;
            end
        end
        DREAD: begin
            if(ewb_feedback.mem_resp) begin
                state <= IDLE;
                l2cache_feedback <= ewb_feedback;
                ewb_request.mem_read <= '0;
            end
        end
        WRESP: begin
            l2cache_feedback.mem_resp <= '0;
            if(l2cache_request.mem_read) begin
                state <= WREAD;
                ewb_request <= l2cache_request;
            end
        end
        WREAD: begin
            if(ewb_feedback.mem_resp) begin
                state <= WRITE;
                l2cache_feedback <= ewb_feedback;

                ewb_request.mem_read <= '0;
                ewb_request.mem_write <= 1'b1;
                ewb_request.mem_addr  <= data_addr;
                ewb_request.mem_wdata256 <= data_line;
            end
        end
        WRITE: begin
            l2cache_feedback.mem_resp <= '0;
            if(ewb_feedback.mem_resp) begin
                state <= IDLE;
                ewb_request.mem_write <= '0;
            end            
        end
    endcase
    if (rst) begin
        state <= IDLE;
        data_line <= '0;
        data_addr <= '0;
        l2cache_feedback.mem_resp     = '0;
        l2cache_feedback.mem_rdata256 = '0;
        ewb_request.mem_addr          = '0;
        ewb_request.mem_read          = '0;
        ewb_request.mem_write         = '0;
        ewb_request.mem_wdata256      = '0; 
    end
end

endmodule : ew_buffer

`endif
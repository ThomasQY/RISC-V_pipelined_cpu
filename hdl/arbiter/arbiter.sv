`ifndef ARBITER_SV
`define ARBITER_SV

import l1_cache_types::*;

module arbiter(
    input clk,
    input rst,
    // icache -> arbiter
    input l1_cache_request icache_request,
    // arbiter -> icache
    output l1_cache_feedback icache_feedback,
    // dcache -> arbiter
    input l1_cache_request dcache_request,
    // arbiter -> dcache
    output l1_cache_feedback dcache_feedback,
    // arbiter -> L2 cache
    output l1_cache_request arbiter_request,
    // L2 cache -> arbiter
    input l1_cache_feedback arbiter_feedback
);

enum logic [2:0] {
    IDLE, IREAD, DREAD, DWRITE, RRESP, WRESP
} state;

always_ff @(posedge clk) begin
    unique case(state)
        IDLE: begin
            if(icache_request.mem_read) begin
                state <= IREAD;
                arbiter_request <= icache_request;
            end
            else if(dcache_request.mem_read) begin
                state <= DREAD;
                arbiter_request <= dcache_request;
            end
            else if(dcache_request.mem_write) begin
                state <= DWRITE;
                arbiter_request <= dcache_request;
            end
        end
        IREAD: begin
            if(arbiter_feedback.mem_resp) begin
                state <= RRESP;
                icache_feedback <= arbiter_feedback;
                // keep reading to prefetch
                arbiter_request.mem_addr <= icache_request.mem_addr + 32'd32;
            end
        end
        DREAD: begin
            if(arbiter_feedback.mem_resp) begin
                state <= RRESP;
                dcache_feedback <= arbiter_feedback;
                // keep reading to prefetch
                arbiter_request.mem_addr <= dcache_request.mem_addr + 32'd32;
            end
        end
        DWRITE: begin
            if(arbiter_feedback.mem_resp) begin
                state <= WRESP;
                dcache_feedback <= arbiter_feedback;
            end
        end
        RRESP: begin
            icache_feedback.mem_resp <= '0;
            dcache_feedback.mem_resp <= '0;
            // prefetch
            if(arbiter_feedback.mem_resp) begin
                state <= IDLE;
                arbiter_request.mem_read <= '0; 
            end
        end
        WRESP: begin
            dcache_feedback.mem_resp <= '0;
            if(dcache_request.mem_read) begin
                state <= DREAD;
                arbiter_request <= dcache_request;
            end
        end
    endcase
    if(rst) begin
        icache_feedback.mem_resp     <= '0;
        icache_feedback.mem_rdata256 <= '0;
        dcache_feedback.mem_resp     <= '0;
        dcache_feedback.mem_rdata256 <= '0;
        arbiter_request.mem_read     <= '0;
        arbiter_request.mem_write    <= '0;
        arbiter_request.mem_addr     <= '0;
        arbiter_request.mem_wdata256 <= '0;
        state <= IDLE;
    end
end

endmodule : arbiter

`endif
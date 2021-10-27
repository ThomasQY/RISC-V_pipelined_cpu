`ifndef CACHE_CONTROL_SV
`define CACHE_CONTROL_SV

// import l1_cache_types::*;

module cache_control  #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter num_ways = 4
)
(
    input clk,
    input rst,
    // interface datapath
    input  hit,
    input  lru_valid_dirty,
    output logic addr_sel,
    output logic [1:0] cache_in_sel,
    output logic [1:0] metamux_sel,
    output logic lru_itf_load,
    // interface cacheline_adapter
    output logic cl_read,
    output logic cl_write,
    input  cl_resp,
    // interface cpu
    input mem_write,
    input mem_read,
    output logic mem_resp
);

enum int unsigned {
    CHECK, WB, RP
} state_crt, state_nxt;

function void set_defaults();
    //TODO
    addr_sel  = 1'b0;
    cache_in_sel = 2'b00;
    metamux_sel = 2'b00;
    lru_itf_load = 1'b0;
    // to cacheline adapter / l2 cache
    cl_read = 1'b0;
    cl_write = 1'b0;
    // to cpu
    mem_resp = 1'b0;
endfunction


// current state action
always_comb
begin: current_state_action
    set_defaults();
    case(state_crt)
        CHECK: begin
            if(mem_read  | mem_write) begin // have request
                if(hit) begin // hit
                    mem_resp = 1'b1;
                    lru_itf_load = 1'b1;
                    if(mem_write) begin // mem_write
                        cache_in_sel = 2'b10; // use bus_adaptor
                        metamux_sel = 2'b01; // set dirty
                    end
                end
                else begin // miss
                    // check dirty of lru
                    if(lru_valid_dirty) begin // need write back
                        // cl_write = 1'b1;
                        addr_sel = 1'b1;
                    end
                    else begin // need read pmem
                        cache_in_sel = 2'b11; // from cl_adaptor
                        // cl_read = 1'b1;
                    end
                end
            end
        end
        WB: begin
        // set way select for cacheline adaptor mux
        // set cl_write
        // keeping the read of cache_data, and index
            cl_write = 1'b1;
            addr_sel = 1'b1;
            if(cl_resp) begin // clear dirty
                metamux_sel = 2'b10;
            end 
        end
        RP: begin
        // set way select for cacheline adaptor mux
        // set cl_read
        // set write of cache_data, and index
            cache_in_sel = 2'b11; // from cl_adaptor
            cl_read = 1'b1;
            if(cl_resp) begin // changing tag, set valid
                metamux_sel = 2'b11;
            end 
        end
    endcase
end


// next state logic
always_comb
begin: next_state_logic
    case(state_crt)
        CHECK: begin
            if(hit | (~mem_read  & ~mem_write)) // hit
                state_nxt = CHECK;
            else begin // miss
                if(lru_valid_dirty) // dirty
                    state_nxt = WB;
                else
                    state_nxt = RP;
            end
        end
        WB: begin
            if(cl_resp) state_nxt = RP;
            else state_nxt = WB;
        end
        RP: begin
            if(cl_resp) state_nxt = CHECK;
            else state_nxt = RP;
        end
    endcase
end


// assigning next state
always_ff @(posedge clk)
begin: next_state_assignment
    /* Assignment of next state on clock edge */
    state_crt <= state_nxt;
    if(rst) begin
        state_crt <= CHECK;
    end
end
endmodule : cache_control

`endif
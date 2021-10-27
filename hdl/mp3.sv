`ifndef MP3_SV
`define MP3_SV

import rv32i_types::*;
import l1_cache_types::*;

module mp3(
    input clk,
    input rst,
    // from l2 cache
    input [63:0] pmem_rdata64,
    input pmem_resp,
    // to l2 cache
    output logic pmem_read,
    output logic pmem_write,
    output logic [31:0] pmem_address,
    output [63:0] pmem_wdata64
);

// internal signals
rv32i_word icache_rdata;
logic [31:0] icache_addr;
logic icache_read;
logic icache_resp;

rv32i_word dcache_rdata;
logic [31:0] dcache_addr;
logic dcache_read;
logic dcache_write;
logic [3:0] dcache_byte_en;
rv32i_word dcache_wdata;
logic dcache_resp;

l1_cache_request  icache_request;
l1_cache_feedback icache_feedback;
l1_cache_request  dcache_request;
l1_cache_feedback dcache_feedback;
l1_cache_request  arbiter_request;
l1_cache_feedback arbiter_feedback;
l1_cache_request  l2cache_request;
l1_cache_feedback l2cache_feedback;
l1_cache_request  ewb_request;
l1_cache_feedback ewb_feedback;

logic cacheline_adaptor_read;
logic cacheline_adaptor_write;
logic cacheline_adaptor_resp;
logic [31:0] cacheline_adaptor_address;
logic [255:0] pmem_wdata256;
logic [255:0] pmem_rdata256;

// instantiate cpu here
cpu CPU(.*);

// instantiate L1 cache here
cache ICACHE(
    .clk(clk),
    .rst(rst),
    //interface cpu
    .mem_resp(icache_resp),
    .mem_rdata(icache_rdata),
    .mem_read(icache_read),
    .mem_write('0),
    .mem_byte_enable('0),
    .mem_address(icache_addr),
    .mem_wdata('0),
    //interface arbiter
    .pmem_rdata(icache_feedback.mem_rdata256),
    .pmem_wdata(icache_request.mem_wdata256),
    .pmem_address(icache_request.mem_addr),
    .pmem_read(icache_request.mem_read),
    .pmem_write(icache_request.mem_write),
    .pmem_resp(icache_feedback.mem_resp)
);

cache DCACHE(
    .clk(clk),
    .rst(rst),
    //interface cpu
    .mem_resp(dcache_resp),
    .mem_rdata(dcache_rdata),
    .mem_read(dcache_read),
    .mem_write(dcache_write),
    .mem_byte_enable(dcache_byte_en),
    .mem_address(dcache_addr),
    .mem_wdata(dcache_wdata),
    //interface arbiter
    .pmem_rdata(dcache_feedback.mem_rdata256),
    .pmem_wdata(dcache_request.mem_wdata256),
    .pmem_address(dcache_request.mem_addr),
    .pmem_read(dcache_request.mem_read),
    .pmem_write(dcache_request.mem_write),
    .pmem_resp(dcache_feedback.mem_resp)
);

// instantiate arbiter here
arbiter ARBITER(.*);

cache_l2 CACHE_L2(
    .clk(clk),
    .rst(rst),
    //interface arbiter
    .mem_resp(arbiter_feedback.mem_resp),
    .mem_rdata256(arbiter_feedback.mem_rdata256),
    .mem_read(arbiter_request.mem_read),
    .mem_write(arbiter_request.mem_write),
    .mem_address(arbiter_request.mem_addr),
    .mem_wdata256(arbiter_request.mem_wdata256),
    //interface cacheline adapter
    .pmem_rdata(l2cache_feedback.mem_rdata256),
    .pmem_wdata(l2cache_request.mem_wdata256),
    .pmem_address(l2cache_request.mem_addr),
    .pmem_read(l2cache_request.mem_read),
    .pmem_write(l2cache_request.mem_write),
    .pmem_resp(l2cache_feedback.mem_resp)
);

ew_buffer EW_BUFFER(.*);

// instantiate cacheline adaptor here
cacheline_adaptor CACHELINE_ADAPTOR(
    .clk,
    .reset_n(!rst),
    // to arbiter
    .line_i(ewb_request.mem_wdata256),                     // i
    .line_o(ewb_feedback.mem_rdata256),                     // o
    .address_i(ewb_request.mem_addr),      // i
    .read_i(ewb_request.mem_read),            // i
    .write_i(ewb_request.mem_write),          // i
    .resp_o(ewb_feedback.mem_resp),            // o
    // to pmem
    .burst_i(pmem_rdata64),                     // i
    .burst_o(pmem_wdata64),                     // o
    .address_o(pmem_address),                   // o
    .read_o(pmem_read),                         // o
    .write_o(pmem_write),                       // o
    .resp_i(pmem_resp)                          // i
);

// instantiate L2 cache here

endmodule : mp3

`endif
`ifndef CACHE_L2_SV
`define CACHE_L2_SV

module cache_l2 #(
    parameter s_offset = 5,
    parameter s_index  = 4,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter num_ways = 4
)
(
    input clk,
    input rst,
    //interface cpu
    output mem_resp,
    output [s_line-1:0] mem_rdata256,
    input  logic mem_read,
    input  logic mem_write,
    input  [31:0] mem_address,
    input  [s_line-1:0] mem_wdata256,
    //interface cl_adaptor
    input  [255:0] pmem_rdata,
    output [255:0] pmem_wdata,
    output  logic [31:0] pmem_address,
    output pmem_read,
    output pmem_write,
    input  pmem_resp
);

// AUTO GRADER TRASH
logic [255:0] cl_rdata256, cl_wdata256;
logic [31:0] cl_address;
logic cl_read, cl_write, cl_resp;

assign cl_rdata256 = pmem_rdata;
assign pmem_wdata = cl_wdata256;
assign pmem_address = cl_address;
assign pmem_read = cl_read;
assign pmem_write = cl_write;
assign cl_resp = pmem_resp;

// internal connection
// control and datapath
logic hit, lru_valid_dirty, addr_sel, lru_itf_load;
logic [1:0] cache_in_sel, metamux_sel;
//datapath and bus_adapter
logic [s_mask-1:0]  mem_byte_enable256;
assign mem_byte_enable256 = {s_mask{1'b1}};

// NOTE currently using l1 cache control and datapath
// might need to change in the future
cache_control #(s_offset, s_index, s_tag, s_mask, s_line, num_sets, num_ways)
CACHE_CONTROL
(
    .*
    // .mem_write(in_write),
    // .mem_read(in_read)
);

cache_datapath #(s_offset, s_index, s_tag, s_mask, s_line, num_sets, num_ways)
CACHE_DATAPATH
(
    .*
    // .mem_address(in_address)
);

endmodule : cache_l2

`endif

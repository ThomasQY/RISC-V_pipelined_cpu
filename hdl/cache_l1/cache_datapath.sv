`ifndef CACHE_DATAPATH_SV
`define CACHE_DATAPATH_SV

// import l1_cache_types::*;

module cache_datapath #(
    parameter s_offset = 5,
    parameter s_index  = 3,
    parameter s_tag    = 32 - s_offset - s_index,
    parameter s_mask   = 2**s_offset,
    parameter s_line   = 8*s_mask,
    parameter num_sets = 2**s_index,
    parameter num_ways = 4
)
(
    input  clk,
    input  rst,
    // interface cache_control
    output logic hit,
    output logic lru_valid_dirty,
    input  addr_sel,
    input [1:0] cache_in_sel,
    input [1:0] metamux_sel,
    input lru_itf_load,
    // interface bus_adapter
    input  logic [31:0] mem_byte_enable256,
    input  logic [s_line-1:0] mem_wdata256,
    output logic [s_line-1:0] mem_rdata256,
    // interface cacheline_adaptor
    input  logic [s_line-1:0] cl_rdata256,
    output logic [s_line-1:0] cl_wdata256,
    output logic [31:0]  cl_address,
    // interface cpu
    input  logic [31:0]  mem_address
);
logic [s_index-1:0] index;
assign index = mem_address[s_offset+s_index-1:s_offset];
logic [1:0] lru_way, hit_way;

// logic lru_itf_load;
logic [num_ways-2:0] lru_itf_datain;
logic [num_ways-2:0] lru_itf_dataout;

logic md_itf_load   [num_ways];
logic [s_tag+1:0] md_itf_datain;
logic [s_tag+1:0] md_itf_dataout[num_ways];

logic [s_line-1:0] cache_data_datain;
logic [s_line-1:0] cache_data_dataout [num_ways];
logic [s_mask-1:0] cache_data_write_en[num_ways];


// all the data storages
genvar i;
generate
    for(i=0; i<num_ways; i++) begin: gen_meta_data
        // highest bit valid, then dirty, lowest bits tag
        meta_array #(s_index, s_tag+2) meta_data(
            .clk(clk), .rst(rst), .read(1'b1), .load(md_itf_load[i]),
            .index(index),
            .datain(md_itf_datain), .dataout(md_itf_dataout[i])
        );

        data_array #(s_offset, s_index) cache_data(
            .clk(clk), .rst(rst), .read(1'b1), .write_en(cache_data_write_en[i]),
            .index(index),
            .datain(cache_data_datain), .dataout(cache_data_dataout[i])
        );
    end: gen_meta_data
endgenerate

meta_array #(s_index, num_ways-1) lru(
    .clk(clk), .rst(rst), .read(1'b1), .load(lru_itf_load),
    .index(index),
    .datain(lru_itf_datain), .dataout(lru_itf_dataout)
);

// functions
function void set_defaults();
    cl_address = mem_address;
    cache_data_datain = mem_wdata256;
    md_itf_datain = 1'b0;
    // NOTE assign wen and datain for all ways
    for(int i=0; i<num_ways; i++) begin
        md_itf_load[i] = 1'b0;
        cache_data_write_en[i] = {s_mask{1'b0}};
    end
endfunction

function void get_lru_way();
    // NOTE 0 for small, 1 for big
    // should be changed to recursion for further augmentation
    lru_way = 2'd0;
    // NOTE probably should use casex
    casex(lru_itf_dataout)
        3'b00x:
            lru_way = 2'd0;
        3'b01x:
            lru_way = 2'd1;
        3'b1x0:
            lru_way = 2'd2;
        3'b1x1:
            lru_way = 2'd3;
    endcase
endfunction

function void get_lru_in();
    // NOTE 0 for small, 1 for big
    // should be changed to recursion for further augmentation
    case(hit_way)
        2'd0: begin
            lru_itf_datain[0] = 1'b1;
            lru_itf_datain[1] = 1'b1;
            lru_itf_datain[2] = lru_itf_dataout[2];
        end
        2'd1: begin
            lru_itf_datain[0] = 1'b1;
            lru_itf_datain[1] = 1'b0;
            lru_itf_datain[2] = lru_itf_dataout[2];
        end
        2'd2: begin
            lru_itf_datain[0] = 1'b0;
            lru_itf_datain[1] = lru_itf_dataout[1];
            lru_itf_datain[2] = 1'b1;
        end
        2'd3: begin
            lru_itf_datain[0] = 1'b0;
            lru_itf_datain[1] = lru_itf_dataout[1];
            lru_itf_datain[2] = 1'b0;
        end
    endcase
endfunction

function void get_hit();
    hit = '0;
    hit_way = '0;
    for(int i=0; i<num_ways; i++) begin
        // generate hit
        if(md_itf_dataout[i][s_tag+1]&&(md_itf_dataout[i][s_tag-1:0]==mem_address[31-:s_tag])) begin
            hit = 1'b1;
            hit_way = i[1:0];
            break;
        end
    end
endfunction

always_comb
begin
    get_hit();
    get_lru_way();
    get_lru_in();
    set_defaults();
    // direct assignments
    lru_valid_dirty = md_itf_dataout[lru_way][s_tag+1] & md_itf_dataout[lru_way][s_tag];
    // only output to cpu the hit way (if miss, we will come back to this after RP)
    mem_rdata256 = cache_data_dataout[hit_way];
    // write to pmem only when miss, only write lru one
    cl_wdata256 = cache_data_dataout[lru_way];

    unique case(addr_sel)
        1'b0:
            cl_address = mem_address;
        1'b1:
            cl_address = {md_itf_dataout[lru_way][s_tag-1:0], mem_address[s_offset+s_index-1-:s_index],5'd0}; // for write back the lru line
    endcase

    // data_datain mux
    unique case(cache_in_sel)
        2'b10: begin // write hit
            cache_data_datain = mem_wdata256;
            cache_data_write_en[hit_way] = mem_byte_enable256;
        end
        2'b11: begin // for read pmem
            cache_data_datain = cl_rdata256;
            cache_data_write_en[lru_way] = {s_mask{1'b1}};
        end
        default: ; // 2'b0x default not loading
    endcase

    // metamux
    case(metamux_sel)
        // highest bit valid, then dirty, lowest bits tag
        // nothing: ;
        2'b01: begin
            // set dirty
            md_itf_datain = {md_itf_dataout[hit_way][s_tag+1], 1'b1, md_itf_dataout[hit_way][s_tag-1:0]};
            md_itf_load[hit_way] = 1'b1;
        end
        // metamux::wb: begin
        //     // clear  dirty
        //     md_itf_datain = {md_itf_dataout[lru_way][s_tag+1], 1'b0, md_itf_dataout[lru_way][s_tag-1:0]};
        //     md_itf_load[lru_way] = 1'b1;
        // end
        2'b11: begin
            // set valid and tag
            md_itf_datain = {1'b1, 1'b0, mem_address[31-:s_tag]};
            md_itf_load[lru_way] = 1'b1;
        end
        default: ;
    endcase
end

endmodule : cache_datapath

`endif
`ifndef L1_CACHE_TYPES_SV
`define L1_CACHE_TYPES_SV

package l1_cache_types;

import arbitermux::*;
import metamux::*;

// dcache and arbiter structs
// dcache -> arbiter, arbiter -> L2 cache
typedef struct packed {
    logic [31:0] mem_addr;
    logic mem_read;
    logic mem_write;
    logic [255:0] mem_wdata256;
} l1_cache_request;
// arbiter -> dcache, L2 cache -> arbiter
typedef struct packed {
    logic mem_resp;
    logic [255:0] mem_rdata256;
} l1_cache_feedback;

endpackage : l1_cache_types
`endif

`ifndef META_ARRAY_SV
`define META_ARRAY_SV

module meta_array #(
    parameter s_index = 4,
    parameter width = 1
)
(
    clk,
    rst,
    read,
    load,
    index,
    datain,
    dataout
);

localparam num_sets = 2**s_index;

input clk;
input rst;
input read;
input load;
input [s_index-1:0] index;
input [width-1:0] datain;
output logic [width-1:0] dataout;

logic [width-1:0] data [num_sets-1:0] /* synthesis ramstyle = "logic" */;
assign dataout = data[index];

always_ff @(posedge clk)
begin
    if (rst) begin
        for (int i = 0; i < num_sets; ++i)
            data[i] <= '0;
    end
    else begin
        if(load)
            data[index] <= datain;
    end
end

endmodule : meta_array

`endif
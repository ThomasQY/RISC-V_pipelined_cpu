module cacheline_adaptor
(
    input clk,
    input reset_n,

    // Port to LLC (Lowest Level Cache)
    input logic [255:0] line_i,
    output logic [255:0] line_o,
    input logic [31:0] address_i,
    input read_i,
    input write_i,
    output logic resp_o,

    // Port to memory
    input logic [63:0] burst_i,
    output logic [63:0] burst_o,
    output logic [31:0] address_o,
    output logic read_o,
    output logic write_o,
    input resp_i
);

logic [255:0] cur_line;
logic [31:0]  cur_addr;
always_ff @ (posedge clk) begin
    cur_line <= line_i;
end
    
assign address_o = address_i;

logic [255:0] pre_line_o;
always_ff @ (posedge clk) begin
    pre_line_o <= line_o;
end

enum logic [3:0] {wait_0, read_1, read_2, read_3, read_4, write_0, write_1, write_2, write_3, write_4, done} state, next_state;

always_ff @ (posedge clk) begin
    if(!reset_n)
        state <= wait_0;
    else
        state <= next_state;
end

always_comb begin
    next_state = state;
    case (state)
        wait_0: begin
            if(read_i)
                next_state = read_1;
            else if(write_i)
                next_state = write_0;
            else
                next_state = wait_0;
        end
        
        read_1: begin
            if (resp_i)
                next_state = read_2;
            else
                next_state = read_1;
        end
        
        read_2:
            next_state = read_3;
        
        read_3:
            next_state = read_4;
        
        read_4:
            next_state = done;

        write_0: 
            next_state = write_1;
        
        write_1:
            if (resp_i)
                next_state = write_2;
            else
                next_state = write_1;
        
        write_2:
            next_state = write_3;
        
        write_3:
            next_state = write_4;
        
        write_4:
            next_state = done;
        
        done:
            next_state = wait_0;
        
        default: next_state = wait_0;
    endcase
end

always_comb begin
    resp_o = 1'b0;
    read_o = 1'b0;
    write_o = 1'b0;
    line_o = pre_line_o;
    burst_o = 64'b0;
    
    case(state)
        wait_0: begin
            read_o = 1'b0;
            write_o = 1'b0;
        end
        
        read_1: begin
            line_o[63:0] = burst_i;
            read_o = 1'b1;
        end
        
        read_2: begin
            line_o[127:64] = burst_i;
            read_o = 1'b1;
        end

        read_3: begin
            line_o[191:128] = burst_i;
            read_o = 1'b1;
        end

        read_4: begin
            line_o[255:192] = burst_i;
            read_o = 1'b1;
        end

        write_0:;

        write_1: begin
            burst_o = cur_line[63:0];
            write_o = 1'b1;
        end
        
        write_2: begin
            burst_o = cur_line[127:64];
            write_o = 1'b1;
        end

        write_3: begin
            burst_o = cur_line[191:128];
            write_o = 1'b1;
        end
        
        write_4: begin
            burst_o = cur_line[255:192];
            write_o = 1'b1;
        end

        done:
            resp_o = 1'b1;
        
        default:;
    endcase
end

endmodule : cacheline_adaptor

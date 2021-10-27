`ifndef unit_tb
`define unit_tb

import l1_cache_types::*;

module unit_tb();

timeunit 1ns;
timeprecision 1ns;

/****************************** Generate Clock *******************************/
bit clk;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(posedge clk); endclocking

/*********************** Variable/Interface Declarations *********************/
logic rst;

l1_cache_request icache_request;
l1_cache_feedback icache_feedback;
l1_cache_request dcache_request;
l1_cache_feedback dcache_feedback;
l1_cache_request arbiter_request;
l1_cache_feedback arbiter_feedback;


// sudocode: address = {22'd0 ,content_lines_index, 5'd0};
// tag takes bit[4:3] of content_lines_index; set_idx takes bit[2:0]
logic [255:0] content_lines [32]; // cover all cache lines twice

arbiter dut
(
    .*
);


task reset();
    int unsigned i;
    rst <= 1'b1;
    icache_request.mem_read <= 1'd0;
    icache_request.mem_write <= 1'd0;
    dcache_request.mem_read <= 1'd0;
    dcache_request.mem_write <= 1'd0;
    icache_request.mem_addr <= 32'd0;
    icache_request.mem_wdata256 <= 256'd0;
    dcache_request.mem_addr <= 32'd0;
    dcache_request.mem_wdata256 <= 256'd0;
    arbiter_feedback.mem_rdata256 <= 256'd0;
    arbiter_feedback.mem_resp <= 1'b0;
    for(i=0; i<32; i++) begin
        content_lines[i] <= {32{i[7:0]}};
    end
    ##(10);
    rst <= 1'b0;
    ##(1);
endtask : reset

// DO NOT MODIFY CODE ABOVE THIS LINE
task test_icache_read();
    // TODO read content
    // NOTE teamwork
    int unsigned i;
    $display("START: test_icache_read\n");
    for (i = 0; i < 32; i++) begin
        @(tb_clk);
        icache_request.mem_read <= 1'b1;
        icache_request.mem_addr <= {22'd0 ,i[4:0], 5'd0};
        @(tb_clk iff arbiter_request.mem_read);
        assert (arbiter_request.mem_addr == {22'd0 ,i[4:0], 5'd0}) else begin
            $display("ERROR: %0d: %0t: arbiter_request.mem_addr: expected: %h, detected: %h", `__LINE__, $time, {22'd0 ,i[4:0], 5'd0}, arbiter_request.mem_addr);
        end
        ##(4);
        arbiter_feedback.mem_rdata256 <= content_lines[i];
        arbiter_feedback.mem_resp <= 1'b1;
        // $display("time: %0t:", $time);
        // @(tb_clk iff icache_feedback.mem_resp);
        // assert (icache_feedback.mem_rdata256 == content_lines[i]) else begin
        //     $display("ERROR: %0d: %0t: icache_feedback.mem_rdata: expected: %h, detected: %h", `__LINE__, $time, content_lines[i], icache_feedback.mem_rdata256);
        // end
        // $display("time: %0t:", $time);
        @(tb_clk);
        arbiter_feedback.mem_resp <= 1'b0;
        @(tb_clk);
        icache_request.mem_read <= 1'b0;
        ##(2);
    end
endtask : test_icache_read;

task test_dcache_read_write();
    // TODO read content
    // NOTE teamwork
    int unsigned i;
    int unsigned j;
    $display("START: test_dcache_read_write\n");
    for (i = 0; i < 16; i++) begin
        @(tb_clk);
        dcache_request.mem_read <= 1'b1;
        dcache_request.mem_addr <= {22'd0 ,i[4:0], 5'd0};
        @(tb_clk iff arbiter_request.mem_read);
        assert (arbiter_request.mem_addr == {22'd0 ,i[4:0], 5'd0}) else begin
            $display("ERROR: %0d: %0t: arbiter_request.mem_addr: expected: %h, detected: %h", `__LINE__, $time, {22'd0 ,i[4:0], 5'd0}, arbiter_request.mem_addr);
        end
        ##(4);
        arbiter_feedback.mem_rdata256 <= content_lines[i];
        arbiter_feedback.mem_resp <= 1'b1;
        @(tb_clk iff dcache_feedback.mem_resp);
        arbiter_feedback.mem_resp <= 1'b0;
        assert (dcache_feedback.mem_rdata256 == content_lines[i]) else begin
            $display("ERROR: %0d: %0t: dcache_feedback.mem_rdata: expected: %h, detected: %h", `__LINE__, $time, content_lines[i], dcache_feedback.mem_rdata256);
        end
        @(tb_clk);
        dcache_request.mem_read <= 1'b0;
        ##(2);
    end

    // $display(`__LINE__);

    for (i = 16; i < 32; i++) begin
        j = i-16;
        @(tb_clk);
        dcache_request.mem_write <= 1'b1;
        dcache_request.mem_addr <= {22'd0 ,i[4:0], 5'd0};
        dcache_request.mem_wdata256 <= content_lines[j];
        @(tb_clk iff arbiter_request.mem_write);
        assert (arbiter_request.mem_addr == {22'd0 ,i[4:0], 5'd0}) else begin
            $display("ERROR: %0d: %0t: arbiter_request.mem_addr: expected: %h, detected: %h", `__LINE__, $time, {22'd0 ,i[4:0], 5'd0}, arbiter_request.mem_addr);
        end
        assert (arbiter_request.mem_wdata256 == content_lines[j]) else begin
            $display("ERROR: %0d: %0t: dcache_feedback.mem_rdata: expected: %h, detected: %h", `__LINE__, $time, content_lines[j], arbiter_request.mem_wdata256);
        end        
        ##(4);
        arbiter_feedback.mem_resp <= 1'b1;
        @(tb_clk iff dcache_feedback.mem_resp);
        arbiter_feedback.mem_resp <= 1'b0;
        @(tb_clk);
        dcache_request.mem_write <= 1'b0;
        content_lines[i] <= content_lines[j];
        ##(2);
    end

endtask : test_dcache_read_write;

task test_combined();
    int unsigned i, j;
    for (i = 0; i < 16; i++) begin
        j = i + 16;
        icache_request.mem_read <= 1'b1;
        icache_request.mem_addr <= {22'd0 ,i[4:0], 5'd0};
        dcache_request.mem_read <= 1'b1;
        dcache_request.mem_addr <= {22'd0 ,j[4:0], 5'd0};
        @(tb_clk iff arbiter_request.mem_read);
        assert (arbiter_request.mem_addr == {22'd0 ,j[4:0], 5'd0}) else begin
            $display("ERROR: %0d: %0t: arbiter_request.mem_addr: expected: %h, detected: %h", `__LINE__, $time, {22'd0 ,j[4:0], 5'd0}, arbiter_request.mem_addr);
        end
        ##(4);
        arbiter_feedback.mem_rdata256 <= content_lines[j];
        arbiter_feedback.mem_resp <= 1'b1;
        @(tb_clk iff dcache_feedback.mem_resp);
        arbiter_feedback.mem_resp <= 1'b0;
        assert (dcache_feedback.mem_rdata256 == content_lines[j]) else begin
            $display("ERROR: %0d: %0t: dcache_feedback.mem_rdata: expected: %h, detected: %h", `__LINE__, $time, content_lines[j], dcache_feedback.mem_rdata256);
        end
        @(tb_clk);
        dcache_request.mem_read <= 1'b0;

        @(tb_clk iff arbiter_request.mem_read);
        assert (arbiter_request.mem_addr == {22'd0 ,i[4:0], 5'd0}) else begin
            $display("ERROR: %0d: %0t: arbiter_request.mem_addr: expected: %h, detected: %h", `__LINE__, $time, {22'd0 ,i[4:0], 5'd0}, arbiter_request.mem_addr);
        end
        ##(4);
        arbiter_feedback.mem_rdata256 <= content_lines[i];
        arbiter_feedback.mem_resp <= 1'b1;
        @(tb_clk iff dcache_feedback.mem_resp);
        arbiter_feedback.mem_resp <= 1'b0;
        // assert (icache_feedback.mem_rdata256 == content_lines[i]) else begin
        //     $display("ERROR: %0d: %0t: icache_feedback.mem_rdata: expected: %h, detected: %h", `__LINE__, $time, content_lines[i], icache_feedback.mem_rdata256);
        // end
        @(tb_clk);
        icache_request.mem_read <= 1'b0;
        ##(2);
    end
endtask : test_combined;

initial begin
    reset();
    /************************ Your Code Here ***********************/
    // Feel free to make helper tasks / functions, initial / always blocks, etc.
    // test_icache_read();
    // test_dcache_read_write();
    // reset();
    test_combined();
    $display("ALL TESTS FINISHED\n");
    /***************************************************************/
    // // Make sure your test bench exits by calling itf.finish();
    // itf.finish();
    // $error("TB: Illegal Exit ocurred");
    // finish();
end

endmodule : unit_tb
`endif

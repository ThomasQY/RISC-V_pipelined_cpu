`ifndef rand_tb
`define rand_tb

module rand_tb();

timeunit 1ns;
timeprecision 1ns;

/****************************** Generate Clock *******************************/
bit clk;
always #5 clk = clk === 1'b0;
default clocking tb_clk @(posedge clk); endclocking

/*********************** Variable/Interface Declarations *********************/
logic rst;
logic mem_resp, mem_read, mem_write;
logic [31:0] mem_rdata, mem_wdata, mem_address;
logic [3:0]  mem_byte_enable;
logic pmem_resp, pmem_read, pmem_write;
logic [255:0] pmem_rdata, pmem_wdata;
logic [31:0]  pmem_address;
// logic [255:0] expected_rdata;
logic [31:0] rand_addr;
logic [31:0] rand_content;
logic [31:0] content_record [2**11];

cache dut(.*);
unit_mem pmem(.*);

task reset();
    int unsigned i;
    int unsigned j;
    rst <= 1'b1;
    mem_read <= 1'd0;
    mem_write <= 1'd0;
    mem_byte_enable <= 4'd0;
    mem_address <= 32'd0;
    mem_wdata <= 32'd0;
    ##(10);
    rst <= 1'b0;
    ##(1);
endtask : reset

task test_read_rand();
    int unsigned i;
    int unsigned j;
    $display("START: test_read_rand\n");
    @(tb_clk)
    rand_addr <= $urandom();
    for (i = 0; i < 100000; i++) begin
        @(tb_clk);
        mem_read <= 1'b1;
        mem_address <= {19'd0,rand_addr[12:2], 2'd0};
        @(tb_clk iff mem_resp);
        assert (mem_rdata == pmem.data[mem_address[12:5]][(mem_address[4:2]*32+31)-:32]) else begin
            $display("ERROR: Wrong rdata for i=%d at %0t: expected: %h, detected: %h",i, $time,
                     pmem.data[mem_address[12:5]][(mem_address[4:2]*32+31)-:32], mem_rdata);
        end
        ##(1);
        mem_read <= 1'b0;
        rand_addr <= $urandom();
    end
endtask : test_read_rand;

task test_write_rand();
    int unsigned i;
    int unsigned j;
    $display("START: test_write_rand\n");
    @(tb_clk)
    rand_addr <= $urandom();
    rand_content <= $urandom();
    for (i = 0; i < 100000; i++) begin // writing random trash
        @(tb_clk);
        mem_write <= 1'b1;
        mem_byte_enable <= 4'b1111;
        mem_address <= {19'd0,rand_addr[12:2], 2'd0};
        mem_wdata <= rand_content;
        content_record[rand_addr[12:2]] <= rand_content;
        @(tb_clk iff mem_resp);
        ##(1);
        mem_write <= 1'b0;
        rand_addr <= $urandom();
        rand_content <= $urandom();
    end
    $display("START: test_read_back\n");
    @(tb_clk)
    for (i = 0; i < 2048; i++) begin
        @(tb_clk);
        mem_read <= 1'b1;
        mem_address <= {19'd0,i[10:0], 2'd0};
        @(tb_clk iff mem_resp);
        assert (mem_rdata == content_record[i]) else begin
            $display("ERROR: Wrong rdata for i=%d at %0t: expected: %h, detected: %h",i, $time,
                     content_record[i], mem_rdata);
        end
        ##(1);
        mem_read <= 1'b0;
    end
endtask : test_write_rand;

initial begin
    reset();
    // test_read_rand();
    test_write_rand();
    $display("ALL TESTS FINISHED\n");
end

endmodule : rand_tb
`endif

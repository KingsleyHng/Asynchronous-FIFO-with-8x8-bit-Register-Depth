`timescale 1ns/1ps

module async_fifo_tb;

  parameter DATA_WIDTH = 8;
  parameter ADDR_WIDTH = 3;

  reg write_enable, write_clk, write_reset_n;
  reg read_enable, read_clk, read_reset_n;
  reg [DATA_WIDTH-1:0] write_data;
  wire [DATA_WIDTH-1:0] read_data;
  wire fifo_full, fifo_empty;

  // Model a queue for checking data
  reg [DATA_WIDTH-1:0] verification_data_queue[$];
  reg [DATA_WIDTH-1:0] verification_write_data;
  reg all_test_passed = 1;

  // Instantiate the FIFO
  AsynchronousFIFO #(DATA_WIDTH, ADDR_WIDTH) dut (
    .write_enable(write_enable), 
    .write_clk(write_clk), 
    .write_reset_n(write_reset_n),
    .read_enable(read_enable), 
    .read_clk(read_clk), 
    .read_reset_n(read_reset_n),
    .write_data(write_data), 
    .read_data(read_data), 
    .fifo_full(fifo_full), 
    .fifo_empty(fifo_empty)
  );

  // Clock generation
  initial begin
    write_clk = 1'b0;
    read_clk = 1'b0;

    fork
      forever #20 write_clk = ~write_clk;
      forever #80 read_clk = ~read_clk;
    join
  end

  // Write operations
  initial begin
    write_enable = 1'b0;
    write_data = '0;
    write_reset_n = 1'b0;
    repeat(5) @(posedge write_clk);
    write_reset_n = 1'b1;
    $display("Write domain reset deasserted");

    for (int iter = 0; iter < 2; iter++) begin
      for (int i = 0; i < 16; i++) begin
        @(posedge write_clk && !fifo_full);
        write_enable = (i % 2 == 0) ? 1'b1 : 1'b0;
        if (write_enable) begin
          write_data = $urandom;
          verification_data_queue.push_back(write_data);
        end
      end
      #1us;
    end
  end

  // Read operations
  initial begin
    read_enable = 1'b0;
    read_reset_n = 1'b0;
    repeat(5) @(posedge read_clk);
    read_reset_n = 1'b1;

    for (int iter = 0; iter < 2; iter++) begin
      for (int i = 0; i < 16; i++) begin
        @(posedge read_clk && !fifo_empty);
        read_enable = (i % 2 == 0) ? 1'b1 : 1'b0;
        if (read_enable) begin
          verification_write_data = verification_data_queue.pop_front();
          // Check the read_data against modeled write_data
          if(read_data != verification_write_data) begin
            $error("Comparison Failed: expected write_data = %h, read_data = %h", verification_write_data, read_data);
            all_test_passed = 0;
          end
          else begin
            $display("Comparison Passed: expected write_data = %h, read_data = %h", verification_write_data, read_data);
          end
        end
      end
      #1us;
    end

   
  end
  
  initial begin
    #10000
    if (!all_test_passed) begin
      $display("Test Failed");
      $finish;
    end
    
    else begin
      $display("TEST PASSED");
   
    end
    $finish;
  end
  
  // VCD generation
  initial begin
    $dumpfile("async_fifo_tb.vcd");  // Name of the VCD file
    $dumpvars(0, async_fifo_tb);     // Dump all variables in this module
  end

endmodule

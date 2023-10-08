`timescale 1ns/1ps


`include "FIFO.v"

module FIFO_tb;
  reg wclk;
  reg reset;
  reg [DATA_WIDTH-1:0] Din;
  wire [DATA_WIDTH-1:0] Dout;
  wire fifo_empty;
  wire rclk;
  wire [PTR_SIZE-1:0]wptr;
  wire [PTR_SIZE-1:0]rptr;
  wire wr_first_edge;
  wire rd_first_edge;
  wire rd_en;

parameter DATA_WIDTH = 8;
parameter DEPTH = 8;
parameter PTR_SIZE = 3;
  integer i;

  // Instantiate the FIFO module
  FIFO uut (.wclk(wclk), .reset(reset), .rclk(rclk), .wptr(wptr), .rptr(rptr), .wr_first_edge(wr_first_edge), .rd_first_edge(rd_first_edge), 
  .rd_en(rd_en), .Din(Din), .Dout(Dout), .fifo_empty(fifo_empty));

  
  initial begin
    wclk = 0;       // Initialize the clock to 0
    forever #5 wclk = ~wclk; // Toggle the clock every 5 time units
  end

  initial begin
    $dumpfile("FIFO.vcd");
    $dumpvars();
    reset <= 1'b1;
    #10;
    reset <= 1'b0;

    for (i = 0; i <= 10; i = i + 1) begin
      // Create an array to hold random values for Din
      Din = $random;
      #10;
    end

    // Finish the simulation after some time
    $finish;
  end
endmodule
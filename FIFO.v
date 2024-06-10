// Code your design here


module ReadPointerControl
#(
  parameter ADDR_WIDTH = 3
)
(
  input   read_enable, read_clk, read_reset_n,
  input   [ADDR_WIDTH :0] sync_write_pointer,
  output reg  fifo_empty,
  output  [ADDR_WIDTH-1:0] read_address,
  output reg [ADDR_WIDTH :0] read_pointer
);

  reg [ADDR_WIDTH:0] read_binary;
  wire [ADDR_WIDTH:0] read_gray_next, read_binary_next;

  // Gray code style pointer
  always_ff @(posedge read_clk or negedge read_reset_n)
    if (!read_reset_n)
      {read_binary, read_pointer} <= '0;
    else
      {read_binary, read_pointer} <= {read_binary_next, read_gray_next};

  // Memory read-address pointer (use binary to address memory)
  assign read_address = read_binary;
  assign read_binary_next = read_binary + (read_enable & ~fifo_empty);
  assign read_gray_next = (read_binary_next >> 1) ^ read_binary_next;

  // FIFO empty when the next read pointer == synchronized write pointer or on reset
  assign fifo_empty_condition = (read_gray_next == sync_write_pointer);

  always_ff @(posedge read_clk or negedge read_reset_n)
    if (!read_reset_n)
      fifo_empty <= 1'b1;
    else
      fifo_empty <= fifo_empty_condition;

endmodule

module WritePointerControl
#(
  parameter ADDR_WIDTH = 3
)
(
  input   write_enable, write_clk, write_reset_n,
  input   [ADDR_WIDTH :0] sync_read_pointer,
  output reg  fifo_full,
  output  [ADDR_WIDTH-1:0] write_address,
  output reg [ADDR_WIDTH :0] write_pointer
);

   reg [ADDR_WIDTH:0] write_binary;
  wire [ADDR_WIDTH:0] write_gray_next, write_binary_next;

  // Gray code style pointer
  always_ff @(posedge write_clk or negedge write_reset_n)
    if (!write_reset_n)
      {write_binary, write_pointer} <= '0;
    else
      {write_binary, write_pointer} <= {write_binary_next, write_gray_next};

  // Memory write-address pointer (use binary to address memory)
  assign write_address = write_binary[ADDR_WIDTH-1:0];
  assign write_binary_next = write_binary + (write_enable & ~fifo_full);
  assign write_gray_next = (write_binary_next >> 1) ^ write_binary_next;

  // FIFO full condition
  assign fifo_full_condition = (write_gray_next == {~sync_read_pointer[ADDR_WIDTH:ADDR_WIDTH-1], sync_read_pointer[ADDR_WIDTH-2:0]});

  always_ff @(posedge write_clk or negedge write_reset_n)
    if (!write_reset_n)
      fifo_full <= 1'b0;
    else
      fifo_full <= fifo_full_condition;

endmodule

module SyncWritePointerToReadDomain
#(
  parameter ADDR_WIDTH = 3
)
(
  input   read_clk, read_reset_n,
  input   [ADDR_WIDTH:0] write_pointer,
  output reg [ADDR_WIDTH:0] sync_write_pointer
);

  reg [ADDR_WIDTH:0] intermediate_write_pointer;

  always_ff @(posedge read_clk or negedge read_reset_n)
    if (!read_reset_n)
      {sync_write_pointer, intermediate_write_pointer} <= 0;
    else
      {sync_write_pointer, intermediate_write_pointer} <= {intermediate_write_pointer, write_pointer};

endmodule

// Read pointer to write clock synchronizer
module SyncReadPointerToWriteDomain
#(
  parameter ADDR_WIDTH = 3
)
(
  input   write_clk, write_reset_n,
  input   [ADDR_WIDTH:0] read_pointer,
  output reg  [ADDR_WIDTH:0] sync_read_pointer
);

  reg [ADDR_WIDTH:0] intermediate_read_pointer;

  always_ff @(posedge write_clk or negedge write_reset_n)
    if (!write_reset_n) {sync_read_pointer, intermediate_read_pointer} <= 0;
    else {sync_read_pointer, intermediate_read_pointer} <= {intermediate_read_pointer, read_pointer};

endmodule

// FIFO memory
module FIFOMemory
#(
  parameter DATA_WIDTH = 8, // Memory data word width
  parameter ADDR_WIDTH = 3 // Number of memory address bits
)
(
  input   write_enable, fifo_full, write_clk,
  input   [ADDR_WIDTH-1:0] write_address, read_address,
  input   [DATA_WIDTH-1:0] write_data,
  output  [DATA_WIDTH-1:0] read_data
);

  // RTL Verilog memory model
  localparam DEPTH = 1 << ADDR_WIDTH;

  logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

  assign read_data = mem[read_address];

  always_ff @(posedge write_clk)
    if (write_enable && !fifo_full)
      mem[write_address] <= write_data;

endmodule

module AsynchronousFIFO
#(
  parameter DATA_WIDTH = 8,
  parameter ADDR_WIDTH = 3
)
(
  input   write_enable, write_clk, write_reset_n,
  input   read_enable, read_clk, read_reset_n,
  input   [DATA_WIDTH-1:0] write_data,
  output  [DATA_WIDTH-1:0] read_data,
  output  fifo_full,
  output  fifo_empty
);

  wire [ADDR_WIDTH-1:0] write_address, read_address;
  wire [ADDR_WIDTH:0] write_pointer, read_pointer, sync_read_pointer, sync_write_pointer;

  SyncReadPointerToWriteDomain syncReadPointerToWriteDomain (.write_clk(write_clk), .write_reset_n(write_reset_n), .read_pointer(read_pointer), .sync_read_pointer(sync_read_pointer));
  SyncWritePointerToReadDomain syncWritePointerToReadDomain (.read_clk(read_clk), .read_reset_n(read_reset_n), .write_pointer(write_pointer), .sync_write_pointer(sync_write_pointer));
  FIFOMemory #(DATA_WIDTH, ADDR_WIDTH) fifoMemory (.write_enable(write_enable), .fifo_full(fifo_full), .write_clk(write_clk), .write_address(write_address), .read_address(read_address), .write_data(write_data), .read_data(read_data));
  ReadPointerControl #(ADDR_WIDTH) readPointerControl (.read_enable(read_enable), .read_clk(read_clk), .read_reset_n(read_reset_n), .sync_write_pointer(sync_write_pointer), .fifo_empty(fifo_empty), .read_address(read_address), .read_pointer(read_pointer));
  WritePointerControl #(ADDR_WIDTH) writePointerControl (.write_enable(write_enable), .write_clk(write_clk), .write_reset_n(write_reset_n), .sync_read_pointer(sync_read_pointer), .fifo_full(fifo_full), .write_address(write_address), .write_pointer(write_pointer));

endmodule

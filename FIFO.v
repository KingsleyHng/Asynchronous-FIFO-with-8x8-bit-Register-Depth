`timescale 1ns/1ps

module FIFO( 
            input wclk, 
            input reset,
            input [DATA_WIDTH-1:0]Din,
            output [DATA_WIDTH-1:0]Dout,
            output rclk,
            output [PTR_SIZE-1:0]wptr,
            output [PTR_SIZE-1:0]rptr,
            output wr_first_edge,
            output rd_first_edge,
            output rd_en,
            output fifo_empty
            );

parameter DEPTH = 8;
parameter DATA_WIDTH = 8;
parameter PTR_SIZE = 3; 

reg[DATA_WIDTH-1:0]memory[0:DEPTH-1];
reg[PTR_SIZE-1:0]wptr;
reg[PTR_SIZE-1:0]rptr;


//reg [PTR_SIZE-1:0]wptr_next;
wire rclk;
assign #2 rclk=wclk;

//WritePointer
reg wr_first_edge; // Declare a register to track the first edge
always @(posedge wclk or posedge reset) begin
    if (reset) begin
        // Reset condition
        wptr <= 3'b000;     // Initialize wptr to 000
        wr_first_edge <= 1'b1; // Set first_edge to 1 during reset
    end
    else begin
        if (wr_first_edge) begin
            // Initial edge condition
            wptr <= 3'b000;     // Set wptr to 000
            wr_first_edge <= 1'b0; // Clear first_edge after the initial edge
        end
        else begin
            // State transition logic for wptr
            case (wptr)
                3'b000: wptr <= 3'b001;
                3'b001: wptr <= 3'b011;
                3'b011: wptr <= 3'b010;
                3'b010: wptr <= 3'b110;
                3'b110: wptr <= 3'b111;
                3'b111: wptr <= 3'b101;
                3'b101: wptr <= 3'b100;
                default: wptr <= 3'b000; // Handle other cases if needed
            endcase
        end
    end
end

//ReadPointer
reg rd_first_edge;
always @(posedge rclk or posedge reset) begin
    if (reset) begin
        // Reset condition
        rptr <= 3'b000;     // Initialize wptr to 000
        rd_first_edge <= 1'b1; // Set first_edge to 1 during reset
    end
    else begin
        if (rd_first_edge) begin
            // Initial edge condition
            rptr <= 3'b000;     // Set wptr to 000
            rd_first_edge <= 1'b0; // Clear first_edge after the initial edge
        end
        else begin
            // State transition logic for wptr
            case (rptr)
                3'b000: rptr <= 3'b001;
                3'b001: rptr <= 3'b011;
                3'b011: rptr <= 3'b010;
                3'b010: rptr <= 3'b110;
                3'b110: rptr <= 3'b111;
                3'b111: rptr <= 3'b101;
                3'b101: rptr <= 3'b100;
                default: rptr <= 3'b000; // Handle other cases if needed
            endcase
        end
    end
end

reg [PTR_SIZE-1:0]wptr_sync1;
always@(posedge rclk or posedge reset) begin
    if (reset) begin
        wptr_sync1 <= 0;
    end
    else begin 
        wptr_sync1 <= wptr;
   end
end

reg [PTR_SIZE-1:0]wptr_sync2;
always@(posedge rclk or posedge reset) begin
    if (reset) begin
        wptr_sync2 <= 0;
    end
    else begin 
        wptr_sync2 <= wptr_sync1;
   end
end

reg fifo_empty;
always@(*) begin
    if (wptr_sync2 == rptr) begin
        fifo_empty <= 1;
    end
    else
        fifo_empty <= 0;
end

wire rd_en;
assign rd_en = ~fifo_empty;

integer i;
//Data storage
always @(posedge wclk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < DEPTH; i = i + 1) begin
            memory[i] <= 8'bzzzzzzzz;
        end
    end else begin
        memory[wptr] <= Din;
    end
end

reg Dout;
always @(posedge rclk) begin
    Dout <= memory[rptr];
end
endmodule
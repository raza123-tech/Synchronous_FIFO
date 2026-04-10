// Code your design here
// Code your design here
    `timescale 1ns/1ps

module syn_fifo #(
  parameter WIDTH = 8,
  parameter DEPTH = 16
)(
  input  clk,
  input  reset,
  input  rd_en,
  input  wt_en,
  output reg                    fifo_full,
  output reg                    fifo_empty,
  input      [WIDTH-1:0]        fifo_in,
  output     [WIDTH-1:0]        fifo_out,          
  output reg [$clog2(DEPTH):0]  fifo_count
);

  reg [WIDTH-1:0]        mem [0:DEPTH-1];
  reg [$clog2(DEPTH)-1:0] rd_ptr, wt_ptr;

  
  assign fifo_out = mem[rd_ptr];

 
  always @(*) begin
    fifo_empty = (fifo_count == 0);
    fifo_full  = (fifo_count == DEPTH);
  end

 
  always @(posedge clk or posedge reset) begin
    if (reset)
      fifo_count <= 0;
    else begin
      case ({wt_en & ~fifo_full, rd_en & ~fifo_empty})
        2'b10:   fifo_count <= fifo_count + 1;  
        2'b01:   fifo_count <= fifo_count - 1; 
        default: fifo_count <= fifo_count;       
      endcase
    end
  end

 
  always @(posedge clk) begin
    if (wt_en && !fifo_full)
      mem[wt_ptr] <= fifo_in;
  end


  always @(posedge clk or posedge reset) begin
    if (reset) begin
      wt_ptr <= 0;
      rd_ptr <= 0;
    end else begin
      if (wt_en && !fifo_full)
        wt_ptr <= wt_ptr + 1;
      if (rd_en && !fifo_empty)
        rd_ptr <= rd_ptr + 1;
    end
  end

endmodule
    

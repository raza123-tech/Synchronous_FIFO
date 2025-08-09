// Code your testbench here
// or browse Examples
module tb;
  parameter DEPTH =16;
  parameter WIDTH = 8;
  
  
  reg clk,rst;
  reg wr_en;
  reg [WIDTH-1:0] din;
  wire full;
  
  //read
  reg rd_en;
  wire [WIDTH-1:0] dout;
  wire empty;
  
  sync_fifo uut(
    clk,rst,wr_en,din,full,rd_en,dout,empty);
  
 initial begin 
   clk = 0;
 end
 
  always #5 clk=~clk;
  
  
  initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
  end
  
  
initial begin
 rst = 1;
 wr_en=0;
 rd_en=0;
 din=0;
 


repeat(2)@(posedge clk);
rst=0;
#10;

$display("\n===== sync_fifo  Tests Start =====\n");
  // 1) Write Test and check if empty went low
tc_write();

// 2) Read Test
tc_read();

  //3)Full test
  tc_full();
  //4)Empty test
 tc_empty();
  
  tc_wraparound();
 tc_simultaneous_read_write();
 tc_overflow();
 tc_underflow();
  tc_reset();

  
#10;
$finish;
  
end

  task tc_write();
    begin
    $display("Write operation test");
    din = 8'd124;
    @(posedge clk)
    wr_en=1;
    @(posedge clk);
      wr_en = 0;
    
      if(!empty)
      $display("PASS: FIFO  not empty after write.");
    else
      $display("Fail: FIFO  empty after write.");
    end
  endtask
  
  task tc_read();
    begin
    $display("Read operation test");
    
  @(posedge clk)
    rd_en=1;
    @(posedge clk);
      rd_en = 0;
    
    if(dout==8'd124)
      $display("PASS: Read data = 124 as expected.");
    else
      $display("ERROR: Read data = 0x%0d (expected 124).", dout);
    end
  endtask
  
  
task tc_full();
  
  integer i;
  begin
  $display("Full Condition test");
  for (i = 0; i < DEPTH; i = i + 1) begin
  @(posedge clk)
  wr_en  = 1;
  din=$random; 
  @(posedge clk)
  wr_en =0;
end
  
  if(full)
    $display("PASS: full flag asserted after %0d writes.", DEPTH);
  else
    $display("ERROR: full flag = 0 (expected 1) after writing %0d items.", DEPTH);
  end
endtask

  task tc_empty();
    begin
      while(!empty) begin
        @(posedge clk);
        rd_en = 1; end
      @(posedge clk)
      rd_en=0;
      if (!empty) $display("Error: FIFO empty flag not set.");
  else $display("FIFO empty flag set correctly");
end 
  endtask
  
  task tc_wraparound();
  integer i;
  begin
    $display("Wraparound Test Case");

    // Fill FIFO with DEPTH values
    for (i = 0; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      din = i;
      wr_en = 1;
      @(posedge clk);
      wr_en = 0;
      
    end

    // Read 2 values to create space
    for (i = 0; i < 2; i = i + 1) begin
      @(posedge clk);
      rd_en = 1;
      @(posedge clk);
      rd_en = 0;
      
    end

    // Write special value to test wraparound
    @(posedge clk);
    din = 8'h77;
    wr_en = 1;
    @(posedge clk);
    wr_en = 0;
    

    // Read remaining elements
    for (i = 2; i < DEPTH; i = i + 1) begin
      @(posedge clk);
      rd_en = 1;
      @(posedge clk);
      rd_en = 0;
      
    end

    // Final read should return 0x77
    @(posedge clk);
    rd_en = 1;
    @(posedge clk);
    rd_en = 0;
    

    if (dout !== 8'h77)
      $display(" Error: Wrap-around mismatch. Expected 0x77, got %h", dout);
    else
      $display("Wrap-around test case passed. Got 0x77");

  end
endtask

  task tc_simultaneous_read_write();
begin
  $display("Simultaneous Read/Write Test");

  @(posedge clk);
    din   = 8'h55;
    wr_en = 1;
    rd_en = 0;

  @(posedge clk);
    wr_en = 0;
    rd_en = 0;

  @(posedge clk);
    din   = 8'h99;
    wr_en = 1;
    rd_en = 1;

  @(posedge clk);
    wr_en = 0;
    rd_en = 0;

  // Wait 1 cycle to observe the read result
  @(posedge clk);
  if (dout !== 8'h55)
    $display("    ERROR: Expected 8'h55, got %h", dout);
  else
    $display("PASS: Read 0x55 correctly during simultaneous rd/wr.");

  // Step 3: Read 0x99
  @(posedge clk);
    rd_en = 1;

  @(posedge clk);
    rd_en = 0;

  // Wait one more cycle for dout update
  @(posedge clk);
  if (dout !== 8'h99)
    $display("    ERROR: Expected 8'h99, got %h", dout);
  else
    $display("PASS: Read 0x99 correctly.");

  $display("");
end
endtask

task tc_overflow();
integer i;
begin
    for (i = 0; i < DEPTH ; i=i+1) begin
        din = $random;
        wr_en = 1; 
      @(posedge clk); 
      wr_en = 0;
        
        if (full)
         $display("FIFO is full now");
    end
    for(i =0 ; i<2; i=i+1) begin
    din = $random;
    wr_en = 1; 
     @(posedge clk)
    wr_en = 0;
    if(full)
    $display("Overflow!!!write attempt while fifo is full");
    end
end
endtask

task tc_underflow();
begin
$display("Underflow Test");
// Make sure FIFO is empty
if (!empty) begin
// If not empty, drain it
while (!empty) begin @(posedge clk);
rd_en = 1;
@(posedge clk);
rd_en = 0;
end
 end
// 1) Attempt to read when empty
@(posedge clk);
rd_en = 1;
@(posedge clk);
rd_en = 0;
// 2) Attempt a second read
@(posedge clk);
rd_en = 1;
@(posedge clk);
rd_en = 0;

if(!empty)begin
  $display("ERROR: empty flag deasserted on underflow attempt.");
    end else begin
      $display("PASS: empty flag stays asserted on underflow.");
    end

    
  end
  endtask

task tc_reset();
begin
  $display("Reset Test");
    din = 8'd12;
    @(posedge clk);
      wr_en = 1;
    @(posedge clk);
      wr_en = 0;

    @(posedge clk);
      rst = 1;
    @(posedge clk);
      rst = 0;

    // After reset, FIFO should be empty
    if (!empty) begin
      $display("ERROR: FIFO not empty after reset.");
    end else begin
      $display("PASS: FIFO empty after reset.");
    end
    $display("");
  end
  endtask

  //------------

endmodule



      
  
  

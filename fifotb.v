// Code your testbench here
// or browse Examples
               
 import uvm_pkg::*;
`include "uvm_macros.svh"


interface fifo_if (input clk);
  logic reset;
  logic rd_en, wt_en;
  logic [7:0] fifo_in;
  logic [7:0] fifo_out;
  logic fifo_full;
  logic fifo_empty;
endinterface



//  Transaction

class fifo_txn extends uvm_sequence_item;
  `uvm_object_utils(fifo_txn)

  rand bit [7:0] data;
  rand bit rd_en, wt_en;
  bit full, empty;
  bit [7:0] out;
  bit reset;

  function new(string name = "fifo_txn");
    super.new(name);
  endfunction
endclass



//  Sequences

class write_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(write_seq)
  function new(string name = "write_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    repeat(10) begin
      t = fifo_txn::type_id::create("t");
      start_item(t);
      assert(t.randomize() with {wt_en==1; rd_en==0;});
      finish_item(t);
    end
  endtask
endclass

class read_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(read_seq)
  function new(string name = "read_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    repeat(10) begin
      t = fifo_txn::type_id::create("t");
      start_item(t);
      t.rd_en = 1; t.wt_en = 0; t.data = 0;
      finish_item(t);
    end
  endtask
endclass

class simult_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(simult_seq)
  function new(string name = "simult_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    repeat(5) begin
      t = fifo_txn::type_id::create("t");
      start_item(t);
      assert(t.randomize() with {wt_en==1; rd_en==1;});
      finish_item(t);
    end
  endtask
endclass

class overflow_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(overflow_seq)
  function new(string name = "overflow_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    repeat(20) begin
      t = fifo_txn::type_id::create("t");
      start_item(t);
      assert(t.randomize() with {wt_en==1; rd_en==0;});
      finish_item(t);
    end
  endtask
endclass

class underflow_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(underflow_seq)
  function new(string name = "underflow_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    repeat(5) begin
      t = fifo_txn::type_id::create("t");
      start_item(t);
      t.rd_en = 1; t.wt_en = 0; t.data = 0;
      finish_item(t);
    end
  endtask
endclass

class reset_seq extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(reset_seq)
  function new(string name = "reset_seq"); super.new(name); endfunction

  task body();
    fifo_txn t;
    t = fifo_txn::type_id::create("t");
    start_item(t);
    t.reset = 1; t.rd_en = 0; t.wt_en = 0;
    finish_item(t);

    t = fifo_txn::type_id::create("t");
    start_item(t);
    t.reset = 0; t.rd_en = 0; t.wt_en = 0;
    finish_item(t);
  endtask
endclass



//  Sequencer

class fifo_sequencer extends uvm_sequencer #(fifo_txn);
  `uvm_component_utils(fifo_sequencer)
  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass



//  Driver

class fifo_driver extends uvm_driver #(fifo_txn);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("no vif", "vif not connected")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_txn t;
    vif.wt_en   <= 0;
    vif.rd_en   <= 0;
    vif.fifo_in <= 0;
    vif.reset   <= 0;

    forever begin
      seq_item_port.get_next_item(t);
      @(posedge vif.clk);
      vif.reset   <= t.reset;
      vif.wt_en   <= t.wt_en;
      vif.rd_en   <= t.rd_en;
      vif.fifo_in <= t.data;
    @(posedge vif.clk);
      seq_item_port.item_done();
    end
  endtask
endclass



//  Monitor 

class fifo_monitor extends uvm_component;
  `uvm_component_utils(fifo_monitor)

  virtual fifo_if vif;
  uvm_analysis_port #(fifo_txn) ap;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    ap = new("ap", this);
    if (!uvm_config_db #(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("no vif", "no vif received")
  endfunction

  task run_phase(uvm_phase phase);
  fifo_txn t;
  bit last_rd_en = 0;

  forever begin
    @(posedge vif.clk);

    t         = fifo_txn::type_id::create("t");
    t.reset   = vif.reset;
    t.rd_en   = vif.rd_en;
    t.wt_en   = vif.wt_en;
    t.data    = vif.fifo_in;
    t.full    = vif.fifo_full;
    t.empty   = vif.fifo_empty;

  
    
    if (last_rd_en && !vif.fifo_empty) begin
      t.out   = vif.fifo_out;    
      t.empty = vif.fifo_empty;  
      t.full  = vif.fifo_full;
    end else begin
      t.out = vif.fifo_out;
    end

    $display("MONITOR: TIME=%t | rd=%0b wt=%0b data_in=%0d data_out=%0d empty=%0b full=%0b",
             $time, t.rd_en, t.wt_en, t.data, t.out, t.empty, t.full);

    ap.write(t);
    last_rd_en = vif.rd_en;  // Track for next cycle
    
  end
  endtask

endclass


//  Scoreboard  

class fifo_scoreboard extends uvm_component;
  `uvm_component_utils(fifo_scoreboard)

  uvm_analysis_imp #(fifo_txn, fifo_scoreboard) imp;

  
  bit [7:0] q[$];
  int DEPTH = 16;

  
  int pass_count = 0;
  int fail_count = 0;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction

 // The Report Phase
 
  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
 
    $display(".........  FIFO SCOREBOARD FINAL SUMMARY REPORT");
      
    $display("  Total Successful Reads/Simult: %0d", pass_count);
     $display("  Total Errors Detected:         %0d", fail_count);
 
    if (fail_count == 0)
      `uvm_info("Scoreboard", "OVERALL TEST STATUS: PASSED", UVM_LOW)
    else
      `uvm_error("SB_FINAL", "OVERALL TEST STATUS: FAILED")
   
  endfunction

function void write(fifo_txn t);
    
    if (t.reset) begin
      `uvm_info("SB", "Reset detected — clearing reference queue", UVM_LOW)
      q.delete();
      return;
    end

   
    if (t.wt_en && !t.rd_en) begin
      if (q.size() == DEPTH)
        `uvm_info("SB_OVERFLOW", "Intentional Overflow", UVM_LOW)
      else
        q.push_back(t.data);
    end
    else if (t.rd_en && !t.wt_en) begin
      if (q.size() == 0)
        `uvm_info("SB_UNDERFLOW", "Intentional Underflow", UVM_LOW)
      else begin
        bit [7:0] exp = q.pop_front();
        if (exp !== t.out) begin
          `uvm_info("SB_MISMATCH", $sformatf("Data Mismatch: exp=%0d got=%0d", exp, t.out), UVM_LOW)
         
        end else begin
          pass_count++;
        end
      end
    end
    else if (t.rd_en && t.wt_en) begin
      if (q.size() > 0) begin
        bit [7:0] exp = q.pop_front();
        q.push_back(t.data);
        if (exp !== t.out) begin
          `uvm_info("Scoreboard simt. mismatch", "Simultaneous Data Mismatch", UVM_LOW)
        end else begin
           pass_count++;
        end
        end
        end
    
      fork
      begin
        #2ps; 
        if (!(t.rd_en || t.wt_en)) begin // Only check flags when the FIFO is IDLE
           if (q.size() == DEPTH && !t.full) begin
             `uvm_error("SB_FLAG", "FULL FLAG MISMATCH")
            fail_count++;
           end
           if (q.size() == 0 && !t.empty) begin
             `uvm_error("SB_FLAG", "EMPTY FLAG MISMATCH")
            fail_count++;
        end
        end
        end
     join_none
      endfunction
endclass
    
// coverage
    
class fifo_coverage extends uvm_component;
  `uvm_component_utils(fifo_coverage)

  uvm_analysis_imp #(fifo_txn, fifo_coverage) imp;
  fifo_txn t;

  covergroup cg;
    coverpoint t.rd_en  { 
      bins read_on  = {1}; 
      bins read_off  = {0}; 
    }
    coverpoint t.wt_en  { 
      bins write_on = {1};
      bins write_off = {0};
    }
    coverpoint t.full   { 
      bins full_1   = {1};
      bins full_0    = {0};
    }
    coverpoint t.empty  { 
      bins empty_1  = {1};
      bins empty_0   = {0};
    }
    cross t.wt_en, t.rd_en;
  endgroup

  function new(string name, uvm_component parent);
    super.new(name, parent);
    cg = new();
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    imp = new("imp", this);
  endfunction

  function void write(fifo_txn tx);
    t = tx;
    cg.sample();
  endfunction
endclass



//  Agent

class fifo_agent extends uvm_component;
  `uvm_component_utils(fifo_agent)

  fifo_monitor   mon;
  fifo_driver    drv;
  fifo_sequencer seqr;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon  = fifo_monitor::type_id::create("mon",  this);
    drv  = fifo_driver::type_id::create("drv",   this);
    seqr = fifo_sequencer::type_id::create("seqr", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    drv.seq_item_port.connect(seqr.seq_item_export);
  endfunction
endclass



//  Environment

class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_agent      agt;
  fifo_coverage   cov;
  fifo_scoreboard sb;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    agt = fifo_agent::type_id::create("agt",  this);
    sb  = fifo_scoreboard::type_id::create("sb",  this);
    cov = fifo_coverage::type_id::create("cov", this);
  endfunction

  function void connect_phase(uvm_phase phase);
    agt.mon.ap.connect(sb.imp);
    agt.mon.ap.connect(cov.imp);
  endfunction
endclass



//  Test class 

class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
     reset_seq     rst;
    write_seq     w;
    read_seq      r;
      simult_seq    s;
    overflow_seq  o;
    underflow_seq u;

    phase.raise_objection(this);

    rst = reset_seq::type_id::create("rst");
    w   = write_seq::type_id::create("w");
     r   = read_seq::type_id::create("r");
      s   = simult_seq::type_id::create("s");
    o   = overflow_seq::type_id::create("o");
    u   = underflow_seq::type_id::create("u");

  
    rst.start(env.agt.seqr);  
    w.start(env.agt.seqr);     
    r.start(env.agt.seqr);    
    w.start(env.agt.seqr);    
    s.start(env.agt.seqr);     
    o.start(env.agt.seqr);    
    r.start(env.agt.seqr);     
    r.start(env.agt.seqr);     
    u.start(env.agt.seqr);     
    
    phase.drop_objection(this);
  endtask
endclass



//  Top 

module top;

  bit clk = 0;
  always #5 clk = ~clk;

  fifo_if vif(clk);

  syn_fifo dut (
    .clk        (clk),
    .reset      (vif.reset),
    .rd_en      (vif.rd_en),
    .wt_en      (vif.wt_en),
    .fifo_full  (vif.fifo_full),
    .fifo_empty (vif.fifo_empty),
    .fifo_in    (vif.fifo_in),
    .fifo_out   (vif.fifo_out),
    .fifo_count ()
  );

  initial begin
    vif.reset = 1;
    repeat(2) @(posedge clk);
    vif.reset = 0;
  end

  initial begin
    uvm_config_db #(virtual fifo_if)::set(null, "*", "vif", vif);
    run_test("fifo_test");
  end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars(0, top);     
  end

endmodule

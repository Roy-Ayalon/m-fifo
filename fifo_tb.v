//-----------------------------------------------------------------------------
// Project       : Fifo Test Bench
//-----------------------------------------------------------------------------
// File          : fifo_tb.v
// Author        : Roy Ayalon 
// Created       : 8 April 2023
//-----------------------------------------------------------------------------

module tb;  

// -----------------------------------------------------------------------------
// Parameter / Define
// -----------------------------------------------------------------------------

parameter     WIDTH = 8;        
parameter     DEPTH = 4;
parameter     RESET_VAL = 0;      
localparam    L2DEPTH = $clog2(DEPTH);
localparam    L2DEPTHP1 = $clog2(DEPTH+1);

// -----------------------------------------------------------------------------
// Register/Wires Declarations
// -----------------------------------------------------------------------------

  reg                                 clk;
  reg                                 rst_n;
  reg                                 push;
  reg                                 pop;
  reg  [WIDTH-1:0]                    data_in;
  wire [WIDTH-1:0]                    data_out;
  wire                                empty;
  wire                                full;
  wire [L2DEPTHP1-1:0]                count; 

// -----------------------------------------------------------------------------
//  TEST
// -----------------------------------------------------------------------------

initial begin
$display("TEST STARTED");
clk = 0;
rst_n = 0;
data_in = 0;
push = 0;
pop = 0;


repeat (5) @(posedge clk);
#1;
rst_n = 1;

repeat (5) @(posedge clk);
push_t(6);
push_t(42);
repeat (7) @(posedge clk);
//push_t(17);
//push_t(36);
//push_t(1);
repeat (7) @(posedge clk);
pop_t(6);
repeat (7) @(posedge clk);
//pop_t(42);
repeat (5) @(posedge clk);

$display("TEST FINISHED");
$finish;
end

// -----------------------------------------------------------------------------
//  TASKS & Functions
// -----------------------------------------------------------------------------
task push_t;
input [WIDTH-1:0] data;
@(posedge clk) begin
push = 1'b1;
data_in = data;
repeat(1) @(posedge clk);
push = 1'b0;
end
endtask

task pop_t;
input [WIDTH-1:0] data;
@(posedge clk) begin
pop = 1'b1;
if(data_out != data) begin
$display("DATA OUT ISN'T AS ECPECTED!");
$finish;
end
repeat(1) @(posedge clk);
pop = 1'b0;
end
endtask 

// -----------------------------------------------------------------------------
// clock / reset generator
// -----------------------------------------------------------------------------

always #5 clk = ~clk;

// -----------------------------------------------------------------------------
//  DUT
// -----------------------------------------------------------------------------

m_fifo #(.WIDTH(WIDTH),
         .RESET_VAL(RESET_VAL),
         .DEPTH(DEPTH)
) m_fifo (
.clk(clk),
.rst_n(rst_n),
.push(push),
.pop(pop),
.empty(empty),
.full(full),
.data_in(data_in),
.count(count),
.data_out(data_out));

// -----------------------------------------------------------------------------
//  Waves
// -----------------------------------------------------------------------------
initial begin
$dumpfile("tb.vcd");
$dumpvars(1,tb);
end 


endmodule

// =============================================================================
// Author  : Roy Ayalon
// =============================================================================
// Description:
// FIFO
//
// =============================================================================
// Design Parameters:
// NAME                         DESCRIPTION
// ----                         -----------
// - WIDTH                      Width of data path
// - [WIDTH-1:0] RESET_VAL      Reset value for data path
// - DEPTH                      Depth of FIFO
// - L2DEPTH                    log of DEPTH
// - P1                         log of DEPTH+1 - for counter
// 
// Inputs:
// - clk                        --> the clock that is used to evaluate the expression
// - rst_n                      --> the expression will not be evaluated if rst_n===1'b0
// - data_in                    --> the data we want to send 
// - pop                        --> extract the first elements in the fifo
// - push                       --> add element to fifo
//
// Outputs:
// - count                      --> count the number of elements in the fifo
// - empty                      --> =1'b1 when there r no elements in the fifo. sampaled
// - full                       --> =1'b1 when there is no room in the fifo. sampled
// - data_out                   --> fifo output. not sampaled
// =============================================================================


//========
// Module
//========

module m_fifo
#(parameter     WIDTH = 8,          //Width of data path
  parameter     DEPTH = 9,
  parameter     RESET_VAL = 0,      //Reset value for data path
  localparam    L2DEPTH = $clog2(DEPTH),
  localparam    L2DEPTHP1 = $clog2(DEPTH+1)
)
(
  input                                 clk,
  input                                 rst_n,
  input                                 push,
  input                                 pop,
  input  [WIDTH-1:0]                    data_in,
  output [WIDTH-1:0]                    data_out,
  output                                empty,
  output                                full,
  output [L2DEPTHP1-1:0]                count // How many elements currently in the FIFO  
);
//========
// wire
//========

wire [L2DEPTH-1:0]              read_ptr;
wire                            read_ptr_en;
wire [L2DEPTH-1:0]              read_ptr_ns;   
wire [L2DEPTH-1:0]              write_ptr;
wire                            write_ptr_en;
wire [L2DEPTH-1:0]              write_ptr_ns;    
wire [DEPTH-1:0][WIDTH-1:0]     fifo;
wire                            full_ptr_en;
wire                            full_ptr_ns;
wire                            full_reset;
wire                            full_set;
wire                            count_en;
wire [L2DEPTHP1-1:0]            count_ns;
wire                            empty_ptr_en;
wire                            empty_ptr_ns;
wire                            empty_reset;
wire                            empty_set;



// synopsys translate_off
wire                            pop_on_empty;
wire                            push_on_full;
assign pop_on_empty = (empty & pop);
assign push_on_full = (full & push);

m_assert#(.MESSAGE("POP ON EMPTY!")) m_assert1
(
.clk(clk),
.rst_n(rst_n),
.expr(pop_on_empty)
);

m_assert #(.MESSAGE("PUSH ON FULL!")) m_assert2 
(
.clk(clk),
.rst_n(rst_n),
.expr(push_on_full)
);

// synopsys translate_on

//========
// read_ptr
//========

assign read_ptr_en = pop;
assign read_ptr_ns = (read_ptr == (DEPTH-1)) ? '0 : read_ptr + {{L2DEPTH-1{1'b0}},1'b1};

m_ff 
#(.WIDTH(L2DEPTH)
)
m_ff_read_ptr
(
.clk(clk),
.rst_n(rst_n),
.enable(read_ptr_en),
.data_in(read_ptr_ns),
.data_out(read_ptr)
);

//========
// write_ptr    
//========

assign write_ptr_en = push;
assign write_ptr_ns = (write_ptr == (DEPTH-1)) ? '0 : write_ptr + {{L2DEPTH-1{1'b0}},1'b1};

m_ff 
#(.WIDTH(L2DEPTH)
)
m_ff_write_ptr
(
.clk(clk),
.rst_n(rst_n),
.enable(write_ptr_en),
.data_in(write_ptr_ns),
.data_out(write_ptr)
);


//========
// FIFO
//========
genvar i0;

generate
for (i0=0; i0<DEPTH; i0=i0+1) begin : i0_fifo

m_ff 
#(.WIDTH(WIDTH),
  .RESET_VAL(RESET_VAL)
)
m_ff_fifo
(
.clk(clk),
.rst_n(rst_n),
.enable(push & (write_ptr == i0)),
.data_in(data_in),
.data_out(fifo[i0])
);

end
endgenerate

//========
// DATA_OUT
//========

assign data_out = fifo[read_ptr];

//========
// FULL
//========

assign full_reset = pop;
assign full_set = push & (~pop) & (count == DEPTH-1);
assign full_ptr_en = (full_reset | full_set);
assign full_ptr_ns = full_reset ? 1'b0 : 1'b1;

m_ff 
#(.WIDTH(1)
)
m_ff_full
(
.clk(clk),
.rst_n(rst_n),
.enable(full_ptr_en),
.data_in(full_ptr_ns),
.data_out(full)
);

//========
// EMPTY
//========

assign empty_reset = push;
assign empty_set = (pop & (~push) & (count == 1'b1)) | count == 1'b0;
assign empty_ptr_en = empty_reset | empty_set;
assign empty_ptr_ns = empty_reset ? 1'b0 : 1'b1;

m_ff 
#(.WIDTH(1)
)
m_ff_empty
(
.clk(clk),
.rst_n(rst_n),
.enable(empty_ptr_en),
.data_in(empty_ptr_ns),
.data_out(empty)
);

//========
// COUNT 
//========

assign count_en = pop | push;
assign count_ns = count + {{L2DEPTHP1-1{1'b0}},push} - {{L2DEPTHP1-1{1'b0}},pop}; 

m_ff 
#(.WIDTH(L2DEPTHP1)
)
m_ff_count
(
.clk(clk),
.rst_n(rst_n),
.enable(count_en),
.data_in(count_ns),
.data_out(count)
);

endmodule
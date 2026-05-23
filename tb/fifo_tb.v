`timescale 1ns / 1ns

// =============================================================================
// Self-checking testbench for m_fifo.
//
// Drives a sequence of push/pop operations and verifies FIFO ordering against
// a software scoreboard queue. End-of-test prints one of three banners:
//   - print_pass  -> all pop'd bytes matched the scoreboard          (PASS)
//   - print_fail  -> a data mismatch (or push-on-full / pop-on-empty) (FAIL)
//   - print_error -> simulation watchdog timed out                   (ERROR)
//
// Style follows father's tb_uart.v (m-UART/tb/tb_uart.v):
//   * ASCII-art PASS / FAIL / ERROR banners
//   * #1 after every @(posedge clk) before driving stimulus (lesson #4)
//   * Watchdog initial block enforces SIM_LENGTH timeout
// =============================================================================

module tb;

// -----------------------------------------------------------------------------
// Parameter / Define
// -----------------------------------------------------------------------------

parameter WIDTH       = 8;
parameter DEPTH       = 4;
parameter RESET_VAL   = 0;
parameter SIM_LENGTH  = 20000;

localparam L2DEPTH    = $clog2(DEPTH);
localparam L2DEPTHP1  = $clog2(DEPTH+1);

// -----------------------------------------------------------------------------
// Register / Wires
// -----------------------------------------------------------------------------

reg                   clk;
reg                   rst_n;
reg                   push;
reg                   pop;
reg  [WIDTH-1:0]      data_in;
wire [WIDTH-1:0]      data_out;
wire                  empty;
wire                  full;
wire [L2DEPTHP1-1:0]  count;

// Scoreboard: software queue of bytes pushed, popped FIFO-order to compare.
reg  [WIDTH-1:0]      sb_queue [0:1023];
integer               sb_head;
integer               sb_tail;

// -----------------------------------------------------------------------------
// Clock / Reset
// -----------------------------------------------------------------------------

always #5 clk = ~clk;

initial begin
    clk     = 1'b0;
    rst_n   = 1'b0;
    push    = 1'b0;
    pop     = 1'b0;
    data_in = '0;
    sb_head = 0;
    sb_tail = 0;

    repeat (5) @(posedge clk);
    #1;
    rst_n = 1'b1;
end

// -----------------------------------------------------------------------------
// Watchdog -> ERROR banner if the test hangs
// -----------------------------------------------------------------------------

initial begin
    #SIM_LENGTH;
    $display("WATCHDOG: simulation exceeded %0d time units", SIM_LENGTH);
    print_error;
    $finish(2);
end

// -----------------------------------------------------------------------------
// Test sequence
// -----------------------------------------------------------------------------

initial begin
    $display("TEST STARTED");

    @(posedge rst_n);
    repeat (3) @(posedge clk);

    // ---- Test 1: ordering — push three, pop three -------------------------
    $display("[T1] push three bytes then pop three — ordering check");
    t_push(8'h06);
    t_push(8'h2A);
    t_push(8'h17);
    t_pop;
    t_pop;
    t_pop;

    // ---- Test 2: fill to full then check the full flag --------------------
    $display("[T2] fill to DEPTH=%0d, verify full=1", DEPTH);
    t_push(8'h11);
    t_push(8'h22);
    t_push(8'h33);
    t_push(8'h44);
    @(posedge clk); #1;
    if (full !== 1'b1) begin
        $display("ERROR @ %0t: full not asserted after %0d pushes (full=%b, count=%0d)",
                 $time, DEPTH, full, count);
        print_fail;
        $finish;
    end

    // ---- Test 3: drain to empty then check the empty flag -----------------
    $display("[T3] drain to zero, verify empty=1");
    t_pop;
    t_pop;
    t_pop;
    t_pop;
    @(posedge clk); #1;
    if (empty !== 1'b1) begin
        $display("ERROR @ %0t: empty not asserted after draining (empty=%b, count=%0d)",
                 $time, empty, count);
        print_fail;
        $finish;
    end

    // ---- Test 4: pointer wrap-around --------------------------------------
    $display("[T4] interleaved push/pop to exercise pointer wrap");
    t_push(8'hAA);
    t_push(8'hBB);
    t_pop;
    t_push(8'hCC);
    t_push(8'hDD);
    t_pop;
    t_pop;
    t_pop;

    repeat (5) @(posedge clk);

    print_pass;
    $display("TEST FINISHED");
    $finish;
end

// -----------------------------------------------------------------------------
// Driver tasks
// -----------------------------------------------------------------------------

task t_push;
    input [WIDTH-1:0] data;
    begin
        @(posedge clk); #1;
        if (full === 1'b1) begin
            $display("ERROR @ %0t: push attempted while FIFO is full", $time);
            print_fail;
            $finish;
        end
        push              = 1'b1;
        data_in           = data;
        sb_queue[sb_tail] = data;
        sb_tail           = sb_tail + 1;
        $display("  PUSH data=0x%02h  (count_before=%0d)", data, count);
        @(posedge clk); #1;
        push    = 1'b0;
        data_in = '0;
    end
endtask

task t_pop;
    reg [WIDTH-1:0] expected;
    begin
        @(posedge clk); #1;
        if (empty === 1'b1) begin
            $display("ERROR @ %0t: pop attempted while FIFO is empty", $time);
            print_fail;
            $finish;
        end
        expected = sb_queue[sb_head];
        sb_head  = sb_head + 1;
        if (data_out !== expected) begin
            $display("Check DATA FAILED at %0t:", $time);
            $display("   ERROR - expected = 0x%02h", expected);
            $display("   ERROR - actual   = 0x%02h", data_out);
            repeat (2) @(posedge clk);
            print_fail;
            $finish;
        end
        $display("  POP  data=0x%02h  (matched)", data_out);
        pop = 1'b1;
        @(posedge clk); #1;
        pop = 1'b0;
    end
endtask

// -----------------------------------------------------------------------------
// Banner tasks (father's style)
// -----------------------------------------------------------------------------

task print_pass;
    begin
        $display(" #####    ##    ####   ####  ");
        $display(" #    #  #  #  #      #      ");
        $display(" #    # #    #  ####   ####  ");
        $display(" #####  ######      #      # ");
        $display(" #      #    # #    # #    # ");
        $display(" #      #    #  ####   ####  ");
        $display("UVM TEST PASSED");
    end
endtask

task print_fail;
    begin
        $display(" ######   ##   # #      ");
        $display(" #       #  #  # #      ");
        $display(" #####  #    # # #      ");
        $display(" #      ###### # #      ");
        $display(" #      #    # # #      ");
        $display(" #      #    # # ###### ");
        $display("UVM TEST FAILED");
    end
endtask

task print_error;
    begin
        $display(" ###### #####  #####   ####  #####  ");
        $display(" #      #    # #    # #    # #    # ");
        $display(" #####  #    # #    # #    # #    # ");
        $display(" #      #####  #####  #    # #####  ");
        $display(" #      #   #  #   #  #    # #   #  ");
        $display(" ###### #    # #    #  ####  #    # ");
        $display("UVM TEST ERROR");
    end
endtask

// -----------------------------------------------------------------------------
// DUT
// -----------------------------------------------------------------------------

m_fifo #(
    .WIDTH    (WIDTH),
    .DEPTH    (DEPTH),
    .RESET_VAL(RESET_VAL)
) m_fifo_dut (
    .clk      (clk),
    .rst_n    (rst_n),
    .push     (push),
    .pop      (pop),
    .data_in  (data_in),
    .data_out (data_out),
    .empty    (empty),
    .full     (full),
    .count    (count)
);

// -----------------------------------------------------------------------------
// Waves
// -----------------------------------------------------------------------------

initial begin
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);
end

endmodule

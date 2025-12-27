`default_nettype none
`timescale 1ns / 1ps

/* This testbench just instantiates the module and makes some convenient wires
   that can be driven / tested by the cocotb test.py.
*/
module tb ();

  // Wire up the inputs and outputs:
  reg        rstb;
  reg        ready;
  reg  [7:0] data_in;
  wire [7:0] data_out;
  wire       r_w;
  wire       data_vld;
  wire       start;
  wire       stop;
  reg        scl_in;
  wire       scl_oe;
  reg        sda_in;
  wire       sda_oeb;

  i2c_slave i2c_slave_i (
    .rstb      (rstb),
    .ready     (ready),
    .data_in   (data_in),
    .data_out  (data_out),
    .r_w       (r_w),
    .data_vld  (data_vld),
    .start     (start),
    .stop      (stop),
    .scl_in    (scl_in),
    .scl_oe    (sdl_oe),
    .sda_in    (sda_in),
    .sda_oe    (sda_oe)
  );

  // Dump the signals to a FST file. You can view it with gtkwave or surfer.
  initial begin
    $dumpfile("tb.fst");
    $dumpvars(0, tb);
    #1;
  end

endmodule
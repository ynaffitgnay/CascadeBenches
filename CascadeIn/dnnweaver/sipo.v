//`timescale 1ns/1ps
`ifndef __sipo_v__
`define __sipo_v__

`include "common.vh"
`include "register_1_stage_1_bit.v"
module sipo
#( // INPUT PARAMETERS
    parameter  DATA_IN_WIDTH  = 16,
    parameter  DATA_OUT_WIDTH = 64
)( // PORTS
    input  wire                         clk,
    input  wire                         reset,
    input  wire                         enable,
    input  wire [DATA_IN_WIDTH -1 : 0]  data_in,
    output wire                         ready,
    output wire [DATA_OUT_WIDTH -1 : 0] data_out,
    output wire                         out_valid
);

// ******************************************************************
// LOCALPARAMS
// ******************************************************************
    localparam integer NUM_SHIFTS = DATA_OUT_WIDTH / DATA_IN_WIDTH;
    localparam integer SHIFT_COUNT_WIDTH = `C_LOG_2(NUM_SHIFTS)+1;
// ******************************************************************

// ******************************************************************
// WIRES and REGS
// ******************************************************************
  wire                                        parallel_load;
  reg  [ SHIFT_COUNT_WIDTH    -1 : 0 ]        shift_count;
  reg  [ DATA_OUT_WIDTH       -1 : 0 ]        shift;
// ******************************************************************

    assign parallel_load = shift_count == NUM_SHIFTS;
    assign ready = 1'b1;
    wire parallel_load_d;
    assign out_valid = !parallel_load_d && parallel_load;
    assign data_out = shift;

    always @(posedge clk)
    begin: SHIFTER_COUNT
      if (reset)
        shift_count <= 0;
      else
      begin
        if (enable && !out_valid)
          shift_count <= shift_count + 1;
        else if (enable && out_valid)
          shift_count <= 1;
        else if (out_valid)
          shift_count <= 0;
      end
    end

    always @(posedge clk)
    begin: DATA_SHIFT
      if (reset)
        shift <= 0;
      else if (enable) begin
        if (DATA_OUT_WIDTH == DATA_IN_WIDTH)
          shift <={data_in};
        else
          shift <= {data_in, shift[DATA_OUT_WIDTH-1:DATA_IN_WIDTH]};
      end
    end

    register_1_stage_1_bit push_delay (
    .CLK                      ( clk                      ),
    .RESET                    ( reset                    ),
    .DIN                      ( parallel_load            ),
    .DOUT                     ( parallel_load_d          )
    );

    //always @(posedge clk) begin
    //    if (out_valid) begin
    //        $display("SIPO OUT_VALID!!");
    //
    //        $finish(2);
    //    end
    //    else begin
    //        $display("sipo out not valid: parallel_load_d: %d, parallel_load: %d", parallel_load_d, parallel_load);
    //    end
    //end



endmodule

`endif

//reg rst;
//reg enable;
//reg [15:0] din;
//wire ready;
//wire [15:0] dout;
//wire out_valid;
//
//sipo ts(clock.val, rst, enable, din, ready, dout, out_valid);

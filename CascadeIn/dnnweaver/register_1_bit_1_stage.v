`ifndef __register_1_bit_1_stage_v__
`define __register_1_bit_1_stage_v__

module register_1_bit_1_stage
(
    input  wire                  CLK,
    input  wire                  RESET,
    input  wire                  DIN,
    output wire                  DOUT
);

genvar i;
generate
    reg din_delay;
    always @(posedge CLK)
    begin
        if(RESET)
        begin
            din_delay <= 0;
        end else
        begin
            din_delay <= DIN;
        end
    end
    
    assign DOUT = din_delay;
endgenerate


endmodule
`endif //  `ifndef __register_1_bit_1_stage_v__

//reg rst;
//wire din;
//wire dout;
//
//register_1_bit r(clock.val, rst, din, dout);


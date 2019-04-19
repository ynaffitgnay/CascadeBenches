
module hang_on_ternary( clk );
  input wire clk;
  parameter WIDTH = 56;
  parameter WIDTH_LOG = 6;

  wire [WIDTH_LOG - 1:0] msb;

  genvar i;

  for (i = 1; i < WIDTH_LOG; i = i + 1) begin : ORS
    wire [WIDTH - 1:0] oi;

    assign oi = msb[i - 1] ? 0 : 1;
    assign msb[i] = |oi;
    
  end 
endmodule // hang_on_ternary



hang_on_ternary ht(clock.val);

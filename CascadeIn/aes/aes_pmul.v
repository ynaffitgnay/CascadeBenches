// Some synthesis tools don't like xtime being called recursevly ...
module aes_pmul#(parameter LEVEL = 0)(b, out_b);
  input wire [7:0] b;
  output reg [7:0] out_b;

  wire [7:0] two;
  wire [7:0] four;
  wire [7:0] eight;

  assign two = {b[6:0],1'b0}^(8'h1b&{8{b[7]}});
  assign four = {two[6:0],1'b0}^(8'h1b&{8{two[7]}});
  assign eight = {four[6:0],1'b0}^(8'h1b&{8{four[7]}});

  always @(*) begin
    case (LEVEL)
      0: out_b = eight^two^b;    // b
      1: out_b = eight^four^b;   // d
      2: out_b = eight^b;        // 9
      3: out_b = eight^four^two; // e
    endcase // case (LEVEL)
  end
endmodule

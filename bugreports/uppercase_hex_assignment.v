wire [63:0] x;
wire [63:0] y;
assign x = 64'hDEADDEADDEADDEAD;
assign y = 64'hdeaddeaddeaddead;
initial $display("%h", x);
initial $display("%h", y);

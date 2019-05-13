module showbits#( N )( ldBfr, bits );
  parameter N = 1;

  input wire ldBfr;
  output wire[N - 1:0] bits;

  assign bits = ldBfr >> ((32 - N) % 32);

endmodule // showbits

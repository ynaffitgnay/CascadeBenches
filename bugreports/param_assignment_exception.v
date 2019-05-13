module rsize_gen#(
  parameter R_SIZE = 200
)(
);
  wire[4:0] r_size;

  assign r_size = (R_SIZE % 5'd32);


endmodule

rsize_gen rg();


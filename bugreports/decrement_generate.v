module backwards_generator();
  parameter K = 8;

  genvar i;
  for (i = K - 1; i >= 0; i = i - 1) begin
    if (i == K - 1) initial $display("Started generating");
    else if (i == 0) initial $display("Finished generating");

    wire[31:0] xi;
  end

endmodule // backwards_generator

backwards_generator bg();


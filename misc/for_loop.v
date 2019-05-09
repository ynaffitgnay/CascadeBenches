module sum_in_for( );
  reg[31:0] ctr;
  integer i = 0;

  initial begin
    ctr = 0;

    for (i = 0; i < 10; i = i + 1) begin
      ctr = ctr + 1;
    end

    $display(ctr);

  end

endmodule

sum_in_for si();

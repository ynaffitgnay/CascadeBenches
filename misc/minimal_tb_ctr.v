module minimal_tb_with_ctr( clk );
  input wire clk;
  reg[31:0] ctr;

  initial begin
    ctr <= 0;
    $display("State 1");
    if (ctr == 2) $display("State 2");
    if (ctr == 10) begin
      $display("State 3");
      ctr <= 0;
    end
    if (ctr == 2) $display("State 4");
    if (ctr == 10) begin
      $display("State 5");
      ctr <= 0;
    end
    $finish();

  end

  
  always @(posedge clk) ctr <= ctr + 1;

    

endmodule; // minimal_tb_with_ctr

minimal_tb_with_ctr mc( clock.val );

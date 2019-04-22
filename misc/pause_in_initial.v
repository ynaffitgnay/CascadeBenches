module pause_in_initial(clk, rst);
  input wire clk;
  input wire rst;
  reg [31:0] ctr;


  initial begin
    ctr = 0;

    $display("Start");
    $display("rst: %d", rst);

    while(!rst) begin
      $display("rst: %d", rst);
      @(posedge clk);
    end


    repeat(10) begin 
      @(posedge clk);
      $display("am i in here");
    end
    $display("End");
    $finish();

  end

  always @(posedge clk) begin
    ctr = ctr + 1;
    $display(ctr);
  end

    
endmodule; // pause_in_initial

reg rst  = 1;

pause_in_initial pi(clock.val, rst);

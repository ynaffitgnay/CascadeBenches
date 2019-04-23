module pause_in_initial(clk, rst);
  input wire clk;
  input wire rst;
  reg [31:0] ctr;


  initial begin
    $display("Another initial block");
  end

  initial begin
    ctr = 0;

    $display("Start");
    $display("rst: %d", rst);


    // this while loop doesn't appear to change
    //while(!rst) begin
    //  $display("rst: %d", rst);
    //  @(posedge clk);
    //end


    repeat(10) begin 
      @(posedge clk);
      $display("am i in here");
    end
    $display("End");
    $finish();

  end // initial begin


  always @(posedge clk) begin
    ctr = ctr + 1;
    $display(ctr);
  end

    
endmodule; // pause_in_initial

reg rst  = 1;

pause_in_initial pi(clock.val, rst);

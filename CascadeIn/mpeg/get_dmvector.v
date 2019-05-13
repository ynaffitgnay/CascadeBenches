module get_dmvector(clk, rst, buf, inReady, done, dmvec );
  input wire clk;
  input wire rst;
  input wire [1:0] buf;
  input wire inReady;
  
  output reg done;
  output signed dmvec;

  initial $display("oohooh, inready: %d", inReady);


  always @(posedge clk) begin
    if (rst) begin
      done <= 1'b0;
    end
    else if (inReady) begin
      done <= 1'b1;
      //$display("dmvec: %d", dmvec);

    end
  end

  assign dmvec = (buf[1] ? (buf[0] ? -1 : 1) : 0);


endmodule // get_dmvector


reg[1:0] buf;
reg rst;
reg inReady = 1;
reg[5:0] outshift;
reg done;
reg signed dmvec;

always @(posedge clock.val) begin
  buf <= {1'b1, 1'b1};
  $display("dmvec: %d", dmvec);
end


get_dmvector gdm(clock.val, rst, buf, inReady, done, dmvec);

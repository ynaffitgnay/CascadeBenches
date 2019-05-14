module flushbuffer#(
  parameter BYTES = 2048;
)(
  clk, 
  rst,
  N,
  in_valid,
  in_incnt,
  in_bfr, 
  out_ld_bfr, 
  out_incnt,
  done
);
  
  input wire clk;
  input wire rst;

  input wire [31:0] N;
  input wire in_valid;
  input wire [31:0] in_incnt;


  input reg[BYTES * 8] in_bfr;

  output reg[31:0] out_ld_bfr;
  output reg[31:0] out_incnt;

  reg [31:0] ld_bfr;
  wire [31:0] incnt1;
  integer bytes_read;


  always @(posedge clk) begin
    if (rst) begin
      ld_bfr <= 32'h4100000;
      out_incnt <= 32'b0;
      done <= 1'b0;
      out_ld_bfr <= 0;  // TODO: something reasonable

      //temp_incnt <= 0;
      bytes_read <= 0;
    end
    if (in_valid) begin
      // TODO: figure out how to mark inCnt as invalid
      // also deal with clock cycle delay between assigning incnt and getting incnt...
      $display("incnt1: %d", incnt1);

    end

    assign incnt1 = in_incnt - N;
    

  end

  


endmodule


// INITIALIZE FLUSH_BUFFER WITH IN_INCNT AS 0.
// in_incnt should be a reg that gets set to out_incnt from top module whenever
// flushbuffer = done

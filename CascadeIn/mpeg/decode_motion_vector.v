module decode_motion_vector#(
  parameter R_SIZE = 200
)(
  clk,
  rst,
  in_pred,
  motion_code, 
  motion_residual, 
  in_valid,
  full_pel_vector,
  out_pred,
  done
);
  input wire clk;
  input wire rst;
  input wire [31:0] in_pred;
  input wire signed [31:0] motion_code;
  input wire [31:0] motion_residual;
  input wire in_valid;
  input wire full_pel_vector;
  
  output wire [31:0] out_pred;
  output reg done;

  wire[4:0] r_size;
  wire signed [31:0] lim;
  wire signed [31:0] vec1, vec2, vec3;
  wire signed [31:0] vec;




  always @(posedge clk) begin
    if (rst) begin
      done <= 1'b0;
    end
    else if (in_valid) begin
      // After one clock cycle, pred should be valid
      done <= 1'b1;
      //$display("lim: %d, vec: %d", lim, vec);
      $display("in_pred: %d, motion_code: %d, motion_residual: %d, out_pred: %d", in_pred, motion_code, motion_residual, out_pred);

    end


  end

  assign r_size = (R_SIZE % 32);
  assign lim = (16 << r_size);
  assign vec1 = (full_pel_vector) ? (in_pred >> 1) : (in_pred);

  assign vec2 = (motion_code > 0) ? 
                (((motion_code - 1) << r_size) + motion_residual + 1) :
                (motion_code < 0 ? 
                ((((-motion_code - 1) << r_size) + (motion_residual + 1)) * -1) :
                 0);


  assign vec3 = (motion_code > 0) ? (((vec1 + vec2) >= lim) ? ((lim + lim) * -1) : 0) :
                (motion_code < 0 ? (((vec1 + vec2) < -lim) ? (lim + lim) : 0) : 0);

  assign vec = vec1 + vec2 + vec3;

  assign out_pred = full_pel_vector ? (vec << 1) : vec;

endmodule // decode_motion_vector

/*
reg rst;
integer in_pred;
integer motion_code;
integer motion_residual;
reg in_valid;
reg full_pel_vector;

reg [31:0] out_pred;
reg done;
integer ctr = 0;


initial begin
  in_pred = 32'd45;
  motion_code = 6;
  motion_residual = 240;
  full_pel_vector = 0;
  in_valid = 1;
end


always @(posedge clock.val) begin
  ctr <= ctr + 1;
  $display("out_pred: %d", out_pred);

  if (done) $display("done: out_pred: %d", out_pred);
  
  if (ctr == 5) $finish;

end

decode_motion_vector dmv(clock.val, rst, in_pred, motion_code, motion_residual, 
                         in_valid, full_pel_vector, out_pred, done);


*/

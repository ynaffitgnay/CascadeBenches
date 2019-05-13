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
  input wire [31:0] motion_code;
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
      //out_pred <= 32'b0;
      done <= 1'b0;
    end

    else if (in_valid) begin
      // After one clock cycle, pred should be valid
      done <= 1'b1;
      //$display("lim: %d, vec: %d", lim, vec);
      //$display("out_pred: %d", out_pred);

    end


  end

  assign r_size = (R_SIZE % 32);
  assign lim = (16 << r_size);
  assign vec1 = (full_pel_vector) ? (in_pred >> 1) : (in_pred);

  // 17 is defined as ERROR in get_motion_code
  // (all motion codes should be between 0 and 17)
  assign vec2 = (motion_code < 17) ? 
                (((motion_code - 1) << r_size) + motion_residual + 1) :
                ((motion_residual + 1) * -1) ;

  assign vec3 = (motion_code < 17) ? (((vec1 + vec2) >= lim) ? ((lim + lim) * -1) : 0) :
                                     (((vec1 + vec2) < -lim) ? (lim + lim) : 0);

  assign vec = vec1 + vec2 + vec3;

  assign out_pred = (motion_code == 0) ? (vec1) : (full_pel_vector ? (vec << 1) : vec);

endmodule

reg rst;
integer in_pred;
integer motion_code;
integer motion_residual;
reg in_valid;
reg full_pel_vector;

reg [31:0] out_pred;
reg done;

initial begin
  in_pred = 32'd45;
  motion_code = 6;
  motion_residual = 240;
  full_pel_vector = 0;
  in_valid = 1;
end




decode_motion_vector dmv(clock.val, rst, in_pred, motion_code, motion_residual, 
                         in_valid, full_pel_vector, out_pred, done);



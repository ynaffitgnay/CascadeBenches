module get_motion_code(clk, rst, buf, in_valid, outshift, done, mcode );
  localparam ERROR = -1;

  input wire clk;
  input wire rst;
  input wire [10:0] buf;
  input wire in_valid;
  
  output wire [4:0] outshift;
  output reg done;
  output wire signed[4:0] mcode;

  wire [4:0] MVtab0[7:0][1:0];
  wire [4:0] MVtab1[7:0][1:0];
  wire [4:0] MVtab2[11:0][1:0];

  wire [8:0] code1;
  wire [31:0] code2;
  wire [4:0] check_output_bit;
  wire signed[4:0] mcode1;


  always @(posedge clk) begin
    if (rst)
      done <= 1'b0;
    else if (in_valid) begin      
      done <= 1'b1;
      $display("code2: %d, check_output_bit: %d", code2, check_output_bit);

    end


  end

  assign code1 = buf[9:1];
  
  assign code2 = (code1 >= 64) ? (code1 >> 6) : ((code1 >= 24) ? code1 >> 3 : code1);
  assign outshift = 1 + (buf[10] ? 0 : ((code1 >= 64) ? ((MVtab0[code2][1]) + 1) : ((code1 >= 24) ? (MVtab1[code2][1] + 1) : ((code1 < 12) ? 0 : (MVtab2[code2][1] + 1)))));
  assign mcode1 = (code1 >= 64) ? MVtab0[code2][0] : ((code1 >= 24) ? MVtab1[code2][0] : ((code1 < 12) ? 0 : (MVtab2[code2][1])));
  assign check_output_bit = 10 - (outshift - 1);
  assign mcode = buf[10] ? 0 : ((code1 < 12) ? 0 : (buf[check_output_bit] ? (mcode1 * -1) : mcode1));
 
  

  assign MVtab0[0][0] = ERROR;
  assign MVtab0[0][1] = 5'd0;
  assign MVtab0[1][0] = 5'd3;
  assign MVtab0[1][1] = 5'd3;
  assign MVtab0[2][0] = 5'd2;
  assign MVtab0[2][1] = 5'd2;
  assign MVtab0[3][0] = 5'd2;
  assign MVtab0[3][1] = 5'd2;
  assign MVtab0[4][0] = 5'd1;
  assign MVtab0[4][1] = 5'd1;
  assign MVtab0[5][0] = 5'd1;
  assign MVtab0[5][1] = 5'd1;
  assign MVtab0[6][0] = 5'd1;
  assign MVtab0[6][1] = 5'd1;
  assign MVtab0[7][0] = 5'd1;
  assign MVtab0[7][1] = 5'd1;

  assign MVtab1[0][0] = ERROR;
  assign MVtab1[0][1] = 5'd0;
  assign MVtab1[1][0] = ERROR;
  assign MVtab1[1][1] = 5'd0;
  assign MVtab1[2][0] = ERROR;
  assign MVtab1[2][1] = 5'd0;
  assign MVtab1[3][0] = 5'd7;
  assign MVtab1[3][1] = 5'd6;
  assign MVtab1[4][0] = 5'd6;
  assign MVtab1[4][1] = 5'd6;
  assign MVtab1[5][0] = 5'd5;
  assign MVtab1[5][1] = 5'd6;
  assign MVtab1[6][0] = 5'd4;
  assign MVtab1[6][1] = 5'd5;
  assign MVtab1[7][0] = 5'd4;
  assign MVtab1[7][1] = 5'd5;

  
  assign MVtab2[0][0] = 5'd16;
  assign MVtab2[0][1] = 5'd9;
  assign MVtab2[1][0] = 5'd15;
  assign MVtab2[1][1] = 5'd9;
  assign MVtab2[2][0] = 5'd14;
  assign MVtab2[2][1] = 5'd9;
  assign MVtab2[3][0] = 5'd13;
  assign MVtab2[3][1] = 5'd9;
  assign MVtab2[4][0] = 5'd12;
  assign MVtab2[4][1] = 5'd9;
  assign MVtab2[5][0] = 5'd11;
  assign MVtab2[5][1] = 5'd9;
  assign MVtab2[6][0] = 5'd10;
  assign MVtab2[6][1] = 5'd8;
  assign MVtab2[7][0] = 5'd10;
  assign MVtab2[7][1] = 5'd8;
  assign MVtab2[8][0] = 5'd9;
  assign MVtab2[8][1] = 5'd8;
  assign MVtab2[9][0] = 5'd9;
  assign MVtab2[9][1] = 5'd8;
  assign MVtab2[10][0] = 5'd8;
  assign MVtab2[10][1] = 5'd8;
  assign MVtab2[11][0] = 5'd8;
  assign MVtab2[11][1] = 5'd8;


endmodule // get_motion_code


reg[10:0] buf;
reg in_valid;
reg rst;
reg[5:0] outshift;
reg done;
reg signed[4:0] mcode;
reg[31:0] ctr = 0;


initial begin
  buf = 11'b1000111;
//20'h7ffff;
//20'b1000111100001111;
  in_valid = 1;
  rst = 0;
  

end

always @(posedge clock.val) begin
  ctr <= ctr + 1;

  $display("outshift: %d, mcode: %d", outshift, mcode);

  if (done)
    $display("final: outshift: %d, mcode: %d", outshift, mcode);

  if (ctr == 5) $finish;

end

get_motion_code gmc(clock.val, rst, buf, in_valid, outshift, done, mcode);


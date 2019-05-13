module get_motion_code(clk);
//, buf, inReady, outshift, done, mcode );
  input wire clk;
  //input wire [19:0] buf;
  //input wire inReady;
  //
  //output reg [4:0] outshift;
  //output reg done;
  //output integer mcode;

  localparam ERROR = 17;


  wire [4:0] MVtab0[7:0][1:0];
  wire [4:0] MVtab1[7:0][1:0];
  wire [4:0] MVtab2[11:0][1:0];
  

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

get_motion_code gmc(clock.val);

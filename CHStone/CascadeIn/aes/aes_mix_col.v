module aes_mix_col(s0,s1,s2,s3,out_mc);   
  input	wire [7:0] s0;               
  input wire [7:0] s1;
  input wire [7:0] s2;
  input wire [7:0] s3;
  output wire [31:0] out_mc;

  //xtime(s0)={s0[6:0],1'b0}^(8'h1b&{8{s0[7]}})
  //xtime(s1)={s1[6:0],1'b0}^(8'h1b&{8{s1[7]}})
  //xtime(s2)={s2[6:0],1'b0}^(8'h1b&{8{s2[7]}})
  //xtime(s3)={s3[6:0],1'b0}^(8'h1b&{8{s3[7]}})

  assign out_mc[31:24] = {s0[6:0],1'b0}^(8'h1b&{8{s0[7]}})^{s1[6:0],1'b0}^(8'h1b&{8{s1[7]}})^s1^s2^s3;
  assign out_mc[23:16] = s0^{s1[6:0],1'b0}^(8'h1b&{8{s1[7]}})^{s2[6:0],1'b0}^(8'h1b&{8{s2[7]}})^s2^s3;
  assign out_mc[15:08] = s0^s1^{s2[6:0],1'b0}^(8'h1b&{8{s2[7]}})^{s3[6:0],1'b0}^(8'h1b&{8{s3[7]}})^s3;
  assign out_mc[07:00] = {s0[6:0],1'b0}^(8'h1b&{8{s0[7]}})^s0^s1^s2^{s3[6:0],1'b0}^(8'h1b&{8{s3[7]}});
endmodule

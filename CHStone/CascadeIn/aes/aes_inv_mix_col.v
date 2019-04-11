module aes_inv_mix_col(s0, s1, s2, s3, out_imc);
  input	wire [7:0] s0;
  input wire [7:0] s1;
  input wire [7:0] s2;
  input wire [7:0] s3;

  output reg[31:0] out_imc;

  reg [7:0] out_e_0;
  reg [7:0] out_b_1;
  reg [7:0] out_d_2;
  reg [7:0] out_9_3;

  reg [7:0] out_9_0;
  reg [7:0] out_e_1;
  reg [7:0] out_b_2;
  reg [7:0] out_d_3;

  reg [7:0] out_d_0;
  reg [7:0] out_9_1;
  reg [7:0] out_e_2;
  reg [7:0] out_b_3;

  reg [7:0] out_b_0;
  reg [7:0] out_d_1;
  reg [7:0] out_9_2;
  reg [7:0] out_e_3;

  aes_pmul#(3) pmul_e_0(s0, out_e_0);
  aes_pmul#(0) pmul_b_1(s1, out_b_1);
  aes_pmul#(1) pmul_d_2(s2, out_d_2);
  aes_pmul#(2) pmul_9_3(s3, out_9_3);

  aes_pmul#(2) pmul_9_0(s0, out_9_0);
  aes_pmul#(3) pmul_e_1(s1, out_e_1);
  aes_pmul#(0) pmul_b_2(s2, out_b_2);
  aes_pmul#(1) pmul_d_3(s3, out_d_3);

  aes_pmul#(1) pmul_d_0(s0, out_d_0);
  aes_pmul#(2) pmul_9_1(s1, out_9_1);
  aes_pmul#(3) pmul_e_2(s2, out_e_2);
  aes_pmul#(0) pmul_b_3(s3, out_b_3);

  aes_pmul#(0) pmul_b_0(s0, out_b_0);
  aes_pmul#(1) pmul_d_1(s1, out_d_1);
  aes_pmul#(2) pmul_9_2(s2, out_9_2);
  aes_pmul#(3) pmul_e_3(s3, out_e_3);

  always @(*) begin
    out_imc[31:24]=out_e_0^out_b_1^out_d_2^out_9_3; 
    out_imc[23:16]=out_9_0^out_e_1^out_b_2^out_d_3; 
    out_imc[15:08]=out_d_0^out_9_1^out_e_2^out_b_3;
    out_imc[07:00]=out_b_0^out_d_1^out_9_2^out_e_3;
  end

endmodule

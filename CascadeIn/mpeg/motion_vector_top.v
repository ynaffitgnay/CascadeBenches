module motion_vector_top#(
  parameter S = 0,
  parameter H_R_SIZE = 200,
  parameter V_R_SIZE = 200,
  parameter BYTES = 2048                       
)( 
   clk, 
   rst,
   in_valid,
   in_PMV_0_0_0,
   in_PMV_0_0_1,
   in_PMV_0_1_0,
   in_PMV_0_1_1,
   in_PMV_1_0_0,
   in_PMV_1_0_1,
   in_PMV_1_1_0,
   in_PMV_1_1_1,
   in_mvfs_0_0,
   in_mvfs_0_1,
   in_mvfs_1_0,
   in_mvfs_1_1, 
   dmv, 
   mvscale,
   in_bfr,
   out_PMV_0_0_0,
   out_PMV_0_0_1,
   out_PMV_0_1_0,
   out_PMV_0_1_1,
   out_PMV_1_0_0,
   out_PMV_1_0_1,
   out_PMV_1_1_0,
   out_PMV_1_1_1,
   out_mvfs_0_0,
   out_mvfs_0_1,
   out_mvfs_1_0,
   out_mvfs_1_1, 
   done
);

  localparam BITS = (BYTES << 3);
  localparam S_IDLE = 0;
  localparam S_1 = 1;
  localparam S_2 = 2;
  localparam S_3 = 3;
  localparam S_4 = 4;
  localparam S_5 = 5;
  localparam S_6 = 6;
  localparam S_7 = 7;  


  input wire clk;
  input wire rst;

  input wire in_valid;
  
  input wire [31:0] in_PMV_0_0_0;
  input wire [31:0] in_PMV_0_0_1;
  input wire [31:0] in_PMV_0_1_0;
  input wire [31:0] in_PMV_0_1_1;
  input wire [31:0] in_PMV_1_0_0;
  input wire [31:0] in_PMV_1_0_1;
  input wire [31:0] in_PMV_1_1_0;
  input wire [31:0] in_PMV_1_1_1;
  input wire [31:0] in_mvfs_0_0;
  input wire [31:0] in_mvfs_0_1;
  input wire [31:0] in_mvfs_1_0;
  input wire [31:0] in_mvfs_1_1; 
  
  input wire dmv;
  input wire mvscale;
  input wire [BITS - 1:0] in_bfr;

  output wire [31:0] out_PMV_0_0_0;
  output wire [31:0] out_PMV_0_0_1;
  output wire [31:0] out_PMV_0_1_0;
  output wire [31:0] out_PMV_0_1_1;
  output wire [31:0] out_PMV_1_0_0;
  output wire [31:0] out_PMV_1_0_1;
  output wire [31:0] out_PMV_1_1_0;
  output wire [31:0] out_PMV_1_1_1;
  output wire [31:0] out_mvfs_0_0;
  output wire [31:0] out_mvfs_0_1;
  output wire [31:0] out_mvfs_1_0;
  output wire [31:0] out_mvfs_1_1; 

  output wire done;

  wire[31:0] in_PMV[1:0][1:0][1:0];  
  wire[31:0] in_mvfs[1:0][1:0];
  wire[31:0] out_PMV[1:0][1:0][1:0];
  reg[31:0] out_mvfs[1:0][1:0];

  reg [31:0] fb_N;
  reg fb_in_valid;
  reg fb_loading_bfr;
  reg [31:0] ld_bfr;  // driven by flushbuffer
  reg signed [31:0] incnt;  // driven by flushbuffer
  wire fb_done;

  wire [10:0] h_mcode_inbuf;
  reg h_mcode_in_valid;
  wire [4:0] h_outshift;
  wire h_mcode_done;
  wire signed [4:0] h_mcode;
                              
  wire [31:0] h_in_pred;
  wire [31:0] h_motion_residual;
  reg h_decode_in_valid;
  wire [31:0] h_out_pred;
  reg h_decode_done;
  
  wire [10:0] v_mcode_inbuf;
  reg v_mcode_in_valid;
  wire [4:0] v_outshift;
  wire v_mcode_done;
  wire signed [4:0] v_mcode;

  wire [31:0] v_in_pred;
  wire [31:0] v_motion_residual;
  reg v_decode_in_valid;
  wire [31:0] v_out_pred;
  wire v_decode_done;                                           

  wire [31:0] shift_r_size_mod;
  wire [31:0] shift_r_size_mod_unsigned;
  
  reg[4:0] stage;
  reg[31:0] s1_ld_bfr;
  reg[31:0] s1_incnt;
  reg[31:0] s2_ld_bfr;
  reg[31:0] s2_incnt;
  reg[31:0] s3_ld_bfr;
  reg[31:0] s3_incnt;
  reg[31:0] s6_ld_bfr;
  reg[31:0] s6_incnt;


  always @(posedge clk) begin
    $display("fb_N: %d, stage: %d, h_mcode: %d, v_mcode: %d", fb_N, stage, h_mcode, v_mcode);

    if (rst) begin
      h_decode_in_valid <= 1'b0;
      v_decode_in_valid <= 1'b0;

      fb_N <= 0;
      fb_in_valid <= 0;

      h_mcode_in_valid <= 0;
      h_decode_in_valid <= 0;
      v_mcode_in_valid <= 0;
      v_decode_in_valid <= 0;
      
      s1_ld_bfr <= 32'b0;
      s1_incnt <= 32'b0;
      s2_ld_bfr <= 32'b0;
      s2_incnt <= 32'b0;
      s3_ld_bfr <= 32'b0;
      s3_incnt <= 32'b0;
      s6_ld_bfr <= 32'b0;
      s6_incnt <= 32'b0;

      stage <= S_IDLE;
    end

    case (stage)
      S_IDLE: begin
        if (in_valid) begin
          // Initialize ld_bfr
          fb_N <= 0;
          fb_in_valid <= 1;
          stage <= S_1;
        end
      end

      S_1: begin
        if (fb_done) begin
          // Capture this state so you can continue to use ld_bfr without waiting
          s1_ld_bfr <= ld_bfr;
          s1_incnt <= incnt;
          h_mcode_in_valid <= 1'b1;
          
          fb_in_valid <= 1'b0;
  
          stage <= S_2;
        end
      end // if (stage == S_1)
      
      S_2: begin
        out_mvfs[1][S] <= s1_ld_bfr[s1_incnt - 1];
        out_mvfs[0][S] <= s1_ld_bfr[s1_incnt - 1];
  
        if (h_mcode_done) begin
          fb_N <= 1 + h_outshift;
          
          fb_in_valid <= 1'b1;
          stage <= S_3;        
        end
      end
  
      S_3: begin
         fb_in_valid <= 1'b0;
       
        if (fb_done) begin
          $display("fb_N: %d",fb_N);
  
          s2_ld_bfr <= ld_bfr;
          s2_incnt <= incnt;
  
          h_decode_in_valid <= 1'b1;
  
          fb_N <= (H_R_SIZE != 0 && h_mcode != 0) ? H_R_SIZE : 0;  
          fb_in_valid <= 1'b1;
  
          stage <= S_4;
        end // if (fb_done)
      end // if (stage == S_3)
  
      S_4: begin
        if (fb_done) begin
          s3_ld_bfr <= ld_bfr;
          s3_incnt <= incnt;
  
          v_mcode_in_valid <= 1'b1;
  
          fb_in_valid <= 1'b0;
  
          stage <= S_5;
        end        
      end // if (stage == S_4)   
      
      S_5: begin
        if (v_mcode_done) begin  
          fb_N <= 1 + v_outshift;
          fb_in_valid <= 1'b1;
          stage <= S_6;
        end
      end

      S_6: begin
        // when mcode is done, residual can be completed as soon as buffer flushed
        if (fb_done) begin
          s6_ld_bfr <= ld_bfr;
          s6_incnt <= incnt;

          v_decode_in_valid <= 1'b1;

          fb_N <= (V_R_SIZE != 0 && v_mcode != 0) ? V_R_SIZE : 0;
          fb_in_valid <= 1'b1;
        end
        
        // Idle here
      end
    endcase
  end // always @ (posedge clk)


  // Assign array entries
  assign in_PMV[0][0][0] = in_PMV_0_0_0;
  assign in_PMV[0][0][1] = in_PMV_0_0_1;
  assign in_PMV[0][1][0] = in_PMV_0_1_0;
  assign in_PMV[0][1][1] = in_PMV_0_1_1;
  assign in_PMV[1][0][0] = in_PMV_1_0_0;
  assign in_PMV[1][0][1] = in_PMV_1_0_1;
  assign in_PMV[1][1][0] = in_PMV_1_1_0;
  assign in_PMV[1][1][1] = in_PMV_1_1_1;

  assign in_mvfs[0][0] = in_mvfs_0_0;
  assign in_mvfs[0][1] = in_mvfs_0_1;
  assign in_mvfs[1][0] = in_mvfs_1_0;
  assign in_mvfs[1][1] = in_mvfs_1_1;

  assign out_PMV_0_0_0 = out_PMV[0][0][0];
  assign out_PMV_0_0_1 = out_PMV[0][0][1];
  assign out_PMV_0_1_0 = out_PMV[0][1][0];
  assign out_PMV_0_1_1 = out_PMV[0][1][1];
  assign out_PMV_1_0_0 = out_PMV[0][0][0];  // PMV[1][S][0] = PMV[0][S][0]
  assign out_PMV_1_0_1 = out_PMV[0][0][1];  // PMV[1][S][1] = PMV[0][S][1]
  assign out_PMV_1_1_0 = out_PMV[1][1][0];
  assign out_PMV_1_1_1 = out_PMV[1][1][1];

  assign out_mvfs_0_0 = out_mvfs[0][0];
  assign out_mvfs_0_1 = out_mvfs[0][1];
  assign out_mvfs_1_0 = out_mvfs[1][0];
  assign out_mvfs_1_1 = out_mvfs[1][1];

  // incnt, 1 for setting mvfs, 11 for mcode_inbuf size
  assign h_mcode_inbuf = (s1_ld_bfr >> (s1_incnt - 1 - 11));
  assign h_in_pred = in_PMV[0][S][0];
  assign out_PMV[0][S][0] = h_out_pred;


  assign shift_r_size_mod = ((32 - H_R_SIZE) % 32);
  assign shift_r_size_mod_unsigned = shift_r_size_mod % 32;

  assign h_motion_residual = (H_R_SIZE != 0 && h_mcode != 0) ? (s2_ld_bfr >> shift_r_size_mod_unsigned) : 0;

  assign v_mcode_inbuf = (s3_ld_bfr >> (s3_incnt - 11));
  assign v_in_pred = mvscale ? (in_PMV[0][S][1] >> 1) : in_PMV[0][S][1];
  assign out_PMV[0][S][1] = (mvscale) ? (v_out_pred << 1) : v_out_pred;

  assign v_motion_residual = (V_R_SIZE != 0 && v_mcode != 0) ? (s6_ld_bfr >> shift_r_size_mod_unsigned) : 0;
  
  
  assign done = h_decode_done & v_decode_done;

  flushbuffer#( BYTES ) fb(
                           .clk( clk ),
                           .rst( rst ),
                           .N( fb_N ),
                           .in_valid( fb_in_valid ),
                           .in_bfr( in_bfr ),
                           .loading_bfr( fb_loading_bfr ),
                           .ld_bfr( ld_bfr ),
                           .incnt ( incnt ),
                           .done( fb_done )
                           );

  get_motion_code get_h_mcode(
                              .clk( clk ),
                              .rst( rst ),
                              .buf( h_mcode_inbuf ),
                              .in_valid( h_mcode_in_valid ),
                              .outshift( h_outshift ),
                              .done( h_mcode_done ),
                              .mcode( h_mcode )
                              );

  decode_motion_vector#( H_R_SIZE ) h_decode(
                                             .clk( clk ), 
                                             .rst( rst ), 
                                             .in_pred( h_in_pred ), 
                                             .motion_code( h_mcode ), 
                                             .motion_residual( h_motion_residual ),
                                             .in_valid( h_decode_in_valid ),
                                             .full_pel_vector ( /* UNUSED */ ),
                                             .out_pred( h_out_pred ),
                                             .done( h_decode_done )
                                             );
  get_motion_code get_v_mcode(
                              .clk( clk ),
                              .rst( rst ),
                              .buf( v_mcode_inbuf ),
                              .in_valid( v_mcode_in_valid ),
                              .outshift( v_outshift ),
                              .done( v_mcode_done ),
                              .mcode( v_mcode )
                              );



  decode_motion_vector#( V_R_SIZE ) v_decode(
                                           .clk( clk ), 
                                           .rst( rst ), 
                                           .in_pred( v_in_pred ), 
                                           .motion_code( v_mcode ), 
                                           .motion_residual( v_motion_residual ),
                                           .in_valid( v_decode_in_valid ),
                                           .full_pel_vector ( /* UNUSED */ ),
                                           .out_pred( v_out_pred ),
                                           .done( v_decode_done )
                                           );
    
endmodule 

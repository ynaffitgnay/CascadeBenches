module motion_vector_top#(
  parameter H_R_SIZE = 200,
  parameter V_R_SIZE = 200
)( 
   clk, 
   rst, 
   in_mvfs, 
   s, 
   dmv, 
   mvscale,
   out_mvfs,
   done
);

  input wire clk;
  input wire rst; 
  input integer in_mvfs[1:0][1:0];
  input integer s;
  input wire dmv;
  input wire mvscale;
  output integer out_mvfs[1:0][1:0];
  output reg done;



  reg [31:0] ld_bfr;


  always @(posedge clk) begin
    if (rst) begin
      done <= 1'b0;
    end

    
  end


endmodule 

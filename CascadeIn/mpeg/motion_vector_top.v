module motion_vector_top#(
  parameter S = 0,
  parameter H_R_SIZE = 200,
  parameter V_R_SIZE = 200,
  parameter BYTES = 2048                       
)( 
   clk, 
   rst,
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

  localparam BITS = (BYTES >> 3);

  input wire clk;
  input wire rst;

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

  output reg done;

  wire[31:0] in_PMV[1:0][1:0][1:0];
  wire[31:0] in_mvfs[1:0][1:0];
  wire[31:0] out_PMV[1:0][1:0][1:0];
  reg[31:0] out_mvfs[1:0][1:0];


  reg [31:0] ld_bfr;
  reg signed [31:0] incnt;

  reg [31:0] fb_N;
  reg fb_in_valid;
  reg fb_loading_bfr;
  wire fb_done;


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


  wire [10:0] h_mcode_inbuf;
  reg h_mcode_in_valid;
  wire [4:0] h_outshift;
  wire h_mcode_done;
  wire signed [4:0] h_mcode;


  get_motion_code get_h_mcode(
                              .clk( clk ),
                              .rst( rst ),
                              .buf( h_mcode_inbuf ),
                              .in_valid( h_mcode_in_valid ),
                              .outshift( h_outshift ),
                              .mcode( h_mcode )
                              );

                              
  
  wire [31:0] h_in_pred;
  reg [4:0] h_motion_code;
  reg [31:0] h_motion_residual;
  reg h_code_rcv;
  reg [31:0] h_out_pred;
  reg h_decode_done;

  decode_motion_vector#( H_R_SIZE ) h_decode(
                                           .clk( clk ), 
                                           .rst( rst ), 
                                           .in_pred( h_in_pred ), 
                                           .motion_code( h_motion_code ), 
                                           .motion_residual( h_motion_residual ),
                                           .in_valid( h_code_rcv ),
                                           .full_pel_vector ( /* UNUSED */ ),
                                           .out_pred( h_out_pred ),
                                           .done( h_decode_done )
                                           );

  
  wire [10:0] v_mcode_inbuf;
  reg v_mcode_in_valid;
  wire [4:0] v_outshift;
  wire v_mcode_done;
  wire signed [4:0] v_mcode;


  
  get_motion_code get_v_mcode(
                              .clk( clk ),
                              .rst( rst ),
                              .buf( v_mcode_inbuf ),
                              .in_valid( v_mcode_in_valid ),
                              .outshift( v_outshift ),
                              .mcode( v_mcode )
                              );



  wire [31:0] v_in_pred;
  reg [4:0] v_motion_code;
  reg [31:0] v_motion_residual;
  reg v_code_rcv;
  reg [31:0] v_out_pred;
  reg v_decode_done;

  decode_motion_vector#( V_R_SIZE ) v_decode(
                                           .clk( clk ), 
                                           .rst( rst ), 
                                           .in_pred( v_in_pred ), 
                                           .motion_code( v_motion_code ), 
                                           .motion_residual( v_motion_residual ),
                                           .in_valid( v_code_rcv ),
                                           .full_pel_vector ( /* UNUSED */ ),
                                           .out_pred( v_out_pred ),
                                           .done( v_decode_done )
                                           );

                                           

  integer s0_flushed_bits;



  reg stage[4:0];
  
  

  always @(posedge clk) begin
    if (rst) begin
      done <= 1'b0;
      s0_flushed_bits <= 32'b0;
      h_code_rcv <= 1'b0;
      v_code_rcv <= 1'b0;
      
      stage <= 5'b0;
      
    end

    if (stage == 0) begin
      $display("Stage 0");

      out_mvfs[1][S] <= in_bfr[BITS - 1];
      out_mvfs[0][S] <= in_bfr[BITS - 1];

      s0_flushed_bits <= 32'b1;
      
      stage <= 5'b1;
    end

    if (stage == 1) begin
      


      
    end
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
  assign out_PMV_1_0_0 = out_PMV[1][0][0];
  assign out_PMV_1_0_1 = out_PMV[1][0][1];
  assign out_PMV_1_1_0 = out_PMV[1][1][0];
  assign out_PMV_1_1_1 = out_PMV[1][1][1];

  assign out_mvfs_0_0 = out_mvfs[0][0];
  assign out_mvfs_0_1 = out_mvfs[0][1];
  assign out_mvfs_1_0 = out_mvfs[1][0];
  assign out_mvfs_1_1 = out_mvfs[1][1];


  assign motion_code_inbuf = (in_bfr >> (BITS - 1 - s0_flushed_bits - 11));
  assign h_in_pred = in_PMV[0][S][0];
  assign v_in_pred = mvscale ? (in_PMV[0][S][1] >> 1) : in_PMV[0][S][1];

    
    
endmodule 

reg rst;
integer in_PMV[1:0][1:0][1:0];
integer in_mvfs[1:0][1:0];
integer dmv;
integer mvscale;
integer out_PMV[1:0][1:0][1:0];
integer out_mvfs[1:0][1:0];
reg done;

reg [16383:0] in_bfr;

initial begin
  in_mvfs[0][0] <= 32'd232;
  in_mvfs[0][1] <= 32'd200;
  in_mvfs[1][0] <= 32'd32;
  in_mvfs[1][1] <= 32'd240;

  in_bfr <= 16384'h006878304820a0c0c04038f8f85888e0c8d0b0486028b8a0202078a8402048b8d8f000d8c0407030a09828b02020f8c86818d8f080b048e8f0b8307830c040a8a080a0a0e8d06878e87808b878c840a0c8e040a8287850681000087890885090481880d8d81850104020c870809058187078206848b01810b83818c8989830308850f008d8c8f020a870303828c0e82030e8e8200058d018f0487860f888e0d008b8c0905830908870c060f0c8a0b8a01830d09880b8b89090a8f090a0a8303018c89078d0386048305850c8f8d0f828887020080850c02820e038c0c83838e8c8507808b8d8e850a88020d88868f8a8f808c0a8c038f0c0d0887830e070a850c060507878107830a8a8a0e080184818f8f098a0d038c0385880c08880d0702840c020b05038a8d018a8a8f8f088602038b808881000b028002068a03858e83800f0b8e85820b000d8f8b828105008d040e048284848905090788840b8a088103068e8686848d048c0b82838e848a05098e8f820e02800a8186070a0980820a068d02018f808f8907810c05898b0c8a098a060a8f010f8b018d8003850f860088020c06830d0f0b8805038c00070b0306038183818201860500040703018583898e0a0c0b848f88008086868c8308888d0905028886008d0a068a0504060b09008385858d07830f0f060f8c06880f81868484078f8c030c020509010506070b83850f8e80028f838c020c060f83088e05000c0806878d08000b0d808c0601028b860204850c06868880010a018683008189878804820b0706878102090a038f000e8b81810d0c8f0c8c8687018d080a8f840987840e080d078d810983090f05090e030a0c0f800807880a0e8a8d0707068b808c038b02860404868d898d85098b8d820382040f098f0a88808e8a88058488008c03078702090d0c0d810b0a8a0a858883808400050d868405058d04050c81878a0504838d8183848284800388838c84888584888f000b0b098c0f8e0f0480870e8c8781000283040482088689810f0b850009820b0807800a02840702850309060a8009848b8885898b830589860d8f0b8c888406870e800d0b08070f890f878700078f058585808f8500840d8f038389070d0904810a088d8b0703808a8684828b05828781828386828a0e8a0189090e87890706088b0088070b86078407000b85048b850904878c8a8201800904818f8189848800008e02048483070e810f0184020e878a8c89870089000787000709048a018d87080e09868882800109030f88830405898d0f81070e0b8a828a840f89068c8909810a8c0f0604888d8880020c070f0a0f8b81030e858a01068b0908818f0b8a008102038b090a8a838585868f8b860208058e0f02078d8880848506878982060e850e81850c8d0d8b8103828d8d08078101050c89068a0481888b020c07888501058d0a010e8281890d0201058c030b09818a0205018f050a098a080505828b8d09030c8c830709068e090e0c808e0f02098e8100850b828b8f84008e810585808788030f058406868f860f0c098d03898f08808d81870a8588850e088982818f8d8988860e040503838480818409018d0d8807860a8789870e88850486098d048d840787830e848b8b030e8c8b878487080f8a0a8d89850b0703098704028c8e850a038d8c0a8482840d020e0f01868e8f0a818f820509890a0707860f040a0f8f89830705880e8f0f0e8a8782098b068105098f0e080103020d80868f8b8d0d87850d080387028b810e0a898f83890a8e008a8508898306000b858c018108000b098286048c000208018f030f8b07810a8e04808c830b070e0a00898401010f0e040908050b828e8c870f81870b0808038289818b878684840c830e00038e820f0b8686820c0c8c8409848d8d85000500000a0782888f0207898d838701018087868c090b008106068a850c0e870703858b0f020b0f850b018e0c008b0a810e8f810106880e80020f07020b8b838e850901048f0d040b0f010881050c01848d83850d82090481840f800e0482088e8f04820588068100820c0e00898f8e000b0301068d8b018f0c850f8d080c84808988050785098e8c8a85810b0e82848d0e870f07050b0b010487820b8e05018b000d01038701078a018d88088c098f878a038c0e0008870700808b8a858a078a0f0a82028a858081018686830f888489080a0d858f078e848c0c8f8c030f068d02868108050e0e03838782818b010b818b0e0a810b86888c8a8d078c8e028d01070a0c0e04028e87818e8a85058906848c070007068e0e8a070d0b0d838e0e0a06838b0d8c018d0082838f80878b88028a838b8c0886048d80840483810b0901080b088d07810b8e0a0d89058d0c8906098c8e0d0f0780868b870a8c8704800c000287888702898389020e0f020c038c8108868c0c000000008e868f058c008a8d8d0b8e0f0489848a8b8b0d830905020b8d070a05858089090789830c8a87008a0d8f080688090f840a888f0a03888d85038c02040805020206058c89848a01080c8a09070107098388838d80818c090b0c830482848f07878a0509890d8e0982890a058b8b8c08000c84870d0f8980098082810a89840b05818e8882098e8d0c0f08800e8c808d868b840c00860b878d05010408888480870b8f878880838e8d0601040a8703020b8e0485880b848a8e0d8a0e840a83098409810c8a83890c04078a80880d8100868208060a0588860381080385810d0c81860f020e8c068a82800c028c860b80848d868e870f80808f8c0982000a8e850f8400818502060f0e830501090c81030582870e858a838a0e81080f83050c8a89848d8e048d098c000e03088a8601098;
end

motion_vector_top mvt(
                      //clock.val,
                      //rst,
                      //in_PMV,
                      //in_mvfs,
                      //dmv,
                      //mvscale,
                      //in_bfr,
                      //out_PMV,
                      //out_mvfs,
                      //done
                      //);
   .clk(clock.val), 
   .rst(rst),
   .in_PMV_0_0_0(in_PMV[0][0][0]),
   .in_PMV_0_0_1(in_PMV[0][0][1]),
   .in_PMV_0_1_0(in_PMV[0][1][0]),
   .in_PMV_0_1_1(in_PMV[0][1][1]),
   .in_PMV_1_0_0(in_PMV[1][0][0]),
   .in_PMV_1_0_1(in_PMV[1][0][1]),
   .in_PMV_1_1_0(in_PMV[1][1][0]),
   .in_PMV_1_1_1(in_PMV[1][1][1]),
   .in_mvfs_0_0(in_mvfs[0][0]),
   .in_mvfs_0_1(in_mvfs[0][1]),
   .in_mvfs_1_0(in_mvfs[1][0]),
   .in_mvfs_1_1(in_mvfs[1][1]), 
   .dmv(dmv), 
   .mvscale(mvscale),
   .in_bfr(in_bfr),
   .out_PMV_0_0_0(out_PMV[0][0][0]),
   .out_PMV_0_0_1(out_PMV[0][0][1]),
   .out_PMV_0_1_0(out_PMV[0][1][0]),
   .out_PMV_0_1_1(out_PMV[0][1][1]),
   .out_PMV_1_0_0(out_PMV[1][0][0]),
   .out_PMV_1_0_1(out_PMV[1][0][1]),
   .out_PMV_1_1_0(out_PMV[1][1][0]),
   .out_PMV_1_1_1(out_PMV[1][1][1]),
   .out_mvfs_0_0(out_mvfs[0][0]),
   .out_mvfs_0_1(out_mvfs[0][1]),
   .out_mvfs_1_0(out_mvfs[1][0]),
   .out_mvfs_1_1(out_mvfs[1][1]), 
   .done
);

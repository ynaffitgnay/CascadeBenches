module flushbuffer#(
  parameter BYTES = 2048
)(
  clk, 
  rst,
  N,
  in_valid,  
  in_bfr,
  loading_bfr,
  ld_bfr, 
  incnt,
  done
);
  localparam BITS = BYTES << 3;

  input wire clk;
  input wire rst;

  input wire [31:0] N;
  input wire in_valid;
  input wire[BITS - 1:0] in_bfr;

  output reg loading_bfr;
  output reg[31:0] ld_bfr;
  output reg signed [31:0] incnt;
  output reg done;

  
  integer bytes_read;

  wire [31:0] byte0, byte1, byte2, byte3;
  
 
  always @(posedge clk) begin
    $display("in_valid: %d, bytes_read: %d, lb: %h", in_valid, bytes_read, ld_bfr);
    //$display("%d, %d, %d, %d", byte0, byte1, byte2, byte3);
    //$display("inbfr: %h", in_bfr);


    if (rst) begin
      //$display("rst");
      ld_bfr <= 32'h4100000;
      incnt <= 32'b0;
      done <= 1'b0;

      bytes_read <= 32'b0;
      loading_bfr <= 1'b0;
    end
    else if (loading_bfr) begin
      if (incnt > 24) begin
      //  $display("Perhaps done loading");

        done <= 1'b1;
        loading_bfr <= 1'b0;
      end
      
      $display("incnt: %d", incnt);

      if (incnt <= 0) begin
        ld_bfr <= ld_bfr | (byte0 << ((24 - incnt) % 32)) | (byte1 << ((24 - (incnt + 8)) % 32)) | (byte2 << ((24 - (incnt + 16)) % 32)) | (byte3 << ((24 - (incnt + 24)) % 32));

        incnt <= incnt + 32;
        bytes_read <= bytes_read + 4;

      end
      else if (incnt <= 8) begin
        ld_bfr <= ld_bfr | (byte0 << ((24 - incnt) % 32)) | (byte1 << ((24 - (incnt + 8)) % 32)) | (byte2 << ((24 - (incnt + 16)) % 32));

        incnt <= incnt + 24;
        bytes_read <= bytes_read + 3;
      end
           else if (incnt <= 16) begin
             ld_bfr <= ld_bfr | (byte0 << ((24 - incnt) % 32)) | (byte1 << ((24 - (incnt + 8)) % 32));

             incnt <= incnt + 16;
             bytes_read <= bytes_read + 2;
           end

                else if (incnt <= 24) begin

                  ld_bfr <= ld_bfr | (byte0 << ((24 - incnt) % 32));

                  incnt <= incnt + 8;
                  bytes_read <= bytes_read + 1;                  
                end

    end
    else if (in_valid) begin // this should be last
      $display("starting new flush for N: %d", N);
      // TODO: figure out how to mark inCnt as invalid
      // also deal with clock cycle delay between assigning incnt and getting incnt...
      //$display("incnt: %d, (N mod 32): %d", incnt, N % 32);
      ld_bfr <= (ld_bfr << (N % 32));
      incnt <= incnt - N;
      loading_bfr <= 1'b1;      
      done <= 0;
    end

  end // always @ (posedge clk)
  assign byte0 = (in_bfr >> ((BYTES - bytes_read - 1) << 3)) & 32'hff;
  assign byte1 = (in_bfr >> ((BYTES - bytes_read - 2) << 3)) & 32'hff;
  assign byte2 = (in_bfr >> ((BYTES - bytes_read - 3) << 3)) & 32'hff;
  assign byte3 = (in_bfr >> ((BYTES - bytes_read - 4) << 3)) & 32'hff;

endmodule

/*
// INITIALIZE FLUSH_BUFFER WITH IN_INCNT AS 0.
// in_incnt should be a reg that gets set to out_incnt from top module whenever
// flushbuffer = done
module test_flush_buf(input wire clk);

  reg rst;
  reg [31:0] N;
  reg in_valid;
  reg [16383:0] in_bfr;
  reg loading_bfr;
  reg [31:0] out_ld_bfr;
  reg [31:0] out_incnt;
  reg done;

  reg [4:0] state;


  integer ctr;


  initial begin
    in_bfr = 16384'h006878304820a0c0c04038f8f85888e0c8d0b0486028b8a0202078a8402048b8d8f000d8c0407030a09828b02020f8c86818d8f080b048e8f0b8307830c040a8a080a0a0e8d06878e87808b878c840a0c8e040a8287850681000087890885090481880d8d81850104020c870809058187078206848b01810b83818c8989830308850f008d8c8f020a870303828c0e82030e8e8200058d018f0487860f888e0d008b8c0905830908870c060f0c8a0b8a01830d09880b8b89090a8f090a0a8303018c89078d0386048305850c8f8d0f828887020080850c02820e038c0c83838e8c8507808b8d8e850a88020d88868f8a8f808c0a8c038f0c0d0887830e070a850c060507878107830a8a8a0e080184818f8f098a0d038c0385880c08880d0702840c020b05038a8d018a8a8f8f088602038b808881000b028002068a03858e83800f0b8e85820b000d8f8b828105008d040e048284848905090788840b8a088103068e8686848d048c0b82838e848a05098e8f820e02800a8186070a0980820a068d02018f808f8907810c05898b0c8a098a060a8f010f8b018d8003850f860088020c06830d0f0b8805038c00070b0306038183818201860500040703018583898e0a0c0b848f88008086868c8308888d0905028886008d0a068a0504060b09008385858d07830f0f060f8c06880f81868484078f8c030c020509010506070b83850f8e80028f838c020c060f83088e05000c0806878d08000b0d808c0601028b860204850c06868880010a018683008189878804820b0706878102090a038f000e8b81810d0c8f0c8c8687018d080a8f840987840e080d078d810983090f05090e030a0c0f800807880a0e8a8d0707068b808c038b02860404868d898d85098b8d820382040f098f0a88808e8a88058488008c03078702090d0c0d810b0a8a0a858883808400050d868405058d04050c81878a0504838d8183848284800388838c84888584888f000b0b098c0f8e0f0480870e8c8781000283040482088689810f0b850009820b0807800a02840702850309060a8009848b8885898b830589860d8f0b8c888406870e800d0b08070f890f878700078f058585808f8500840d8f038389070d0904810a088d8b0703808a8684828b05828781828386828a0e8a0189090e87890706088b0088070b86078407000b85048b850904878c8a8201800904818f8189848800008e02048483070e810f0184020e878a8c89870089000787000709048a018d87080e09868882800109030f88830405898d0f81070e0b8a828a840f89068c8909810a8c0f0604888d8880020c070f0a0f8b81030e858a01068b0908818f0b8a008102038b090a8a838585868f8b860208058e0f02078d8880848506878982060e850e81850c8d0d8b8103828d8d08078101050c89068a0481888b020c07888501058d0a010e8281890d0201058c030b09818a0205018f050a098a080505828b8d09030c8c830709068e090e0c808e0f02098e8100850b828b8f84008e810585808788030f058406868f860f0c098d03898f08808d81870a8588850e088982818f8d8988860e040503838480818409018d0d8807860a8789870e88850486098d048d840787830e848b8b030e8c8b878487080f8a0a8d89850b0703098704028c8e850a038d8c0a8482840d020e0f01868e8f0a818f820509890a0707860f040a0f8f89830705880e8f0f0e8a8782098b068105098f0e080103020d80868f8b8d0d87850d080387028b810e0a898f83890a8e008a8508898306000b858c018108000b098286048c000208018f030f8b07810a8e04808c830b070e0a00898401010f0e040908050b828e8c870f81870b0808038289818b878684840c830e00038e820f0b8686820c0c8c8409848d8d85000500000a0782888f0207898d838701018087868c090b008106068a850c0e870703858b0f020b0f850b018e0c008b0a810e8f810106880e80020f07020b8b838e850901048f0d040b0f010881050c01848d83850d82090481840f800e0482088e8f04820588068100820c0e00898f8e000b0301068d8b018f0c850f8d080c84808988050785098e8c8a85810b0e82848d0e870f07050b0b010487820b8e05018b000d01038701078a018d88088c098f878a038c0e0008870700808b8a858a078a0f0a82028a858081018686830f888489080a0d858f078e848c0c8f8c030f068d02868108050e0e03838782818b010b818b0e0a810b86888c8a8d078c8e028d01070a0c0e04028e87818e8a85058906848c070007068e0e8a070d0b0d838e0e0a06838b0d8c018d0082838f80878b88028a838b8c0886048d80840483810b0901080b088d07810b8e0a0d89058d0c8906098c8e0d0f0780868b870a8c8704800c000287888702898389020e0f020c038c8108868c0c000000008e868f058c008a8d8d0b8e0f0489848a8b8b0d830905020b8d070a05858089090789830c8a87008a0d8f080688090f840a888f0a03888d85038c02040805020206058c89848a01080c8a09070107098388838d80818c090b0c830482848f07878a0509890d8e0982890a058b8b8c08000c84870d0f8980098082810a89840b05818e8882098e8d0c0f08800e8c808d868b840c00860b878d05010408888480870b8f878880838e8d0601040a8703020b8e0485880b848a8e0d8a0e840a83098409810c8a83890c04078a80880d8100868208060a0588860381080385810d0c81860f020e8c068a82800c028c860b80848d868e870f80808f8c0982000a8e850f8400818502060f0e830501090c81030582870e858a838a0e81080f83050c8a89848d8e048d098c000e03088a8601098;
    rst = 1'b1;
    ctr = 32'b0;
    in_valid = 0;
    state = 0;

  end

  always @(posedge clk) begin
    ctr <= ctr + 1;
    //$display("ctr: %d, loading_bfr: %d", ctr, loading_bfr);


    if (rst) begin 
      rst <= 1'b0;
      in_valid <= 1'b0;

    end


    if (ctr == 1) begin
      $display("Eventually I get here");

      in_valid <= 1'b1;
      //N <= 32'd5;
      N <= 32'b0;

      state <= 1;

    end


    else if (loading_bfr) begin
      //$display("loading_bfr: %d", loading_bfr);

      in_valid <= 1'b0;
      
    end

    if (ctr > 10) $finish(1);

  end


  flushbuffer fb(.clk(clk), 
                 .rst(rst), 
                 .N(N), 
                 .in_valid(in_valid), 
                 .in_bfr(in_bfr), 
                 .loading_bfr(loading_bfr), 
                 .ld_bfr(out_ld_bfr), 
                 .incnt(out_incnt), 
                 .done(done)
                 );


endmodule // test_flush_buf


test_flush_buf tfb(clock.val);
*/

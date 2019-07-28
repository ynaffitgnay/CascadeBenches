//---------------------------------------------------------------------------------------
//  Project:  ADPCM Encoder / Decoder 
// 
//  Filename:  tb_ima_adpcm.v      (April 26, 2010 )
// 
//  Author(s):  Moti Litochevski 
// 
//  Description:
//    This file implements the ADPCM encoder & decoder test bench. The input samples 
//    to be encoded are read from a binary input file. The encoder stream output and 
//    decoded samples are also compared with binary files generated by the Scilab 
//    simulation.
//
//---------------------------------------------------------------------------------------
//
//  To Do: 
//  - 
// 
//---------------------------------------------------------------------------------------
// 
//  Copyright (C) 2010 Moti Litochevski 
// 
//  This source file may be used and distributed without restriction provided that this 
//  copyright statement is not removed from the file and that any derivative work 
//  contains the original copyright notice and the associated disclaimer.
//
//  THIS SOURCE FILE IS PROVIDED "AS IS" AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES, 
//  INCLUDING, WITHOUT LIMITATION, THE IMPLIED WARRANTIES OF MERCHANTIBILITY AND 
//  FITNESS FOR A PARTICULAR PURPOSE. 
// 
//---------------------------------------------------------------------------------------
// Refactored to run on Cascade in April 2019 by Tiffany Yang

include ima_adpcm_enc.v;
include ima_adpcm_dec.v;

module test(clk);
  input wire clk;

  //---------------------------------------------------------------------------------------
  // internal signal  
  reg rst;        // global reset 
  reg [15:0] inSamp;    // encoder input sample 
  reg inValid;      // encoder input valid flag 
  wire inReady;      // encoder input ready indication 
  wire [3:0] encPcm;    // encoder encoded output value 
  wire encValid;      // encoder output valid flag
  wire decReady;     // decoder ready for input indication
  wire [15:0] decSamp;  // decoder output sample value 
  wire decValid;      // decoder output valid flag 
  integer sampCount, encCount, decCount;
  reg [7:0] intmp, enctmp, dectmp;
  reg [3:0] encExpVal;
  reg [15:0] decExpVal;
  reg [31:0] dispCount;

  reg inDone, encDone, decDone;

  reg[31:0] testCount;

  reg[7:0] inReg, decReg;

  // Variables to read file input into before copying to in-mem buffer
  reg[(BUFFER_BYTES << 3) - 1:0] inVal;
  reg[(BUFFER_BYTES << 3) - 1:0] encVal;
  reg[(BUFFER_BYTES << 3) - 1:0] decVal;

  reg[15:0] inIdx, encIdx, decIdx;

  // Buffers to hold file content
  reg[(BUFFER_BYTES << 3) - 1:0] inBuf [(TOTAL_IN_BYTES / BUFFER_BYTES) - 1:0];
  reg[(BUFFER_BYTES << 3) - 1:0] encBuf [(TOTAL_ENC_BYTES / BUFFER_BYTES) - 1:0];
  reg[(BUFFER_BYTES << 3) - 1:0] decBuf [(TOTAL_DEC_BYTES / BUFFER_BYTES) - 1:0];
  reg[31:0] inBytesRead, encBytesRead, decBytesRead;
 

  reg[3:0] mainState;
  reg[3:0] inState;
  reg[3:0] encState;
  reg[3:0] decState;

  reg[31:0] mCtr;
  reg[31:0] iCtr;
  reg[31:0] eCtr;
  reg[31:0] dCtr;

  parameter BUFFER_BYTES = 32;
  // CORRECT VALUES
  //parameter TOTAL_IN_BYTES = 348160;
  //parameter TOTAL_ENC_BYTES = 174080;
  //parameter TOTAL_DEC_BYTES = 348160;

  // Truncated for development
  parameter TOTAL_IN_BYTES = 10880;
  parameter TOTAL_ENC_BYTES = 5440;
  parameter TOTAL_DEC_BYTES = 10880;

  
 
  parameter MAIN0 = 0;
  parameter MAIN1 = 1;
  parameter MAIN2 = 2;

  parameter IN0 = 0;
  parameter IN1 = 1;
  parameter IN2 = 2;
  parameter IN3 = 3;
  parameter IN4 = 4;
  parameter IN5 = 5;

  parameter ENC0 = 0;
  parameter ENC1 = 1;
  parameter ENC2 = 2;
  parameter ENC3 = 3;
  parameter ENC4 = 4;
  
  parameter DEC0 = 0;
  parameter DEC1 = 1;
  parameter DEC2 = 2;
  parameter DEC3 = 3;
  parameter DEC4 = 4;

  parameter TESTS_TO_RUN = 1;
  
  
  // NOTE: Cascade does not like input files to be outside of
  // the Cascade home directory. Make sure to copy these into
  // the home directory (at least until the path gets fixed)
  stream instream = $fopen("test_in.bin");
  stream encstream = $fopen("test_enc.bin");
  stream decstream = $fopen("test_dec.bin");
  
  initial begin
    $display("Initializing");

    testCount = 0;

    mCtr = 0;
    mainState = 0;

    iCtr = 0;
    inState = 0;

    eCtr = 0;
    encState = 0;

    dCtr = 0;
    decState = 0;

    // Fill the input buffer
    for (inIdx = 0; inIdx < (TOTAL_IN_BYTES / BUFFER_BYTES); inIdx = inIdx + 1) begin
      if (!($eof(instream))) $get(instream, inVal);
      //$display("i: %d", inIdx);
    
      inBuf[inIdx] <= inVal;
    end

    for (encIdx = 0; encIdx < (TOTAL_ENC_BYTES / BUFFER_BYTES); encIdx = encIdx + 1) begin
      if (!($eof(encstream))) $get(encstream, encVal);
      //$display("e: %d", encIdx);
    
      encBuf[encIdx] <= encVal;
    end

    for (decIdx = 0; decIdx < (TOTAL_DEC_BYTES / BUFFER_BYTES); decIdx = decIdx + 1) begin
      if (!($eof(decstream))) $get(decstream, decVal);
      //$display("d: %d", decIdx);
    
      decBuf[decIdx] <= decVal;
    end
    

    $display("Done initializing");

  end

  //---------------------------------------------------------------------------------------
  // test bench implementation 
  // global signals generation
  always @(posedge clk) begin
    mCtr <= mCtr + 1;

    //$display("intmp: %h, enctmp: %h, dectmp: %h", intmp, enctmp, dectmp);


    if (testCount >= TESTS_TO_RUN) $finish(1);

    case (mainState)
      MAIN0: begin
        rst <= 1;

        inDone <= 0;
        encDone <= 0;
        decDone <= 0;

        if (mCtr >= 2) begin
          $display("");
          $display("IMA ADPCM encoder & decoder simulation");
          $display("--------------------------------------");
          mCtr <= 0;
          mainState <= MAIN1;
        end
      end

      MAIN1: begin
        //$display("In MAIN1 (should only display once)");

        rst <= 0;
        
        mCtr <= 0;
        mainState <= MAIN2;
      end // case: MAIN1

      MAIN2: begin
        if (inDone && encDone && decDone) begin
          $display("Test %d done!. Count: %d", testCount , mCtr);

          testCount <= testCount + 1;
          mCtr <= 0;
          mainState <= MAIN0;
        end
      end
         
    endcase // case (mainState)        
  end 

  //------------------------------------------------------------------
  // encoder input samples read process 
  always @(posedge clk) begin
    iCtr <= iCtr + 1;
    if (rst) inState <= IN1;

    case (inState)
      IN0: begin
        //@(posedge clk);
        iCtr <= 0;
      end

      IN1: begin
        // clear encoder input signal 
        inSamp <= 16'b0;
        inValid <= 1'b0;
        // clear samples counter 
        sampCount <= 0;
        inBytesRead <= 0;

        // binary input file 
        //if (iCtr == 0) $seek(instream, 0);
        inIdx <= 0;

        if (!rst) begin
          iCtr <= 0;
          inState <= IN2;
        end
      end // case: IN1
      
      // wait for reset release
      //while (rst) @(posedge clock);
      //repeat (50) @(posedge clock);  // 50 cycles

      IN2: begin
        if (iCtr >= 50) begin
          $display("Getting input byte");

          // read input samples file 
          //$get(instream, inBuf);
          //intmp = $fgetc(instream);

          intmp <= inBuf[inIdx][(BUFFER_BYTES << 3) - 1:(BUFFER_BYTES << 3) - 8];
          inBytesRead <= inBytesRead + 1;

          $display("inBuf[%d] = %h%h%h%h%h%h%h%h", inIdx, 
                   inBuf[inIdx][255:224],
                   inBuf[inIdx][223:192],
                   inBuf[inIdx][191:160],
                   inBuf[inIdx][159:128],
                   inBuf[inIdx][127:96],
                   inBuf[inIdx][95:64],
                   inBuf[inIdx][63:32],
                   inBuf[inIdx][31:0]);


          iCtr <= 0;
          inState <= IN3;
        end
      end // case: IN2

      IN3: begin
        //while (intmp != `EOF)
        //begin

        // Stop looping through inputs if eof

        // TODO: NEED TO FIX BHVR OF EOF. REPLACE WITH BYTES_READ
        //if ($eof(instream)) begin
        if (inBytesRead >= TOTAL_IN_BYTES) begin
          $display("Reached eof");

          iCtr <= 0;
          inState <= IN5;
        end

        else begin
          if (iCtr == 0) begin
            // read the next character to form the new input sample 
            // Note that first byte is used as the low byte of the sample 
            inSamp[7:0] <= intmp;
            //bytes_read <= bytes_read + 1;
            //$display("bytes_read: %d", bytes_read);

            
            //inSamp[15:8] <= $fgetc(instream);
            //$get(instream, inReg);

            case (inBytesRead % BUFFER_BYTES)
              1:  inSamp[15:8] <= inBuf[inIdx][247:240];
              3:  inSamp[15:8] <= inBuf[inIdx][231:224];
              5:  inSamp[15:8] <= inBuf[inIdx][215:208];
              7:  inSamp[15:8] <= inBuf[inIdx][199:192];
              9:  inSamp[15:8] <= inBuf[inIdx][183:176];
              11: inSamp[15:8] <= inBuf[inIdx][167:160];
              13: inSamp[15:8] <= inBuf[inIdx][151:144];
              15: inSamp[15:8] <= inBuf[inIdx][135:128];
              17: inSamp[15:8] <= inBuf[inIdx][119:112];
              19: inSamp[15:8] <= inBuf[inIdx][103:96];
              21: inSamp[15:8] <= inBuf[inIdx][87:80];
              23: inSamp[15:8] <= inBuf[inIdx][71:64];
              25: inSamp[15:8] <= inBuf[inIdx][55:48];
              27: inSamp[15:8] <= inBuf[inIdx][39:32];
              29: inSamp[15:8] <= inBuf[inIdx][23:16];
              31: inSamp[15:8] <= inBuf[inIdx][7:0];
              default: $display("Unexpected number of bytes read for inSamp");

            endcase // case (inBytesRead % BUFFER_BYTES)

            inBytesRead <= inBytesRead + 1;
          end // if (iCtr == 0)

          if (iCtr == 1) begin
            // sign input sample is valid (should be able to do this at iCtr = 0)
            inValid <= 1'b1;

            $display("inBytesRead: %d", inBytesRead);

            if ((inBytesRead % BUFFER_BYTES) == 0) begin
              $display("Reading more bytes");

              inIdx <= inIdx + 1;
              //if (!($eof(instream))) $get(instream, inBuf);

              $display("inBuf[%d] = %h%h%h%h%h%h%h%h", inIdx, 
                   inBuf[inIdx][255:224],
                   inBuf[inIdx][223:192],
                   inBuf[inIdx][191:160],
                   inBuf[inIdx][159:128],
                   inBuf[inIdx][127:96],
                   inBuf[inIdx][95:64],
                   inBuf[inIdx][63:32],
                   inBuf[inIdx][31:0]);
            end // if ((inBytesRead % BUFFER_BYTES) == 0)

            // Transition to next state
            iCtr <= 0;
            inState <= IN4;
          end // if (iCtr == 1)

          // @(posedge clock);
          if (iCtr >= 1) begin
            
          end
        end // else: !if($eof(instream))

      end // case: IN3


      IN4: begin
        // update the sample counter 
        if (iCtr == 0) begin 
          sampCount <= sampCount + 1;
          //inByteInc <= 0;
          $display("Sample count: %d", sampCount);

        end


        // wait for encoder input ready assertion to confirm the new sample was read
        // by the encoder.
        //while (!inReady)
        //  @(posedge clock);

        if (inReady) begin
          // read next character from the input file 
          //intmp = $fgetc(instream);
          //$display("outvalid: %d", encValid);

          //$get(instream, intmp);
          
          case (inBytesRead % BUFFER_BYTES)
            0:  intmp <= inBuf[inIdx][255:248];
            2:  intmp <= inBuf[inIdx][239:232];
            4:  intmp <= inBuf[inIdx][223:216];
            6:  intmp <= inBuf[inIdx][207:200];
            8:  intmp <= inBuf[inIdx][191:184];
            10: intmp <= inBuf[inIdx][175:168];
            12: intmp <= inBuf[inIdx][159:152];
            14: intmp <= inBuf[inIdx][143:136];
            16: intmp <= inBuf[inIdx][127:120];
            18: intmp <= inBuf[inIdx][111:104];
            20: intmp <= inBuf[inIdx][95:88];
            22: intmp <= inBuf[inIdx][79:72];
            24: intmp <= inBuf[inIdx][63:56];
            26: intmp <= inBuf[inIdx][47:40];
            28: intmp <= inBuf[inIdx][31:24];
            30: intmp <= inBuf[inIdx][15:8];
            default: $display("Unexpected value");

          endcase // case (inBytesRead % BUFFER_BYTES)



          inBytesRead <= (sampCount << 1) + 1;
          $display("inbytesread; %d", inBytesRead);

          //if (!inByteInc) begin
          //  inBytesRead <= inBytesRead + 1;
          //  inByteInc <= 1;
          //end
          

          iCtr <= 0;
          inState <= IN3;
        end

      end // case: IN4

      IN5: begin
        // sign input is not valid 
        inValid <= 1'b0;
        //@(posedge clock);

        if (iCtr >= 1) begin
          //$display("Closing input file");
          // close input file 
          //$fclose(instream);

          inDone <= 1;

          iCtr <= 0;
          inState <= IN0;
        end
      end // case: IN5
      
      default: inState <= IN0;
    endcase // case (inState)

  end // always @ (posedge clk)


  // encoder output checker - the encoder output is compared to the value read from 
  // the ADPCM coded samples file. 
  //initial 
  //begin
  always @(posedge clk) begin
    eCtr <= eCtr + 1;
    if (rst) encState <= ENC1;

    case(encState)
      ENC0: begin
        eCtr <= 0;
      end

      ENC1: begin
        // clear encoded sample value 
        encCount <= 0;
        encBytesRead <= 0;
        
        // open input file 
        //encstream = $fopen(`ENC_FILE, "rb");
        //if (eCtr == 0) $seek(encstream, 0);
        encIdx <= 0;

        if (!rst) begin
          $display("getting first enc byte");

          //$get(encstream, enctmp);
          enctmp <= encBuf[encIdx][(BUFFER_BYTES << 3) - 1:(BUFFER_BYTES << 3) - 8];
          encBytesRead <= encBytesRead + 1;

          $display("encBuf[%d] = %h%h%h%h%h%h%h%h", encIdx, 
                   encBuf[encIdx][255:224],
                   encBuf[encIdx][223:192],
                   encBuf[encIdx][191:160],
                   encBuf[encIdx][159:128],
                   encBuf[encIdx][127:96],
                   encBuf[encIdx][95:64],
                   encBuf[encIdx][63:32],
                   encBuf[encIdx][31:0]);


          eCtr <= 0;
          encState <= ENC2;
        end
      end // case: ENC1
      

      // wait for reset release
      //while (rst) @(posedge clock);
    
      // encoder output compare loop 
      //enctmp = $fgetc(encstream);
      ENC2: begin
        //if ($eof(encstream)) begin
        if (encBytesRead >= TOTAL_ENC_BYTES) begin
          $display("Reached eof of encryption file");
          eCtr <= 0;
          encState <= ENC4;
        end

        else begin
          //while (enctmp != `EOF)  // can put this into a state machine
          //begin 
          // assign the expected value to a register with the same width 
          encExpVal <= enctmp;
          
          // wait for encoder output valid 
          //while (!encValid)
          //  @(posedge clock);
          if (encValid) begin
            eCtr <= 0;
            encState <= ENC3;
          end
        end // else: !if($eof(encstream))
        
      end // case: ENC2  

      ENC3: begin
        // compare the encoded value with the value read from the input file 
        if (encPcm != encExpVal) begin 
          // announce error detection and exit simulation
          if (eCtr == 0) begin
            $display(" Error!");
            $display("Error found in encoder output index %d.", encCount+1);
            $display("   (expected value 'h%h, got value 'h%h)", encExpVal, encPcm);
          end

          // wait for a few clock cycles before ending simulation 
          //repeat (20) @(posedge clock);
          if (eCtr >= 20) $finish();
        end // if (encPcm != encExpVal)

        else begin
          $display("encoder output correct. expected %h, got %h", encExpVal, encPcm);
          // update the encoded sample counter 
          if (eCtr == 0) encCount <= encCount + 1;
          // delay for a clock cycle after comparison 
          //@(posedge clock);

          if (eCtr == 1) begin
            // read next char from input file 
            //enctmp = $fgetc(encstream);

            
            case (encBytesRead % BUFFER_BYTES)
              0:  enctmp <= encBuf[encIdx][255:248];
              1:  enctmp <= encBuf[encIdx][247:240];
              2:  enctmp <= encBuf[encIdx][239:232];
              3:  enctmp <= encBuf[encIdx][231:224];
              4:  enctmp <= encBuf[encIdx][223:216];
              5:  enctmp <= encBuf[encIdx][215:208];
              6:  enctmp <= encBuf[encIdx][207:200];
              7:  enctmp <= encBuf[encIdx][199:192];
              8:  enctmp <= encBuf[encIdx][191:184];
              9:  enctmp <= encBuf[encIdx][183:176];
              10: enctmp <= encBuf[encIdx][175:168];
              11: enctmp <= encBuf[encIdx][167:160];
              12: enctmp <= encBuf[encIdx][159:152];
              13: enctmp <= encBuf[encIdx][151:144];
              14: enctmp <= encBuf[encIdx][143:136];
              15: enctmp <= encBuf[encIdx][135:128];
              16: enctmp <= encBuf[encIdx][127:120];
              17: enctmp <= encBuf[encIdx][119:112];
              18: enctmp <= encBuf[encIdx][111:104];
              19: enctmp <= encBuf[encIdx][103:96];
              20: enctmp <= encBuf[encIdx][95:88];
              21: enctmp <= encBuf[encIdx][87:80];
              22: enctmp <= encBuf[encIdx][79:72];
              23: enctmp <= encBuf[encIdx][71:64];
              24: enctmp <= encBuf[encIdx][63:56];
              25: enctmp <= encBuf[encIdx][55:48];
              26: enctmp <= encBuf[encIdx][47:40];
              27: enctmp <= encBuf[encIdx][39:32];
              28: enctmp <= encBuf[encIdx][31:24];
              29: enctmp <= encBuf[encIdx][23:16];
              30: enctmp <= encBuf[encIdx][15:8];
              31: enctmp <= encBuf[encIdx][7:0];
              default: $display("Unexpected value when filling in enctmp");

            endcase // case (encBytesRead % BUFFER_BYTES)
            //$get(encstream, enctmp);

            encBytesRead <= encBytesRead + 1;
          end // if (eCtr == 1)

          if (eCtr == 2) begin
            $display("encBytesRead: %d", encBytesRead);


            if ((encBytesRead % BUFFER_BYTES) == 0) begin
              $display("Reading more enc bytes\n");
              encIdx <= encIdx + 1;

              $display("encBuf[%d] = %h%h%h%h%h%h%h%h", encIdx, 
                   encBuf[encIdx][255:224],
                   encBuf[encIdx][223:192],
                   encBuf[encIdx][191:160],
                   encBuf[encIdx][159:128],
                   encBuf[encIdx][127:96],
                   encBuf[encIdx][95:64],
                   encBuf[encIdx][63:32],
                   encBuf[encIdx][31:0]);
            end // if ((encBytesRead % BUFFER_BYTES) == 0)
            
            eCtr <= 0;
            encState <= ENC2;

          end // if (eCtr == 2)
        end // else: !if(encPcm != encExpVal)
      end // case: ENC3

      ENC4: begin
        if (iCtr >= 1) begin
          //$display("Would close input file here");
          // close input file 
          
          encDone <= 1;

          eCtr <= 0;
          encState <= ENC0;

        end
      end

      default: encState <= ENC0;

    endcase // case (encState)
   
  end // always @ (posedge clk)


  // decoder output checker - the decoder output is compared to the value read from 
  // the ADPCM decoded samples file. 
  //initial 
  //begin
  always @(posedge clk) begin
    dCtr <= dCtr + 1;
    if (rst) decState <= DEC1;

    case (decState)
      DEC0: begin
        dCtr <= 0;
      end

      DEC1: begin        
        // clear decoded sample value 
        decCount <= 0;
        dispCount <= 0;

        decBytesRead <= 0;

        // open input file 
        //decstream = $fopen(`DEC_FILE, "rb");
        //if (dCtr == 0) $seek(decstream, 0);
        decIdx <= 0;

        
        // wait for reset release
        //while (rst) @(posedge clock);

        if (!rst) begin
          $display("Grabbing first dec byte");
          // decoder output compare loop
          
          //dectmp = $fgetc(decstream);
          //$get(decstream, dectmp);

          dectmp <= decBuf[decIdx][(BUFFER_BYTES << 3) - 1:(BUFFER_BYTES << 3) - 8];
          decBytesRead <= decBytesRead + 1;

                   $display("decBuf[%d] = %h%h%h%h%h%h%h%h", decIdx, 
                   decBuf[decIdx][255:224],
                   decBuf[decIdx][223:192],
                   decBuf[decIdx][191:160],
                   decBuf[decIdx][159:128],
                   decBuf[decIdx][127:96],
                   decBuf[decIdx][95:64],
                   decBuf[decIdx][63:32],
                   decBuf[decIdx][31:0]);


          dCtr <= 0;
          decState <= DEC2;
        end
      end // case: DEC1

      DEC2: begin
        // display simulation progress bar title 
        //$write("Simulation progress: ");
        //if ($eof(decstream)) begin
        if (decBytesRead >= TOTAL_DEC_BYTES) begin
          $display("Reached eof of dec file");
          dCtr <= 0;
          decState <= DEC4;
        end

        else begin    
          //while (dectmp != `EOF)
          //begin 
          // read the next char to form the expected 16 bit sample value
          
          if (dCtr == 0) begin  
            decExpVal[7:0] <= dectmp;

            //$get(decstream, decReg);
            //decExpVal[15:8] <= $fgetc(decstream);


            case (decBytesRead % BUFFER_BYTES)
              1:  decExpVal[15:8] <= decBuf[decIdx][247:240];
              3:  decExpVal[15:8] <= decBuf[decIdx][231:224];
              5:  decExpVal[15:8] <= decBuf[decIdx][215:208];
              7:  decExpVal[15:8] <= decBuf[decIdx][199:192];
              9:  decExpVal[15:8] <= decBuf[decIdx][183:176];
              11: decExpVal[15:8] <= decBuf[decIdx][167:160];
              13: decExpVal[15:8] <= decBuf[decIdx][151:144];
              15: decExpVal[15:8] <= decBuf[decIdx][135:128];
              17: decExpVal[15:8] <= decBuf[decIdx][119:112];
              19: decExpVal[15:8] <= decBuf[decIdx][103:96];
              21: decExpVal[15:8] <= decBuf[decIdx][87:80];
              23: decExpVal[15:8] <= decBuf[decIdx][71:64];
              25: decExpVal[15:8] <= decBuf[decIdx][55:48];
              27: decExpVal[15:8] <= decBuf[decIdx][39:32];
              29: decExpVal[15:8] <= decBuf[decIdx][23:16];
              31: decExpVal[15:8] <= decBuf[decIdx][7:0];
              default: $display("Unexpected number of bytes read for decExpVal");

            endcase // case (inBytesRead % BUFFER_BYTES)

            decBytesRead <= decBytesRead + 1;
            $display("decBytesRead: %d", decBytesRead);
           
          end // if (dCtr == 0)

          if (dCtr == 1) begin
            if ((decBytesRead % BUFFER_BYTES) == 0) begin
              $display("Reading more dec bytes");
              decIdx <= decIdx + 1;

              
                   $display("decBuf[%d] = %h%h%h%h%h%h%h%h", decIdx, 
                   decBuf[decIdx][255:224],
                   decBuf[decIdx][223:192],
                   decBuf[decIdx][191:160],
                   decBuf[decIdx][159:128],
                   decBuf[decIdx][127:96],
                   decBuf[decIdx][95:64],
                   decBuf[decIdx][63:32],
                   decBuf[decIdx][31:0]);

              
            end

          end

          // wait for decoder output valid 
          //while (!decValid)
          //  @(posedge clock);
          
          if (decValid && (dCtr >= 1)) begin
            dCtr <= 0;
            decState <= DEC3;
          end
        end // else: !if($eof(decstream))

      end // case: DEC2

      DEC3: begin        
        // compare the decoded value with the value read from the input file 
        if (decSamp != decExpVal) begin
          if (dCtr == 0) begin
            // announce error detection and exit simulation 
            $display(" Error!");
            $display("Error found in decoder output index %d.", decCount+1);
            $display("   (expected value 'h%h, got value 'h%h)", decExpVal, decSamp);
          end

          // wait for a few clock cycles before ending simulation 
          //repeat (20) @(posedge clock);
          //$finish
          if (dCtr >= 20) $finish();

        end // if (decSamp != decExpVal)
        
        else begin
          $display("Dec correct! expected: %h, got: %h", decExpVal, decSamp);

          // delay for a clock cycle after comparison 
          //@(posedge clock);
          // update the decoded sample counter 
          if (dCtr == 1) begin
            decCount <= decCount + 1;

            //
            //// check if simulation progress should be displayed
            //if (dispCount[31:13] != (decCount >> 13))
            //  $write(".");
            // update the display counter 
            //dispCount = decCount;
            
            // read next char from input file 
            //dectmp = $fgetc(decstream);
            //$get(decstream, dectmp);

            case (decBytesRead % BUFFER_BYTES)
              0:  dectmp <= decBuf[decIdx][255:248];
              2:  dectmp <= decBuf[decIdx][239:232];
              4:  dectmp <= decBuf[decIdx][223:216];
              6:  dectmp <= decBuf[decIdx][207:200];
              8:  dectmp <= decBuf[decIdx][191:184];
              10: dectmp <= decBuf[decIdx][175:168];
              12: dectmp <= decBuf[decIdx][159:152];
              14: dectmp <= decBuf[decIdx][143:136];
              16: dectmp <= decBuf[decIdx][127:120];
              18: dectmp <= decBuf[decIdx][111:104];
              20: dectmp <= decBuf[decIdx][95:88];
              22: dectmp <= decBuf[decIdx][79:72];
              24: dectmp <= decBuf[decIdx][63:56];
              26: dectmp <= decBuf[decIdx][47:40];
              28: dectmp <= decBuf[decIdx][31:24];
              30: dectmp <= decBuf[decIdx][15:8];
              default: $display("Unexpected value");

            endcase // case (inBytesRead % BUFFER_BYTES)


            decBytesRead <= decBytesRead + 1;

          end // if (dCtr == 1)

          if (dCtr == 2) begin
            $display("decbytesread; %d", decBytesRead);

            dCtr <= 0;
            decState <= DEC2;
          end // if (dCtr >= 1)
        end // else: !if(decSamp != decExpVal)
      end // case: DEC3

      DEC4: begin
        //$display("Would close decfile here");
        // close input file 
        //$fclose(decstream);

        // when decoder output is done announce simulation was successful 
        $display(" Done");
        $display("Simulation ended successfully after %0d samples", decCount);
        //$finish;
        decDone <= 1;

        dCtr <= 0;
        decState <= 0;
      end // case: DEC4

      default: decState <= DEC0;

    endcase // case (decState)
  end // always @ (posedge clk)

      
    
/* */
  //------------------------------------------------------------------
  // device under test 
  // Encoder instance 
  ima_adpcm_enc enc
    (
     .clock(clk), 
     .reset(rst), 
     .inSamp(inSamp), 
     .inValid(inValid),
     .inReady(inReady),
     .outPCM(encPcm), 
     .outValid(encValid), 
     .outPredictSamp(/* not used */), 
     .outStepIndex(/* not used */) 
     );

  // Decoder instance 
  ima_adpcm_dec dec 
    (
     .clock(clk), 
     .reset(rst), 
     .inPCM(encPcm), 
     .inValid(encValid),
     .inReady(decReady),
     .inPredictSamp(16'b0), 
     .inStepIndex(7'b0), 
     .inStateLoad(1'b0), 
     .outSamp(decSamp), 
     .outValid(decValid) 
     );

endmodule

test t(clock.val);

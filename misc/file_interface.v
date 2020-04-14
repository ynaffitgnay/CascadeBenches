//`timescale 1ns/1ps
module file_mem (
  input  wire                         clk,
  input  wire                         reset,
  input  wire                         offset
  //input  wire  [ADDR_WIDTH-1:0]       address,
  //input  wire                         enable,
  //output reg   [DATA_WIDTH-1:0]       data_out
);

// ******************************************************************
// Variables for cascade file interface
// ******************************************************************
integer lutstream = $fopen("nonexistent_file.txt");
integer outstream = $fopen("other_file.txt");
integer instream = $fopen("other_file.txt", "r");
integer i = 0;
reg[3:0] val = 0;


// ******************************************************************
// Initialization
// ******************************************************************

    initial begin
        ctr = 0;
        for (i = 0; i < 5; i = i + 1) begin
            if (!($feof(lutstream))) begin
                $fscanf(lutstream, "%b", val);
                $fflush(lutstream);
                //mem[i] = val;
                $display("not eof");
            end 
            else begin
                $display("eof");
                //mem[i] = 0;
                val = 1;

                /* THIS DOESN'T APPEAR TO DO ANYTHING... */                
                $fwrite(lutstream, "%d", val);
                $fflush(lutstream);
            end // else: !if(!($feof(lutstream)))
            $display("val: %d", val);
        end // for (i = 0; i < ROM_DEPTH; i = i + 1)
    end // initial begin


// ******************************************************************
// Main logic
// ******************************************************************

    // Counter
    integer ctr;
    integer inval;
    integer inval2;


    always @(posedge clk) begin
        ctr <= ctr + 1;
        if (ctr > 20) begin
            $finish(1);
        end
    end


    always @ (posedge clk) begin
        if (ctr <= 5) begin
            $fwrite(lutstream, "ctr: %d ", ctr);
            $fflush(lutstream);
            /* Doing this in the same clock cycle doesn't seem to work */
            //$fread(lutstream, inval2);
            //$display("ctr: %d, inval2: %d", ctr, inval2);
        end else begin
            $fseek(lutstream, 100, 0);  // 0 seems to be the correct direction...
            $fwrite(lutstream, "ctr: %d ", ctr);
            $fflush(lutstream);
            /* Doing this in the same clock cycle doesn't seem to work */
            //$fseek(lutstream, 100, 0);  // 0 seems to be the correct direction...
            //$fread(lutstream, inval2);
            //$display("ctr: %d, inval2: %d", ctr, inval2);
        end            
    end


    always @ (posedge clk) begin
        //if (ctr < 5) begin
        //end else 
        if (ctr <= 10) begin
            $fwrite(outstream, "%h ", ctr);
            $fflush(outstream);
        end else begin
            $fseek(outstream, 200, 0);  // 0 seems to be the correct direction...
            $fwrite(outstream, "%h ", ctr);
            $fflush(outstream);
        end            
    end // always @ (posedge clk)

    always @ (posedge clk) begin
        //if (ctr < 5) begin
        //end else 
        if (ctr <= 10) begin
            $fread(instream, inval);
            $display("ctr: %d, inval: %d", ctr, inval);
        end else begin
            $fseek(instream, 200, 0);  // 0 seems to be the correct direction...
            $fread(instream, inval);
            $display("ctr: %d, inval: %d", ctr, inval);
        end            
    end



  //always @ (posedge clk)
  //begin : READ_BLK
  //  if(!reset) begin
  //    if (enable)
  //      data_out <= mem[address];
  //    else
  //      data_out <= data_out;
  //  end else begin
  //    data_out <= 0;
  //  end
  //end


endmodule

reg r;
reg [31:0] offset;

initial offset <= 32'hffff;


file_mem tr(clock.val, offset, r);

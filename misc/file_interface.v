//`timescale 1ns/1ps
module file_mem (
  input  wire                         clk,
  input  wire                         reset
  //input  wire  [ADDR_WIDTH-1:0]       address,
  //input  wire                         enable,
  //output reg   [DATA_WIDTH-1:0]       data_out
);

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

// ******************************************************************
// Variables for cascade file interface
// ******************************************************************
integer lutstream = $fopen("nonexistent_file.txt"); 
integer i = 0;
reg[3:0] val = 0;


// ******************************************************************
// Initialization
// ******************************************************************

    initial begin
        for (i = 0; i < 5; i = i + 1) begin
            if (!($feof(lutstream))) begin
                $fscanf(lutstream, "%b", val);
                //mem[i] = val;
                $display("not eof");
            end 
            else begin
                $display("eof");
                //mem[i] = 0;
                $fwrite(lutstream, "%b", 0001);
            end // else: !if(!($feof(lutstream)))
            $display("val: %d", val);
        end // for (i = 0; i < ROM_DEPTH; i = i + 1)
    end // initial begin
  

endmodule

reg r;
file_mem tr(clock.val, r);

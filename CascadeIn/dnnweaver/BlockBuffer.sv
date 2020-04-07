`include "common.vh"
`include "AMITypes.sv"
`include "SoftFIFO.sv"
`include "FIFO.sv"

//import ShellTypes::*;
//import AMITypes::*;

module BlockSector
#(
    parameter integer WIDTH = 64
)
(
    input            clk,
    input            rst,
    input[WIDTH-1:0] wrInput,
    input[WIDTH-1:0] rdInput,
    input            inMuxSel,
    input            sector_we,
    output wire[WIDTH-1:0] dataout
);

    reg[WIDTH-1:0]  data_reg;
    wire[WIDTH-1:0] new_data;
    
    always@(posedge clk) begin
        if (rst) begin
            data_reg <= 0;
        end else begin
            if (sector_we) begin
                data_reg <= new_data;
            end else begin
                data_reg <= data_reg;
            end            
        end
    end

    assign dataout  = data_reg;
    assign new_data = (inMuxSel == 1'b1) ? wrInput : rdInput;
    
endmodule

module we_decoder(
    input we_all,
    input we_specific,
    input[2:0]  index,
    output reg[7:0] we_out
);

    always @(*) begin
        we_out =  8'b0000_0000;
        if (we_all) begin
            we_out = 8'b1111_1111;
        end else begin
            if (we_specific) begin
                we_out[index] = 1'b1;
            end
        end
    end
    
endmodule

module block_rotate
#(
    parameter integer WIDTH = 64,
    parameter integer NUM_SECTORS = 8
)
(
    input[2:0] rotate_amount,
    input [((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? (NUM_SECTORS * WIDTH) + -1 : (NUM_SECTORS * (2 - WIDTH)) + ((WIDTH - 1) - 1)) : ((WIDTH - 1) >= 0 ? ((2 - NUM_SECTORS) * WIDTH) + (((NUM_SECTORS - 1) * WIDTH) - 1) : ((2 - NUM_SECTORS) * (2 - WIDTH)) + (((WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))) - 1))):((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) : ((WIDTH - 1) >= 0 ? (NUM_SECTORS - 1) * WIDTH : (WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))))] inData,
	  output reg [((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? (NUM_SECTORS * WIDTH) + -1 : (NUM_SECTORS * (2 - WIDTH)) + ((WIDTH - 1) - 1)) : ((WIDTH - 1) >= 0 ? ((2 - NUM_SECTORS) * WIDTH) + (((NUM_SECTORS - 1) * WIDTH) - 1) : ((2 - NUM_SECTORS) * (2 - WIDTH)) + (((WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))) - 1))):((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) : ((WIDTH - 1) >= 0 ? (NUM_SECTORS - 1) * WIDTH : (WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))))] outData
    //input[WIDTH-1:0]  inData[NUM_SECTORS-1:0],
    //output reg[WIDTH-1:0] outData[NUM_SECTORS-1:0]
);

    always @(*) begin
        outData = inData;
        if (rotate_amount == 0) begin
            outData = inData;
        end else if (rotate_amount == 1) begin 
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
      			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 2) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 3) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 4) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 5) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 6) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end else if (rotate_amount == 7) begin
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
            outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
        end
    end // always @ (*)
endmodule

module BlockBuffer
(
    // General signals
    input               clk,
    input               rst,
    input               flush_buffer,
    // Interface to App
    input  [`AMI_REQUEST_BUS_WIDTH - 1:0]   reqIn,
    output wire         reqIn_grant,
    output [`AMI_RESPONSE_BUS_WIDTH - 1:0]  respOut,
    input               respOut_grant,
    // Interface to Memory system, 2 ports enables simulatentous eviction and request of a new block
    output reg [`AMI_REQUEST_BUS_WIDTH - 1:0]   reqOut0, // port 0 is the rd port, port 1 is the wr port
    input               reqOut0_grant,
    output reg [`AMI_REQUEST_BUS_WIDTH - 1:0]   reqOut1, // port 0 is the rd port, port 1 is the wr port
    input               reqOut1_grant,
    input  [`AMI_RESPONSE_BUS_WIDTH - 1:0]  respIn0,
    output reg          respIn0_grant,
    input  [`AMI_RESPONSE_BUS_WIDTH - 1:0]  respIn1,
    output reg          respIn1_grant
);


    // Params
    localparam NUM_SECTORS  = 8;
    localparam SECTOR_WIDTH = 64;
    
    // Sectors
    wire[SECTOR_WIDTH-1:0] wrInput[NUM_SECTORS-1:0];
    wire[SECTOR_WIDTH-1:0] rdInput[NUM_SECTORS-1:0];
    wire[SECTOR_WIDTH-1:0] dataout[NUM_SECTORS-1:0];
    wire[(NUM_SECTORS*SECTOR_WIDTH)-1:0] wr_output;
    wire[NUM_SECTORS-1:0] sector_we;
    
    // Queue for incoming AMIRequests
    wire             reqInQ_empty;
    wire             reqInQ_full;
    wire             reqInQ_enq;
    reg              reqInQ_deq;
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_in;
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_out;
    // necessary for doing bitslicing of AMIReq bus
    wire[`AMI_DATA_WIDTH - 1:0] reqInQ_out_data;  
    wire[`AMI_DATA_WIDTH - 1:0] respIn0_data;

    assign reqInQ_out_data = reqInQ_out[`AMIRequest_data];
    assign respIn0_data = respIn0[`AMIResponse_data];
    
    // Following signals will be controlled by the FSM
    reg inMuxSel; // 0 for RdInput, 1 for WrInput


    genvar sector_num;
    generate 
        for (sector_num = 0; sector_num < NUM_SECTORS; sector_num = sector_num + 1) begin : sector_inst
            BlockSector
            #(
                .WIDTH(SECTOR_WIDTH)
            )
            block_sector
            (
                .clk (clk),
                .rst (rst),
                .wrInput(wrInput[sector_num]),
                .rdInput(rdInput[sector_num]),
                .inMuxSel(inMuxSel),
                .sector_we(sector_we[sector_num]),
                .dataout(dataout[sector_num])
            );
            
            assign wrInput[sector_num] = reqInQ_out_data[SECTOR_WIDTH-1:0];
            assign rdInput[sector_num] = respIn0_data[((sector_num+1)*SECTOR_WIDTH)-1:(sector_num*SECTOR_WIDTH)];
            assign wr_output[((sector_num+1)*SECTOR_WIDTH)-1:(sector_num*SECTOR_WIDTH)] = dataout[sector_num];
        end
    endgenerate

    // Read data out of the block
    wire [SECTOR_WIDTH-1:0] rd_output;
    reg [`C_LOG_2(NUM_SECTORS)-1:0] rd_mux_sel; // controlled by the FSM

    assign rd_output = dataout[rd_mux_sel];

    // Write enables per sector

    // FSM signals
    reg wr_all_sectors;
    reg wr_specific_sector;
    wire[`C_LOG_2(NUM_SECTORS)-1:0] wr_sector_index;
    
    we_decoder
    writes_decoder
    (
        .we_all      (wr_all_sectors),
        .we_specific (wr_specific_sector),
        .index       (wr_sector_index),
        .we_out      (sector_we)
    );

    generate
        if (`USE_SOFT_FIFO) begin : SoftFIFO_reqIn_memReqQ
            SoftFIFO
            #(
                .WIDTH                    (`AMI_REQUEST_BUS_WIDTH),
                .LOG_DEPTH                (BLOCK_BUFFER_REQ_IN_Q_DEPTH)
            )
            reqIn_memReqQ
            (
                .clock                    (clk),
                .reset_n                  (~rst),
                .wrreq                    (reqInQ_enq),
                .data                     (reqInQ_in),
                .full                     (reqInQ_full),
                .q                        (reqInQ_out),
                .empty                    (reqInQ_empty),
                .rdreq                    (reqInQ_deq)
            );
        end else begin : FIFO_reqIn_memReqQ
            FIFO
            #(
                .WIDTH                    (`AMI_REQUEST_BUS_WIDTH),
                .LOG_DEPTH                (BLOCK_BUFFER_REQ_IN_Q_DEPTH)
            )
            reqIn_memReqQ
            (
                .clock                    (clk),
                .reset_n                  (~rst),
                .wrreq                    (reqInQ_enq),
                .data                     (reqInQ_in),
                .full                     (reqInQ_full),
                .q                        (reqInQ_out),
                .empty                    (reqInQ_empty),
                .rdreq                    (reqInQ_deq)
            );
        end
    endgenerate        

    assign reqInQ_in   = reqIn;
    assign reqInQ_enq  = reqIn[`AMIRequest_valid] && !reqInQ_full;
    assign reqIn_grant = reqInQ_enq;

    // Queue for outgoing AMIResponses
    wire             respOutQ_empty;
    wire             respOutQ_full;
    reg              respOutQ_enq;
    wire             respOutQ_deq;
    reg [`AMI_RESPONSE_BUS_WIDTH - 1:0]      respOutQ_in;
    wire [`AMI_RESPONSE_BUS_WIDTH - 1:0]      respOutQ_out;    

    generate
        if (`USE_SOFT_FIFO) begin : SoftFIFO_respOut_memReqQ
            SoftFIFO
            #(
                .WIDTH                    (`AMI_RESPONSE_BUS_WIDTH),
                .LOG_DEPTH                (BLOCK_BUFFER_RESP_OUT_Q_DEPTH)
            )
            respOut_memReqQ
            (
                .clock                    (clk),
                .reset_n                  (~rst),
                .wrreq                    (respOutQ_enq),
                .data                     (respOutQ_in),
                .full                     (respOutQ_full),
                .q                        (respOutQ_out),
                .empty                    (respOutQ_empty),
                .rdreq                    (respOutQ_deq)
            );
        end else begin : FIFO_respOut_memReqQ
            FIFO
            #(
                .WIDTH                    (`AMI_RESPONSE_BUS_WIDTH),
                .LOG_DEPTH                (BLOCK_BUFFER_RESP_OUT_Q_DEPTH)
            )
            respOut_memReqQ
            (
                .clock                    (clk),
                .reset_n                (~rst),
                .wrreq                    (respOutQ_enq),
                .data                   (respOutQ_in),
                .full                   (respOutQ_full),
                .q                      (respOutQ_out),
                .empty                  (respOutQ_empty),
                .rdreq                  (respOutQ_deq)
            );
        end
    endgenerate
    
    //assign respOut = '{valid: (!respOutQ_empty && respOutQ_out.valid), data: respOutQ_out.data, size: respOutQ_out.size};
    assign respOut[`AMIResponse_valid] = (!respOutQ_empty && respOutQ_out[`AMIResponse_valid]);
    assign respOut[`AMIResponse_data] = respOutQ_out[`AMIResponse_data];
    assign respOut[`AMIResponse_size] =  respOutQ_out[`AMIResponse_size];
    assign respOutQ_deq = respOut_grant;
    
    /////////////////////
    // FSM
    /////////////////////

    // FSM States
    parameter INVALID     = 3'b000;
    parameter PENDING     = 3'b001;
    parameter CLEAN       = 3'b010;
    parameter MODIFIED    = 3'b011;

    // FSM registers
    reg[2:0]   current_state;
    reg[2:0]   next_state;

    // FSM reset/update
    always@(posedge clk) begin : fsm_update
        if (rst) begin
            current_state <= INVALID;
        end else begin
            current_state <= next_state;
        end
    end
    
    // Current request info
    reg[`AMI_ADDR_WIDTH-6:0]   current_block_index;
    reg[`AMI_ADDR_WIDTH-6:0]   new_block_index;
    reg                       block_index_we;

    always@(posedge clk) begin : current_block_update
        if (rst) begin
            current_block_index <= 0;
        end else begin
            if (block_index_we) begin
                current_block_index <= new_block_index;
            end else begin
                current_block_index <= current_block_index;
            end
        end
    end
    // FSM state transitions
    // FSM controlled signals
    // inMuxSel 0 for RdInput, 1 for WrInput
    // wr_all_sectors
    // wr_specific_sector
    // wr_sector_index
    // rd_mux_sel
    // reqOut0 for issuing reads
    // reqOut1 for issuing writes
    // respIn0_grant , read port
    // respIn1_grant , no responses should come back on the write port
    // reqIn_grant
    // respOut
    // block_index_we
    // new_block_index
    // reqInQ_deq
    // respOutQ_enq
    // respOutQ_in

    wire[`AMI_ADDR_WIDTH - 1:0] reqInQ_out_addr;
    assign reqInQ_out_addr = reqInQ_out[`AMIRequest_addr];
    assign wr_sector_index    = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment

    always @(*) begin
        // Signals controlling writing into the block
        inMuxSel           = 1'b0;
        wr_all_sectors     = 1'b0;
        wr_specific_sector = 1'b0;
        // mux out correct sector
        rd_mux_sel         = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
        // block index
        new_block_index = current_block_index;
        block_index_we  = 1'b0;
        // requests to the memory system
        // Read port
        //reqOut0[`AMIRequest_valid] = 1'b0;
        //reqOut0[`AMIRequest_isWrite] = 1'b0;
        //reqOut0[`AMIRequest_addr] = 64'b0;
        //reqOut0[`AMIRequest_data] = 512'b0;
        //reqOut0[`AMIRequest_size] = 6'd64;
        //reqOut0 = '{1'b0, 1'b0, 64'b0, 512'b0, 6'd64}; // read port
        reqOut0 = {6'd64, 512'b0, 64'b0, 1'b0, 1'b0};


        // Write port
        //reqOut1[`AMIRequest_valid] = 1'b0;
        //reqOut1[`AMIRequest_isWrite] = 1'b0;
        //reqOut1[`AMIRequest_addr] = 64'b0;
        //reqOut1[`AMIRequest_data] = 512'b0;
        //reqOut1[`AMIRequest_size] = 6'd64;
        //reqOut1 = '{valid: 0, isWrite: 1'b0, addr: 64'b0, data: 512'b0, size: 6'd64}; // write port
        reqOut1 = {6'd64, 512'b0, 64'b0, 1'b0, 1'b0};

        // response from memory system
        respIn0_grant = 1'b0;
        respIn1_grant = 1'b0;
        // control the queues to 
        reqInQ_deq   = 1'b0;
        respOutQ_enq = 1'b0;
        //respOutQ_in  = '{valid: 0, data: 512'b0, size: 64};
        respOutQ_in[`AMIResponse_valid]  = 0;
        respOutQ_in[`AMIResponse_data] = 512'b0;
        respOutQ_in[`AMIResponse_size] = 64; 
        // state control
        next_state = current_state;

        case (current_state)
            INVALID : begin
                // valid  request waiting to be serviced, but no valid block in the buffer
                //if (!reqInQ_empty && reqInQ_out.valid)  begin
                if (!reqInQ_empty && reqInQ_out[`AMIRequest_valid])  begin
                    //reqOut0 = '{valid: 1, isWrite: 1'b0, addr: {reqInQ_out_addr[63:6],6'b00_0000} , data: 512'b0, size: 64}; // read port
                    reqOut0[`AMIRequest_valid] = 1;
                    reqOut0[`AMIRequest_isWrite] = 1'b0;
                    reqOut0[`AMIRequest_addr] = {reqInQ_out_addr[63:6],6'b00_0000};
                    reqOut0[`AMIRequest_data] = 512'b0;
                    reqOut0[`AMIRequest_size] = 64; // read port
                    if (reqOut0_grant == 1'b1) begin
                        // block is being read
                        new_block_index = reqInQ_out_addr[63:6];
                        block_index_we  = 1'b1;
                        // go to pending state
                        next_state = PENDING;
                    end
                end
            end
            PENDING : begin
                // waiting for a block to be read from memory and into the block buffer
                if (respIn0[`AMIResponse_valid]) begin
                    inMuxSel = 1'b0; //rdInput
                    wr_all_sectors  = 1'b1; // write every sector
                    respIn0_grant = 1'b1; // accept the response
                    next_state = CLEAN;
                end
            end
            CLEAN : begin
                // we have a valid block, can service a request if the block index matches
                if (!reqInQ_empty && reqInQ_out[`AMIRequest_valid]) begin
                    // go ahead and service the request from the local block buffer
                    if (reqInQ_out_addr[63:6] == current_block_index) begin
                        // service a write operation
                        if (reqInQ_out[`AMIRequest_isWrite]) begin
                            inMuxSel = 1'b1; // wrInput
                            wr_specific_sector = 1'b1;
                            reqInQ_deq = 1'b1;
                            next_state = MODIFIED;
                        // service a read operation
                        end else begin
                            reqInQ_deq   = 1'b1;
                            respOutQ_enq = 1'b1;
                            //respOutQ_in  = '{valid: 1, data: {448'b0,rd_output}, size: 8};
                            respOutQ_in[`AMIResponse_valid] = 1;
                            respOutQ_in[`AMIResponse_data] = {448'b0,rd_output};
                            respOutQ_in[`AMIResponse_size] = 8; 
                        end
                    // a new block must be fetched, but this one does not need to be written back since it is CLEAN
                    end else begin
                        // fetch a different block
                        //reqOut0 = '{valid: 1, isWrite: 1'b0, addr: {reqInQ_out.addr[63:6],6'b00_0000} , data: 512'b0, size: 64}; // read port
                        reqOut0[`AMIRequest_valid] = 1;
                        reqOut0[`AMIRequest_isWrite] = 1'b0;
                        reqOut0[`AMIRequest_addr] = {reqInQ_out_addr[63:6],6'b00_0000};
                        reqOut0[`AMIRequest_data] = 512'b0;
                        reqOut0[`AMIRequest_size] = 64; // read port
                        if (reqOut0_grant == 1'b1) begin
                            // block is being read
                            new_block_index = reqInQ_out_addr[63:6];
                            block_index_we  = 1'b1;
                            // go to pending state
                            next_state = PENDING;
                        end
                    end
                end
                // otherwise sit idle and wait for a request
            end
            MODIFIED : begin
                // we have a valid block, can service a request if the block index matches
                if (!reqInQ_empty && reqInQ_out[`AMIRequest_valid]) begin
                    // go ahead and service the request from the local block buffer
                    if (reqInQ_out_addr[63:6] == current_block_index) begin
                        // service a write operation
                        if (reqInQ_out[`AMIRequest_isWrite]) begin
                            inMuxSel = 1'b1; // wrInput
                            wr_specific_sector = 1'b1;
                            reqInQ_deq = 1'b1;
                        // service a read operation
                        end else begin
                            reqInQ_deq   = 1'b1;
                            respOutQ_enq = 1'b1;
                            //respOutQ_in  = '{valid: 1, data: {448'b0,rd_output}, size: 8};
                            respOutQ_in[`AMIResponse_valid] = 1;
                            respOutQ_in[`AMIResponse_data] = {448'b0,rd_output};
                            respOutQ_in[`AMIResponse_size] = 8; 
                        end
                    // a new block must be fetched, but this one is DIRTY, so it must be written back first
                    end else begin
                        // issue a write and go to CLEAN state
                        //reqOut1 = '{valid: 1, isWrite: 1'b1, addr: {current_block_index,6'b00_0000} , data: wr_output, size: 64}; // write port
                        reqOut1[`AMIRequest_valid] = 1;
                        reqOut1[`AMIRequest_isWrite] = 1'b1;
                        reqOut1[`AMIRequest_addr] = {current_block_index,6'b00_0000};
                        reqOut1[`AMIRequest_data] = wr_output;
                        reqOut1[`AMIRequest_size] = 64; // write port
                        if (reqOut1_grant == 1'b1) begin
                            next_state = CLEAN;
                        end
                    end
                end
            end
            default : begin
                // should never be here
            end
        endcase
    end // FSM state transitions
    
endmodule

reg rst;
reg flush_buffer;
reg [`AMI_REQUEST_BUS_WIDTH - 1:0] reqIn;
wire reqIn_grant;
wire [`AMI_RESPONSE_BUS_WIDTH - 1:0] respOut;
reg respOut_grant;
wire [`AMI_REQUEST_BUS_WIDTH - 1:0] reqOut0;
reg reqOut0_grant;
wire [`AMI_REQUEST_BUS_WIDTH - 1:0] reqOut1;
reg reqOut1_grant;
reg [`AMI_RESPONSE_BUS_WIDTH - 1:0] respIn0;
wire respIn0_grant;
reg [`AMI_RESPONSE_BUS_WIDTH - 1:0] respIn1;
wire respIn1_grant;

BlockBuffer tbb(clock.val, rst, flush_buffer, reqIn, reqIn_grant, respOut, respOut_grant, reqOut0, reqOut0_grant, reqOut1, reqOut1_grant, respIn0, respIn0_grant, respIn1, respIn1_grant);



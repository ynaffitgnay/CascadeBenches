module SoftFIFO (
	clock,
	reset_n,
	wrreq,
	data,
	full,
	q,
	empty,
	rdreq
);
	parameter WIDTH = 512;
	parameter LOG_DEPTH = 9;
	input clock;
	input reset_n;
	input wrreq;
	input [WIDTH - 1:0] data;
	output full;
	output [WIDTH - 1:0] q;
	output empty;
	input rdreq;
	reg [WIDTH - 1:0] buffer [(1 << LOG_DEPTH) - 1:0];
	reg [LOG_DEPTH:0] counter;
	reg [LOG_DEPTH:0] new_counter;
	reg [LOG_DEPTH - 1:0] rd_ptr;
	reg [LOG_DEPTH - 1:0] wr_ptr;
	reg [LOG_DEPTH - 1:0] new_rd_ptr;
	reg [LOG_DEPTH - 1:0] new_wr_ptr;
	assign empty = counter == 0;
	assign full = counter == (1 << LOG_DEPTH);
	assign q = buffer[rd_ptr];
	always @(posedge clock)
		if (!reset_n) begin
			counter <= 0;
			rd_ptr <= 0;
			wr_ptr <= 0;
		end
		else begin
			counter <= new_counter;
			rd_ptr <= new_rd_ptr;
			wr_ptr <= new_wr_ptr;
		end
	always @(posedge clock)
		if (!full && wrreq)
			buffer[wr_ptr] <= data;
		else
			buffer[wr_ptr] <= buffer[wr_ptr];
	always @(*)
		if ((!full && wrreq) && (!empty && rdreq)) begin
			new_counter = counter;
			new_rd_ptr = rd_ptr + 1;
			new_wr_ptr = wr_ptr + 1;
		end
		else if (!full && wrreq) begin
			new_counter = counter + 1;
			new_rd_ptr = rd_ptr;
			new_wr_ptr = wr_ptr + 1;
		end
		else if (!empty && rdreq) begin
			new_counter = counter - 1;
			new_rd_ptr = rd_ptr + 1;
			new_wr_ptr = wr_ptr;
		end
		else begin
			new_counter = counter;
			new_rd_ptr = rd_ptr;
			new_wr_ptr = wr_ptr;
		end
endmodule
module FIFO (
	clock,
	reset_n,
	wrreq,
	data,
	full,
	q,
	empty,
	rdreq
);
	parameter WIDTH = 512;
	parameter LOG_DEPTH = 9;
	input clock;
	input reset_n;
	input wrreq;
	input [WIDTH - 1:0] data;
	output full;
	output [WIDTH - 1:0] q;
	output empty;
	input rdreq;
	reg [WIDTH - 1:0] buffer [(1 << LOG_DEPTH) - 1:0];
	reg [LOG_DEPTH:0] counter;
	reg [LOG_DEPTH:0] new_counter;
	reg [LOG_DEPTH - 1:0] rd_ptr;
	reg [LOG_DEPTH - 1:0] wr_ptr;
	reg [LOG_DEPTH - 1:0] new_rd_ptr;
	reg [LOG_DEPTH - 1:0] new_wr_ptr;
	assign empty = counter == 0;
	assign full = counter == (1 << LOG_DEPTH);
	assign q = buffer[rd_ptr];
	always @(posedge clock)
		if (!reset_n) begin
			counter <= 0;
			rd_ptr <= 0;
			wr_ptr <= 0;
		end
		else begin
			counter <= new_counter;
			rd_ptr <= new_rd_ptr;
			wr_ptr <= new_wr_ptr;
		end
	always @(posedge clock)
		if (!full && wrreq)
			buffer[wr_ptr] <= data;
		else
			buffer[wr_ptr] <= buffer[wr_ptr];
	always @(*)
		if ((!full && wrreq) && (!empty && rdreq)) begin
			new_counter = counter;
			new_rd_ptr = rd_ptr + 1;
			new_wr_ptr = wr_ptr + 1;
		end
		else if (!full && wrreq) begin
			new_counter = counter + 1;
			new_rd_ptr = rd_ptr;
			new_wr_ptr = wr_ptr + 1;
		end
		else if (!empty && rdreq) begin
			new_counter = counter - 1;
			new_rd_ptr = rd_ptr + 1;
			new_wr_ptr = wr_ptr;
		end
		else begin
			new_counter = counter;
			new_rd_ptr = rd_ptr;
			new_wr_ptr = wr_ptr;
		end
endmodule
module BlockSector (
	clk,
	rst,
	wrInput,
	rdInput,
	inMuxSel,
	sector_we,
	dataout
);
	parameter integer WIDTH = 64;
	input clk;
	input rst;
	input [WIDTH - 1:0] wrInput;
	input [WIDTH - 1:0] rdInput;
	input inMuxSel;
	input sector_we;
	output wire [WIDTH - 1:0] dataout;
	reg [WIDTH - 1:0] data_reg;
	wire [WIDTH - 1:0] new_data;
	always @(posedge clk)
		if (rst)
			data_reg <= 0;
		else if (sector_we)
			data_reg <= new_data;
	assign dataout = data_reg;
	assign new_data = (inMuxSel == 1'b1 ? wrInput : rdInput);
endmodule
module we_decoder (
	we_all,
	we_specific,
	index,
	we_out
);
	input we_all;
	input we_specific;
	input [2:0] index;
	output reg [7:0] we_out;
	always @(*) begin
		we_out = 8'b0000_0000;
		if (we_all)
			we_out = 8'b1111_1111;
		else if (we_specific)
			we_out[index] = 1'b1;
	end
endmodule
module block_rotate (
	rotate_amount,
	inData,
	outData
);
	parameter integer WIDTH = 64;
	parameter integer NUM_SECTORS = 8;
	input [2:0] rotate_amount;
	input [((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? (NUM_SECTORS * WIDTH) + -1 : (NUM_SECTORS * (2 - WIDTH)) + ((WIDTH - 1) - 1)) : ((WIDTH - 1) >= 0 ? ((2 - NUM_SECTORS) * WIDTH) + (((NUM_SECTORS - 1) * WIDTH) - 1) : ((2 - NUM_SECTORS) * (2 - WIDTH)) + (((WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))) - 1))):((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) : ((WIDTH - 1) >= 0 ? (NUM_SECTORS - 1) * WIDTH : (WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))))] inData;
	output reg [((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? (NUM_SECTORS * WIDTH) + -1 : (NUM_SECTORS * (2 - WIDTH)) + ((WIDTH - 1) - 1)) : ((WIDTH - 1) >= 0 ? ((2 - NUM_SECTORS) * WIDTH) + (((NUM_SECTORS - 1) * WIDTH) - 1) : ((2 - NUM_SECTORS) * (2 - WIDTH)) + (((WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))) - 1))):((NUM_SECTORS - 1) >= 0 ? ((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) : ((WIDTH - 1) >= 0 ? (NUM_SECTORS - 1) * WIDTH : (WIDTH - 1) + ((NUM_SECTORS - 1) * (2 - WIDTH))))] outData;
	always @(*) begin
		outData = inData;
		if (rotate_amount == 0)
			outData = inData;
		else if (rotate_amount == 1) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 2) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 3) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 4) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 5) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 6) begin
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 0 : NUM_SECTORS - 1) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 1 : -1 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 2 : -2 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 3 : -3 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 6 : -6 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 4 : -4 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
			outData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 7 : -7 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)] = inData[((WIDTH - 1) >= 0 ? 0 : WIDTH - 1) + (((NUM_SECTORS - 1) >= 0 ? 5 : -5 + (NUM_SECTORS - 1)) * ((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH))+:((WIDTH - 1) >= 0 ? WIDTH : 2 - WIDTH)];
		end
		else if (rotate_amount == 7) begin
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

endmodule // block_rotate

module BlockBuffer (
	clk,
	rst,
	flush_buffer,
	reqIn,
	reqIn_grant,
	respOut,
	respOut_grant,
	reqOut,
	reqOut_grant,
	respIn,
	respIn_grant
);
	parameter AMI_ADDR_WIDTH = 64;
	parameter AMI_NUM_PORTS = 2;
	parameter BLOCK_BUFFER_REQ_IN_Q_DEPTH = (USE_SOFT_FIFO ? 3 : 9);
	parameter BLOCK_BUFFER_RESP_OUT_Q_DEPTH = (USE_SOFT_FIFO ? 3 : 9);
	parameter USE_SOFT_FIFO = 1;
	input clk;
	input rst;
	input flush_buffer;
	input AMIRequest reqIn;
	output wire reqIn_grant;
	output AMIResponse respOut;
	input respOut_grant;
	output AMIRequest [AMI_NUM_PORTS - 1:0] reqOut;
	input [AMI_NUM_PORTS - 1:0] reqOut_grant;
	input AMIResponse [AMI_NUM_PORTS - 1:0] respIn;
	output reg [AMI_NUM_PORTS - 1:0] respIn_grant;
	localparam NUM_SECTORS = 8;
	localparam SECTOR_WIDTH = 64;
	wire [SECTOR_WIDTH - 1:0] wrInput [NUM_SECTORS - 1:0];
	wire [SECTOR_WIDTH - 1:0] rdInput [NUM_SECTORS - 1:0];
	wire [SECTOR_WIDTH - 1:0] dataout [NUM_SECTORS - 1:0];
	wire [(NUM_SECTORS * SECTOR_WIDTH) - 1:0] wr_output;
	wire [NUM_SECTORS - 1:0] sector_we;
	wire reqInQ_empty;
	wire reqInQ_full;
	wire reqInQ_enq;
	reg reqInQ_deq;
	AMIRequest reqInQ_in;
	AMIRequest reqInQ_out;
	reg inMuxSel;
	genvar sector_num;
	generate
		for (sector_num = 0; sector_num < NUM_SECTORS; sector_num = sector_num + 1) begin : sector_inst
			BlockSector #(.WIDTH(SECTOR_WIDTH)) block_sector(
				.clk(clk),
				.rst(rst),
				.wrInput(wrInput[sector_num]),
				.rdInput(rdInput[sector_num]),
				.inMuxSel(inMuxSel),
				.sector_we(sector_we[sector_num]),
				.dataout(dataout[sector_num])
			);
			assign wrInput[sector_num] = reqInQ_out.data[SECTOR_WIDTH - 1:0];
			assign rdInput[sector_num] = respIn[0].data[((sector_num + 1) * SECTOR_WIDTH) - 1:sector_num * SECTOR_WIDTH];
			assign wr_output[((sector_num + 1) * SECTOR_WIDTH) - 1:sector_num * SECTOR_WIDTH] = dataout[sector_num];
		end
	endgenerate
	wire [SECTOR_WIDTH - 1:0] rd_output;
	reg [(NUM_SECTORS <= (1 << 0) ? 0 : (NUM_SECTORS <= (1 << 1) ? 1 : (NUM_SECTORS <= (1 << 2) ? 2 : (NUM_SECTORS <= (1 << 3) ? 3 : (NUM_SECTORS <= (1 << 4) ? 4 : (NUM_SECTORS <= (1 << 5) ? 5 : (NUM_SECTORS <= (1 << 6) ? 6 : (NUM_SECTORS <= (1 << 7) ? 7 : (NUM_SECTORS <= (1 << 8) ? 8 : (NUM_SECTORS <= (1 << 9) ? 9 : (NUM_SECTORS <= (1 << 10) ? 10 : (NUM_SECTORS <= (1 << 11) ? 11 : (NUM_SECTORS <= (1 << 12) ? 12 : (NUM_SECTORS <= (1 << 13) ? 13 : (NUM_SECTORS <= (1 << 14) ? 14 : (NUM_SECTORS <= (1 << 15) ? 15 : (NUM_SECTORS <= (1 << 16) ? 16 : (NUM_SECTORS <= (1 << 17) ? 17 : (NUM_SECTORS <= (1 << 18) ? 18 : (NUM_SECTORS <= (1 << 19) ? 19 : (NUM_SECTORS <= (1 << 20) ? 20 : (NUM_SECTORS <= (1 << 21) ? 21 : (NUM_SECTORS <= (1 << 22) ? 22 : (NUM_SECTORS <= (1 << 23) ? 23 : (NUM_SECTORS <= (1 << 24) ? 24 : (NUM_SECTORS <= (1 << 25) ? 25 : (NUM_SECTORS <= (1 << 26) ? 26 : (NUM_SECTORS <= (1 << 27) ? 27 : (NUM_SECTORS <= (1 << 28) ? 28 : (NUM_SECTORS <= (1 << 29) ? 29 : (NUM_SECTORS <= (1 << 30) ? 30 : (NUM_SECTORS <= (1 << 31) ? 31 : 32)))))))))))))))))))))))))))))))) - 1:0] rd_mux_sel;
	assign rd_output = dataout[rd_mux_sel];
	reg wr_all_sectors;
	reg wr_specific_sector;
	reg [(NUM_SECTORS <= (1 << 0) ? 0 : (NUM_SECTORS <= (1 << 1) ? 1 : (NUM_SECTORS <= (1 << 2) ? 2 : (NUM_SECTORS <= (1 << 3) ? 3 : (NUM_SECTORS <= (1 << 4) ? 4 : (NUM_SECTORS <= (1 << 5) ? 5 : (NUM_SECTORS <= (1 << 6) ? 6 : (NUM_SECTORS <= (1 << 7) ? 7 : (NUM_SECTORS <= (1 << 8) ? 8 : (NUM_SECTORS <= (1 << 9) ? 9 : (NUM_SECTORS <= (1 << 10) ? 10 : (NUM_SECTORS <= (1 << 11) ? 11 : (NUM_SECTORS <= (1 << 12) ? 12 : (NUM_SECTORS <= (1 << 13) ? 13 : (NUM_SECTORS <= (1 << 14) ? 14 : (NUM_SECTORS <= (1 << 15) ? 15 : (NUM_SECTORS <= (1 << 16) ? 16 : (NUM_SECTORS <= (1 << 17) ? 17 : (NUM_SECTORS <= (1 << 18) ? 18 : (NUM_SECTORS <= (1 << 19) ? 19 : (NUM_SECTORS <= (1 << 20) ? 20 : (NUM_SECTORS <= (1 << 21) ? 21 : (NUM_SECTORS <= (1 << 22) ? 22 : (NUM_SECTORS <= (1 << 23) ? 23 : (NUM_SECTORS <= (1 << 24) ? 24 : (NUM_SECTORS <= (1 << 25) ? 25 : (NUM_SECTORS <= (1 << 26) ? 26 : (NUM_SECTORS <= (1 << 27) ? 27 : (NUM_SECTORS <= (1 << 28) ? 28 : (NUM_SECTORS <= (1 << 29) ? 29 : (NUM_SECTORS <= (1 << 30) ? 30 : (NUM_SECTORS <= (1 << 31) ? 31 : 32)))))))))))))))))))))))))))))))) - 1:0] wr_sector_index;
	we_decoder writes_decoder(
		.we_all(wr_all_sectors),
		.we_specific(wr_specific_sector),
		.index(wr_sector_index),
		.we_out(sector_we)
	);
	generate
		if (USE_SOFT_FIFO) begin : SoftFIFO_reqIn_memReqQ
			SoftFIFO #(
				.WIDTH($bits(type(AMIRequest))),
				.LOG_DEPTH(BLOCK_BUFFER_REQ_IN_Q_DEPTH)
			) reqIn_memReqQ(
				.clock(clk),
				.reset_n(~rst),
				.wrreq(reqInQ_enq),
				.data(reqInQ_in),
				.full(reqInQ_full),
				.q(reqInQ_out),
				.empty(reqInQ_empty),
				.rdreq(reqInQ_deq)
			);
		end
		else begin : FIFO_reqIn_memReqQ
			FIFO #(
				.WIDTH($bits(type(AMIRequest))),
				.LOG_DEPTH(BLOCK_BUFFER_REQ_IN_Q_DEPTH)
			) reqIn_memReqQ(
				.clock(clk),
				.reset_n(~rst),
				.wrreq(reqInQ_enq),
				.data(reqInQ_in),
				.full(reqInQ_full),
				.q(reqInQ_out),
				.empty(reqInQ_empty),
				.rdreq(reqInQ_deq)
			);
		end
	endgenerate
	assign reqInQ_in = reqIn;
	assign reqInQ_enq = reqIn.valid && !reqInQ_full;
	assign reqIn_grant = reqInQ_enq;
	wire respOutQ_empty;
	wire respOutQ_full;
	reg respOutQ_enq;
	wire respOutQ_deq;
	AMIResponse respOutQ_in;
	AMIResponse respOutQ_out;
	generate
		if (USE_SOFT_FIFO) begin : SoftFIFO_respOut_memReqQ
			SoftFIFO #(
				.WIDTH($bits(type(AMIResponse))),
				.LOG_DEPTH(BLOCK_BUFFER_RESP_OUT_Q_DEPTH)
			) respOut_memReqQ(
				.clock(clk),
				.reset_n(~rst),
				.wrreq(respOutQ_enq),
				.data(respOutQ_in),
				.full(respOutQ_full),
				.q(respOutQ_out),
				.empty(respOutQ_empty),
				.rdreq(respOutQ_deq)
			);
		end
		else begin : FIFO_respOut_memReqQ
			FIFO #(
				.WIDTH($bits(type(AMIResponse))),
				.LOG_DEPTH(BLOCK_BUFFER_RESP_OUT_Q_DEPTH)
			) respOut_memReqQ(
				.clock(clk),
				.reset_n(~rst),
				.wrreq(respOutQ_enq),
				.data(respOutQ_in),
				.full(respOutQ_full),
				.q(respOutQ_out),
				.empty(respOutQ_empty),
				.rdreq(respOutQ_deq)
			);
		end
	endgenerate
	assign respOut = '{
		valid: !respOutQ_empty && respOutQ_out.valid,
		data: respOutQ_out.data,
		size: respOutQ_out.size
	};
	assign respOutQ_deq = respOut_grant;
	parameter INVALID = 3'b000;
	parameter PENDING = 3'b001;
	parameter CLEAN = 3'b010;
	parameter MODIFIED = 3'b011;
	reg [2:0] current_state;
	reg [2:0] next_state;
	always @(posedge clk) begin : fsm_update
		if (rst)
			current_state <= INVALID;
		else
			current_state <= next_state;
	end
	reg [`AMI_ADDR_WIDTH - 6:0] current_block_index;
	reg [`AMI_ADDR_WIDTH - 6:0] new_block_index;
	reg block_index_we;
	always @(posedge clk) begin : current_block_update
		if (rst)
			current_block_index <= 0;
		else if (block_index_we)
			current_block_index <= new_block_index;
	end
	always @(*) begin
		inMuxSel = 1'b0;
		wr_all_sectors = 1'b0;
		wr_specific_sector = 1'b0;
		wr_sector_index = reqInQ_out.addr[5:3];
		rd_mux_sel = reqInQ_out.addr[5:3];
		new_block_index = current_block_index;
		block_index_we = 1'b0;
		reqOut[0] = '{
			valid: 0,
			isWrite: 1'b0,
			addr: 64'b0,
			data: 512'b0,
			size: 64
		};
		reqOut[1] = '{
			valid: 0,
			isWrite: 1'b0,
			addr: 64'b0,
			data: 512'b0,
			size: 64
		};
		respIn_grant[0] = 1'b0;
		respIn_grant[1] = 1'b0;
		reqInQ_deq = 1'b0;
		respOutQ_enq = 1'b0;
		respOutQ_in = '{
			valid: 0,
			data: 512'b0,
			size: 64
		};
		next_state = current_state;
		case (current_state)
			INVALID:
				if (!reqInQ_empty && reqInQ_out.valid) begin
					reqOut[0] = '{
						valid: 1,
						isWrite: 1'b0,
						addr: {reqInQ_out.addr[63:6], 6'b00_0000},
						data: 512'b0,
						size: 64
					};
					if (reqOut_grant[0] == 1'b1) begin
						new_block_index = reqInQ_out.addr[63:6];
						block_index_we = 1'b1;
						next_state = PENDING;
					end
				end
			PENDING:
				if (respIn[0].valid) begin
					inMuxSel = 1'b0;
					wr_all_sectors = 1'b1;
					respIn_grant[0] = 1'b1;
					next_state = CLEAN;
				end
			CLEAN:
				if (!reqInQ_empty && reqInQ_out.valid)
					if (reqInQ_out.addr[63:6] == current_block_index) begin
						if (reqInQ_out.isWrite) begin
							inMuxSel = 1'b1;
							wr_specific_sector = 1'b1;
							reqInQ_deq = 1'b1;
							next_state = MODIFIED;
						end
						else begin
							reqInQ_deq = 1'b1;
							respOutQ_enq = 1'b1;
							respOutQ_in = '{
								valid: 1,
								data: {448'b0, rd_output},
								size: 8
							};
						end
					end
					else begin
						reqOut[0] = '{
							valid: 1,
							isWrite: 1'b0,
							addr: {reqInQ_out.addr[63:6], 6'b00_0000},
							data: 512'b0,
							size: 64
						};
						if (reqOut_grant[0] == 1'b1) begin
							new_block_index = reqInQ_out.addr[63:6];
							block_index_we = 1'b1;
							next_state = PENDING;
						end
					end
			MODIFIED:
				if (!reqInQ_empty && reqInQ_out.valid)
					if (reqInQ_out.addr[63:6] == current_block_index) begin
						if (reqInQ_out.isWrite) begin
							inMuxSel = 1'b1;
							wr_specific_sector = 1'b1;
							reqInQ_deq = 1'b1;
						end
						else begin
							reqInQ_deq = 1'b1;
							respOutQ_enq = 1'b1;
							respOutQ_in = '{
								valid: 1,
								data: {448'b0, rd_output},
								size: 8
							};
						end
					end
					else begin
						reqOut[1] = '{
							valid: 1,
							isWrite: 1'b1,
							addr: {current_block_index, 6'b00_0000},
							data: wr_output,
							size: 64
						};
						if (reqOut_grant[1] == 1'b1)
							next_state = CLEAN;
					end
			default:
				;
		endcase
	end
endmodule

//`timescale 1ns/1ps
module ROM #(
// Parameters
  parameter   DATA_WIDTH          = 16,
  parameter   INIT                = "input_files/dnnweaver/norm_lut.mif",
  parameter   ADDR_WIDTH          = 6,
  parameter   TYPE                = "DISTRIBUTED",
  parameter   INITIALIZE_FIFO     = "yes"
) (
// Port Declarations
  input  wire                         clk,
  input  wire                         reset,
  input  wire  [ADDR_WIDTH-1:0]       address,
  input  wire                         enable,
  output reg   [DATA_WIDTH-1:0]       data_out
);

// ******************************************************************
// Internal variables
// ******************************************************************
  localparam   ROM_DEPTH          = 1 << ADDR_WIDTH;
  (* ram_style = TYPE *)
  reg     [DATA_WIDTH-1:0]        mem[ROM_DEPTH-1:0];     //Memory
// ******************************************************************
// Read Logic
// ******************************************************************

  always @ (posedge clk)
  begin : READ_BLK
    if(!reset) begin
      if (enable)
        data_out <= mem[address];
      else
        data_out <= data_out;
    end else begin
      data_out <= 0;
    end
  end

// ******************************************************************
// Variables for cascade file interface
// ******************************************************************
integer lutstream = $fopen(INIT, "r"); 
integer i = 0;
reg[DATA_WIDTH-1:0] val = 0;


// ******************************************************************
// Initialization
// ******************************************************************

  initial begin
    for (i = 0; i < ROM_DEPTH; i = i + 1) begin
      if (!($feof(lutstream))) begin
        $fscanf(lutstream, "%b", val);
        mem[i] <= val;  
      end 
      else begin
        mem[i] <= 0;
      end // else: !if(!($feof(lutstream)))
    end // for (i = 0; i < ROM_DEPTH; i = i + 1)
  end // initial begin
  

endmodule // ROM

//reg r;
//reg [15:0] addr;
//reg en;
//wire [15:0] data;
//
//ROM#(.DATA_WIDTH(16), .ADDR_WIDTH(11)) tr(clock.val, r, addr, en, data);

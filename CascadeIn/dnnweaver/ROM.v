//`timescale 1ns/1ps
module ROM #(
// Parameters
  parameter   DATA_WIDTH          = 16,
  parameter   INIT                = "input_files/dnnweaver/norm_lut_mif_hex.txt",
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
    //$display("mem[%d] = %h\n", i, mem[i]);
    //$display("i: %d", i);
    //$display("mem[0] = %h\n", mem[0]);
    //$display("hello");
  end

// ******************************************************************
// Variables for cascade file interface
// ******************************************************************
integer lutstream = $fopen(INIT, "r"); //$fopen("input_files/dnnweaver/norm_lut_mif_hex.txt", "r"); //
integer i = 0;
reg[DATA_WIDTH-1:0] val = 0;


// ******************************************************************
// Initialization
// ******************************************************************

  initial begin
    //`ifdef simulation
    //  $readmemb("./hardware/include/norm_lut.vh", mem);
    //`else
    //  $readmemb("norm_lut.mif", mem);
    //`endif
    for (i = 0; i < ROM_DEPTH; i = i + 1) begin
      if (!($feof(lutstream))) begin
        //$fscanf(lutstream, "%b", val);
        $fread(lutstream, val);
        mem[i] = val;
        //$display("mem[%d] = %h\n", i, mem[i]);
        $display("val: %h\n", val);
        //$display("%d", i);

        //$display("hello\n");
      end 
      else begin
        mem[i] <= 0;
      end // else: !if(!($feof(lutstream)))

    end // for (i = 0; i < ROM_DEPTH; i = i + 1)

    for (i = 0; i < ROM_DEPTH; i = i + 1) begin
      $display("mem[%d] = %h\n", i, mem[i]);
      //$display("%d", i);
    end
  end


endmodule // ROM

reg r;
reg [15:0] addr;
reg en;
wire [15:0] data;

ROM#(.DATA_WIDTH(16), .ADDR_WIDTH(11)) tr(clock.val, r, addr, en, data);

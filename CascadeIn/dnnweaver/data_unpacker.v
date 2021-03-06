`include "common.vh"
module data_unpacker #(
// ******************************************************************
// Parameters
// ******************************************************************
  parameter integer IN_WIDTH        = 128,
  parameter integer OUT_WIDTH       = 64
)
// ******************************************************************
// IO
// ******************************************************************
(
  input  wire                                         clk,
  input  wire                                         reset,
  output wire                                         m_packed_read_req,
  input  wire  [ IN_WIDTH             -1 : 0 ]        m_packed_read_data,
  input  wire                                         m_packed_read_ready,
  input  wire                                         m_unpacked_write_ready,
  output reg                                          m_unpacked_write_req,
  output wire  [ OUT_WIDTH            -1 : 0 ]        m_unpacked_write_data
);

localparam MAX_READS = (IN_WIDTH < OUT_WIDTH ? 1 : IN_WIDTH % OUT_WIDTH == 0 ? IN_WIDTH/OUT_WIDTH : IN_WIDTH/OUT_WIDTH+1);
localparam READ_COUNT_W = `C_LOG_2(MAX_READS) + 1;
reg rd_valid;
reg [READ_COUNT_W-1:0] rd_count;
wire rd_count_inc;
wire rd_count_overflow;
assign rd_count_inc = (rd_count == 0 && rd_valid) || rd_count != 0;
assign rd_count_overflow = rd_count == MAX_READS-1;

reg [IN_WIDTH-1:0] data;

always @(posedge clk)
  if (reset)
    rd_count <= 0;
  else if (rd_count_inc && rd_count_overflow)
    rd_count <= 0;
  else if (rd_count_inc)
    rd_count <= rd_count + 1'b1;



always @(posedge clk)
  if (reset)
    rd_valid <= 0;
  else if (rd_count == 0)
    rd_valid <= m_packed_read_req;

assign m_packed_read_req = rd_count == 0 && m_packed_read_ready;

always @(posedge clk)
  if (reset)
    m_unpacked_write_req <= 0;
  else
    m_unpacked_write_req <= rd_valid || rd_count != 0;

always @(posedge clk)
  if (reset)
    data <= 0;
  else if (rd_count != 0)
    data <= data >> OUT_WIDTH;
  else if (rd_valid)
    data <= m_packed_read_data;

assign m_unpacked_write_data = data[OUT_WIDTH-1:0];

endmodule

//reg rst;
//wire b1;
//wire [127:0] b2;
//wire b3, b4, b5;
//wire [63:0] b6;
//
////data_unpacker dtest(clock.val, rst, b1, b2, b3, b4, b5, b6);
//
//data_unpacker #(
//      .IN_WIDTH                 ( 4 * 16                ),
//      .OUT_WIDTH                ( 64               )
//    ) d_unpacker (
//      .clk                      ( /*clk                     */ ),  //input
//      .reset                    ( /*reset */                    ),  //input
//      .m_packed_read_req        ( /*m_packed_read_req      */  ),  //output
//      .m_packed_read_ready      ( /*m_packed_read_ready    */  ),  //input
//      .m_packed_read_data       ( /*m_packed_read_data     */  ),  //output
//      .m_unpacked_write_req     ( /*m_unpacked_write_req   */  ),  //output
//      .m_unpacked_write_ready   ( /*m_unpacked_write_ready */  ),  //input
//      .m_unpacked_write_data    ( /*m_unpacked_write_data  */  )   //output
//      );

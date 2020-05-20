`include "common.vh"
//`include "ShellTypes.sv"
`include "AMITypes.sv"
`include "BlockBuffer.sv"
`include "dnn_accelerator_ami.sv"


module dnnweaver_ami_top #(
// ******************************************************************
// Parameters
// ******************************************************************
  parameter integer PU_TID_WIDTH      = 16,
  parameter integer AXI_TID_WIDTH     = 6,
  parameter integer NUM_PU            = 1,
  parameter integer ADDR_W            = 32,
  parameter integer OP_WIDTH          = 16,
  parameter integer AXI_DATA_W        = 64,
  parameter integer NUM_PE            = 4,
  parameter integer BASE_ADDR_W       = ADDR_W,
  parameter integer OFFSET_ADDR_W     = ADDR_W,
  parameter integer TX_SIZE_WIDTH     = 20,
  parameter integer RD_LOOP_W         = 10,
  parameter integer D_TYPE_W          = 2,
  parameter integer ROM_ADDR_W        = 3,
  parameter integer SERDES_COUNT_W    = 6,
  parameter integer PE_SEL_W          = `C_LOG_2(NUM_PE),
  parameter integer DATA_W            = NUM_PE * OP_WIDTH, // double check this
  parameter integer LAYER_PARAM_WIDTH  = 10
) (
// ******************************************************************
// IO
// ******************************************************************
  input  wire                                        clk,
  input  wire                                        reset,
  input  wire                                        start,
  input  wire                                        flush_buffer, // TODO: Actually connect it
  output wire                                        done,
  // Debug
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_kw,
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_kh,
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_iw,
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_ih,
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_ic,
  output wire [ LAYER_PARAM_WIDTH    -1 : 0 ]        dbg_oc,

  output wire [ 32                   -1 : 0 ]        buffer_read_count,
  output wire [ 32                   -1 : 0 ]        stream_read_count,
  output wire [ 11                   -1 : 0 ]        inbuf_count,
  output wire [ NUM_PU               -1 : 0 ]        pu_write_valid,
  output wire [ ROM_ADDR_W           -1 : 0 ]        wr_cfg_idx,
  output wire [ ROM_ADDR_W           -1 : 0 ]        rd_cfg_idx,
  output wire [ NUM_PU               -1 : 0 ]        outbuf_push,

  output wire [ 3                    -1 : 0 ]        pu_controller_state,
  output wire [ 2                    -1 : 0 ]        vecgen_state,
  output reg  [ 16                   -1 : 0 ]        vecgen_read_count,

  // AMI signals
  output [ `AMI_REQUEST_BUS_WIDTH - 1 : 0 ]          mem_req0,
  input                                              mem_req0_grant,
  output [ `AMI_REQUEST_BUS_WIDTH - 1 : 0 ]          mem_req1,
  input                                              mem_req1_grant,
  input  [ `AMI_RESPONSE_BUS_WIDTH - 1 : 0 ]         mem_resp0,
  output                                             mem_resp0_grant,
  input  [ `AMI_RESPONSE_BUS_WIDTH - 1 : 0 ]         mem_resp1,
  output                                             mem_resp1_grant,
  output l_inc
  
);

    // Signals between DNNWeaver and the BlockBuffer
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0] reqIn;
    wire reqIn_grant;
    wire[`AMI_RESPONSE_BUS_WIDTH - 1:0] respOut;
    wire respOut_grant;

    // Block buffer
    BlockBuffer
    block_buffer
    (
        // General signals
        .clk (clk),
        .rst (reset),
        .flush_buffer (1'b0),
        // Interface to App
        .reqIn (reqIn),
        .reqIn_grant (reqIn_grant),
        .respOut (respOut),
        .respOut_grant (respOut_grant),
        // Interface to Memory system, 2 ports enables simulatentous eviction and request of a new block
        .reqOut0(mem_req0), // port 0 is the rd port, port 1 is the wr port
        .reqOut0_grant(mem_req0_grant),
        .reqOut1(mem_req1), // port 0 is the rd port, port 1 is the wr port
        .reqOut1_grant(mem_req1_grant),
        .respIn0(mem_resp0),
        .respIn0_grant(mem_resp0_grant),
        .respIn1(mem_resp1),
        .respIn1_grant(mem_resp1_grant)
    );

    //always @(posedge clk) begin
    //    if (mem_req0[`AMIRequest_valid]) begin
    //        $display("reqOut0: addr: %h, size %d", mem_req0[`AMIRequest_addr], mem_req0[`AMIRequest_size]);
    //    end
    //
    //    if (mem_req1[`AMIRequest_valid]) begin
    //        $display("reqOut0: addr: %h, size %d", mem_req1[`AMIRequest_addr], mem_req1[`AMIRequest_size]);
    //    end
    //end


    
    dnn_accelerator_ami #(
    // INPUT PARAMETERS
    .NUM_PE                   ( NUM_PE                   ),
    .NUM_PU                   ( NUM_PU                   ),
    .ADDR_W                   ( ADDR_W                   ),
    .AXI_DATA_W               ( DATA_W                   ),
    .BASE_ADDR_W              ( BASE_ADDR_W              ),
    .OFFSET_ADDR_W            ( OFFSET_ADDR_W            ),
    .RD_LOOP_W                ( RD_LOOP_W                ),
    .TX_SIZE_WIDTH            ( TX_SIZE_WIDTH            ),
    .D_TYPE_W                 ( D_TYPE_W                 ),
    .ROM_ADDR_W               ( ROM_ADDR_W               )
    ) 
    accelerator_inst 
    ( // PORTS
    .clk                      ( clk                      ),
    .reset                    ( reset                    ),
    .start                    ( start                    ),
    .done                     ( done                     ),
    // Debug
    .dbg_kw (dbg_kw),
    .dbg_kh(dbg_kh),
    .dbg_iw(dbg_iw),
    .dbg_ih(dbg_ih),
    .dbg_ic(dbg_ic),
    .dbg_oc(dbg_oc),
    .buffer_read_count(buffer_read_count),
    .stream_read_count(stream_read_count),
    .inbuf_count(inbuf_count),
    .pu_write_valid(pu_write_valid),
    .wr_cfg_idx(wr_cfg_idx),
    .rd_cfg_idx(rd_cfg_idx),
    .outbuf_push(outbuf_push),
    .pu_controller_state(pu_controller_state),
    .vecgen_state(vecgen_state),
    .vecgen_read_count(vecgen_read_count),
    // AMI memory
    .mem_req                  ( reqIn                    ),
    .mem_req_grant            ( reqIn_grant              ),
    .mem_resp                 ( respOut                  ),
    .mem_resp_grant           ( respOut_grant            ),
    .l_inc                    ( l_inc)
 

    );

endmodule

//initial $display("start");
//
//
//dnnweaver_ami_top tdat
//(
//  .clk(clock.val),
//  .reset(),
//  .start(),
//  .flush_buffer(), // TODO: Actually connect it
//  .done(),
//  .dbg_kw(),
//  .dbg_kh(),
//  .dbg_iw(),
//  .dbg_ih(),
//  .dbg_ic(),
//  .dbg_oc(),
//  .buffer_read_count(),
//  .stream_read_count(),
//  .inbuf_count(),
//  .pu_write_valid(),
//  .wr_cfg_idx(),
//  .rd_cfg_idx(),
//  .outbuf_push(),
//  .pu_controller_state(),
//  .vecgen_state(),
//  .vecgen_read_count(),
//  .mem_req0(),
//  .mem_req0_grant(),
//  .mem_req1(),
//  .mem_req1_grant(),
//  .mem_resp0(),
//  .mem_resp0_grant(),
//  .mem_resp1(),
//  .mem_resp1_grant(),
//  .l_inc()  
//);
//
//initial $display("instantiated");

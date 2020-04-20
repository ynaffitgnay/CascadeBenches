//
// Types used throughout the AMI memory system
//

`ifndef AMITYPES_SV_INCLUDED
`define AMITYPES_SV_INCLUDED

`include "common.vh"

parameter AMI_NUM_REAL_DNN = 4;
parameter AMI_NUM_APPS     = 8;
parameter AMI_NUM_PORTS    = 2;
parameter AMI_NUM_CHANNELS = 4;

parameter AMI_CHANNEL_BITS = (AMI_NUM_CHANNELS > 1 ? `C_LOG_2(AMI_NUM_CHANNELS) : 1);
parameter AMI_APP_BITS     = (AMI_NUM_APPS  > 1 ? `C_LOG_2(AMI_NUM_APPS)  : 1);
parameter AMI_PORT_BITS    = (AMI_NUM_PORTS > 1 ? `C_LOG_2(AMI_NUM_PORTS) : 1);

parameter AMI_ADDR_WIDTH = 64;
parameter AMI_DATA_WIDTH = 512 + 64;
parameter AMI_REQ_SIZE_WIDTH = 7; // enables 64 byte size

parameter USE_SOFT_FIFO = 1;
`define USE_SOFT_FIFO 1

parameter DISABLE_INTERLEAVE = 1'b0;

// TODO: Ensure these are sized so one app can not backup another
parameter ADDR_XLAT_Q_DEPTH       = (USE_SOFT_FIFO ? 3 : 9);
parameter ADDR_XLATED_Q_DEPTH     = (USE_SOFT_FIFO ? 3 : 9);
parameter CHANNEL_MERGE_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);
parameter RESP_MERGE_CHAN_Q_DEPTH = (USE_SOFT_FIFO ? 4 : 10)-1;
parameter RESP_MERGE_OUT_Q_DEPTH  = (USE_SOFT_FIFO ? 4 : 10)-1;
parameter RESP_MERGE_TAG_Q_DEPTH  = (USE_SOFT_FIFO ? 4 : 10)-1;
parameter CHAN_ARB_REQ_Q_DEPTH    = (USE_SOFT_FIFO ? 3 : 9);
parameter CHAN_ARB_TAG_Q_DEPTH    = (USE_SOFT_FIFO ? 3 : 9);
parameter CHAN_ARB_RESP_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);

parameter AMI2SDRAM_REQ_IN_Q_DEPTH  = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2SDRAM_RESP_IN_Q_DEPTH = (USE_SOFT_FIFO ? 3 : 9);

parameter AMI2DNN_MACRO_RD_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2DNN_MACRO_WR_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2DNN_REQ_Q_DEPTH        = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2DNN_WR_REQ_Q_DEPTH     = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2DNN_RESP_IN_Q_DEPTH    = (USE_SOFT_FIFO ? 3 : 9);
parameter AMI2DNN_READ_TAG_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);


parameter BLOCK_BUFFER_REQ_IN_Q_DEPTH   = (USE_SOFT_FIFO ? 3 : 9);
parameter BLOCK_BUFFER_RESP_OUT_Q_DEPTH = (USE_SOFT_FIFO ? 3 : 9);

`define AMI_ADDR_WIDTH 64
// TODO: maybe change AMI_DATA_WIDTH to just 512? I don't know why the 64 is there
`define AMI_DATA_WIDTH (512 + 64)
//`define AMI_DATA_WIDTH 512
`define AMI_REQ_SIZE_WIDTH 7

`define AMI_REQUEST_BUS_WIDTH  (1 + 1 + `AMI_ADDR_WIDTH + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIRequest_valid       0:0
`define AMIRequest_isWrite     1:1
`define AMIRequest_addr        (`AMI_ADDR_WIDTH + 2 - 1):2
`define AMIRequest_data        (`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_ADDR_WIDTH + 2)
`define AMIRequest_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2)

//typedef struct packed
//{
//    logic                          valid;
//    logic                          isWrite;
//    logic [AMI_ADDR_WIDTH-1:0]     addr;
//    logic [AMI_DATA_WIDTH-1:0]        data;
//    logic [AMI_REQ_SIZE_WIDTH-1:0] size;
//} AMIRequest;

`define AMI_RESPONSE_BUS_WIDTH  (1 + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIResponse_valid       0:0
`define AMIResponse_data        (`AMI_DATA_WIDTH + 1 - 1):1
`define AMIResponse_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + 1 - 1):(`AMI_DATA_WIDTH + 1)

//typedef struct packed {
//    logic                          valid;
//    logic [AMI_DATA_WIDTH-1:0]     data;
//    logic [AMI_REQ_SIZE_WIDTH-1:0] size;
//} AMIResponse;

`define DNNMICRORD_TAG_BUS_WIDTH  (1 + 32 + 20)
`define DNNMicroRdTag_valid       0:0
`define DNNMicroRdTag_addr        (32 + 1 - 1):1
`define DNNMicroRdTag_size        (20 + 32 + 1 - 1):(32 + 1)

//typedef struct packed {
//    logic          valid;
//    logic [31:0] addr;
//    logic [19:0]  size;
//} DNNMicroRdTag;


`define DNNWEAVER_MEMREQ_BUS_WIDTH  (1 + 1 + 32 + 20 + 10 + 64)
`define DNNWeaverMemReq_valid       0:0
`define DNNWeaverMemReq_isWrite     1:1
`define DNNWeaverMemReq_addr        (32 + 2 - 1):2
`define DNNWeaverMemReq_size        (20 + 32 + 2 - 1):(32 + 2)
`define DNNWeaverMemReq_pu_id       (10 + 20 + 32 + 2 - 1):(20 + 32 + 2)
`define DNNWeaverMemReq_time_stamp  (64 + 10 + 20 + 32 + 2 - 1):(10 + 20 + 32 + 2)

//typedef struct packed {
//    logic valid;
//    logic isWrite;
//    logic [31:0] addr;
//    logic [19:0]  size;
//    logic [9:0]  pu_id;
//    logic [63:0] time_stamp;
//} DNNWeaverMemReq;

`endif

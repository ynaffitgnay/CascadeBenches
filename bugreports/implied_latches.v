`define C_LOG_2(n) (\
(n) <= (1<<0) ? 0 : (n) <= (1<<1) ? 1 :\
(n) <= (1<<2) ? 2 : (n) <= (1<<3) ? 3 :\
(n) <= (1<<4) ? 4 : (n) <= (1<<5) ? 5 :\
(n) <= (1<<6) ? 6 : (n) <= (1<<7) ? 7 :\
(n) <= (1<<8) ? 8 : (n) <= (1<<9) ? 9 :\
(n) <= (1<<10) ? 10 : (n) <= (1<<11) ? 11 :\
(n) <= (1<<12) ? 12 : (n) <= (1<<13) ? 13 :\
(n) <= (1<<14) ? 14 : (n) <= (1<<15) ? 15 :\
(n) <= (1<<16) ? 16 : (n) <= (1<<17) ? 17 :\
(n) <= (1<<18) ? 18 : (n) <= (1<<19) ? 19 :\
(n) <= (1<<20) ? 20 : (n) <= (1<<21) ? 21 :\
(n) <= (1<<22) ? 22 : (n) <= (1<<23) ? 23 :\
(n) <= (1<<24) ? 24 : (n) <= (1<<25) ? 25 :\
(n) <= (1<<26) ? 26 : (n) <= (1<<27) ? 27 :\
(n) <= (1<<28) ? 28 : (n) <= (1<<29) ? 29 :\
(n) <= (1<<30) ? 30 : (n) <= (1<<31) ? 31 : 32)
//-----------------------------------------------------------


`define AMI_ADDR_WIDTH 64
`define AMI_DATA_WIDTH (512 + 64)
`define AMI_REQ_SIZE_WIDTH 6

`define AMI_REQUEST_BUS_WIDTH  (1 + 1 + `AMI_ADDR_WIDTH + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIRequest_valid       0:0
`define AMIRequest_isWrite     1:1
`define AMIRequest_addr        (`AMI_ADDR_WIDTH + 2 - 1):2
`define AMIRequest_data        (`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_ADDR_WIDTH + 2)
`define AMIRequest_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2)
`define AMI_RESPONSE_BUS_WIDTH  (1 + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIResponse_valid       0:0
`define AMIResponse_data        (`AMI_DATA_WIDTH + 1 - 1):1
`define AMIResponse_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + 1 - 1):(`AMI_DATA_WIDTH + 1)

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
    //wire[SECTOR_WIDTH-1:0] wrInput[NUM_SECTORS-1:0];
    //wire[SECTOR_WIDTH-1:0] rdInput[NUM_SECTORS-1:0];
    //wire[SECTOR_WIDTH-1:0] dataout[NUM_SECTORS-1:0];
    wire[(NUM_SECTORS*SECTOR_WIDTH)-1:0] wr_output;
    wire[NUM_SECTORS-1:0] sector_we;
    
    // Queue for incoming AMIRequests
    //wire             reqInQ_empty;
    //wire             reqInQ_full;
    //wire             reqInQ_enq;
    //reg              reqInQ_deq;
    //wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_in;
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_out;
    // necessary for doing bitslicing of AMIReq bus
    wire[`AMI_DATA_WIDTH - 1:0] reqInQ_out_data;  
    wire[`AMI_DATA_WIDTH - 1:0] respIn0_data;

    assign reqInQ_out_data = reqInQ_out[`AMIRequest_data];
    assign respIn0_data = respIn0[`AMIResponse_data];
    
    // Following signals will be controlled by the FSM
    reg inMuxSel; // 0 for RdInput, 1 for WrInput

    // Read data out of the block
    wire [SECTOR_WIDTH-1:0] rd_output;
    reg [`C_LOG_2(NUM_SECTORS)-1:0] rd_mux_sel; // controlled by the FSM

    //assign rd_output = dataout[rd_mux_sel];

    // Write enables per sector

    // FSM signals
    reg wr_all_sectors;
    reg wr_specific_sector;
    reg[`C_LOG_2(NUM_SECTORS)-1:0] wr_sector_index;
    
    we_decoder
    writes_decoder
    (
        .we_all      (wr_all_sectors),
        .we_specific (wr_specific_sector),
        .index       (wr_sector_index),
        .we_out      (sector_we)
    );

    
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
    
    wire[`AMI_ADDR_WIDTH - 1:0] reqInQ_out_addr;
    assign reqInQ_out_addr = reqInQ_out[`AMIRequest_addr];

    always @(*) begin
        // Signals controlling writing into the block
        inMuxSel           = 1'b0;
        wr_all_sectors     = 1'b0;
        wr_specific_sector = 1'b0;
        wr_sector_index    = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
        // mux out correct sector
        rd_mux_sel         = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
        // requests to the memory system
        // Read port
        reqOut0 = {6'd64, 512'b0, 64'b0, 1'b0, 1'b0};


        // Write port
        reqOut1 = {6'd64, 512'b0, 64'b0, 1'b0, 1'b0};

        // response from memory system
        respIn0_grant = 1'b0;
        respIn1_grant = 1'b0;

        // state control
        next_state = current_state;
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



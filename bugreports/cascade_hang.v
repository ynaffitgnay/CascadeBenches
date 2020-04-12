`ifndef __DNN2AMI_WRPath_sv__
`define __DNN2AMI_WRPath_sv__

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

`define DNNMICRORD_TAG_BUS_WIDTH  (1 + 32 + 20)
`define DNNMicroRdTag_valid       0:0
`define DNNMicroRdTag_addr        (32 + 1 - 1):1
`define DNNMicroRdTag_size        (20 + 32 + 1 - 1):(32 + 1)

`define DNNWEAVER_MEMREQ_BUS_WIDTH  (1 + 1 + 32 + 20 + 10 + 64)
`define DNNWeaverMemReq_valid       0:0
`define DNNWeaverMemReq_isWrite     1:1
`define DNNWeaverMemReq_addr        (32 + 2 - 1):2
`define DNNWeaverMemReq_size        (20 + 32 + 2 - 1):(32 + 2)
`define DNNWeaverMemReq_pu_id       (10 + 20 + 32 + 2 - 1):(20 + 32 + 2)
`define DNNWeaverMemReq_time_stamp  (64 + 10 + 20 + 32 + 2 - 1):(10 + 20 + 32 + 2)

module Counter64
(
  input               clk,
  input               rst, 
	input								increment,
	output[63:0]				count

);

	reg[31:0]  lower;
	reg[31:0]  upper;
	reg[31:0] new_lower;
	reg[31:0] new_upper;

	assign count = {upper,lower};
	
	always@(posedge clk) begin : counter64_update
		if (rst) begin
			lower <= 32'h0000_0000;
			upper <= 32'h0000_0000;
		end else begin
			lower <= new_lower;
			upper <= new_upper;
		end
	end

	always @(*) begin : counter64_update_logic

		new_lower = lower;
		new_upper = upper;

		if (increment) begin
			// check if overflow will occur
			if (lower == 32'hFFFF_FFFF) begin
				new_upper = upper + 32'h1;
				new_lower = 32'h0;
			end else begin
				new_lower = lower + 32'h1;
			end
		end

	end

endmodule // Counter64

module SoftFIFO  #(parameter WIDTH = 512, LOG_DEPTH = 9)
(
    // General signals
    input  clock,
    input  reset_n,
    // Data in and write enable
    input  wrreq, //enq                    
    input[WIDTH-1:0] data,// data in            
    output full,                   
    output[WIDTH-1:0] q, // data out
    output empty,              
    input  rdreq // deq    
);


reg [WIDTH-1:0] buffer[(1 << LOG_DEPTH)-1:0];

reg [LOG_DEPTH:0] counter;
reg [LOG_DEPTH:0]  new_counter;
reg [LOG_DEPTH-1:0] rd_ptr, wr_ptr; 
reg [LOG_DEPTH-1:0]  new_rd_ptr, new_wr_ptr;

assign empty = (counter == 0);
assign full  = (counter == (1 << LOG_DEPTH));
assign q     = buffer[rd_ptr];

always @(posedge clock) begin
    if (!reset_n) begin
        counter <= 0;
        rd_ptr  <= 0;
        wr_ptr  <= 0;
    end else begin
        counter <= new_counter;
        rd_ptr  <= new_rd_ptr;
        wr_ptr  <= new_wr_ptr;
    end
end

always @(posedge clock) begin
    if (!full && wrreq) begin
        buffer[wr_ptr] <= data;
    end else begin
        buffer[wr_ptr] <= buffer[wr_ptr];
    end
end

always @(*) begin
    if ((!full && wrreq) && (!empty && rdreq)) begin
        new_counter = counter;
        new_rd_ptr  = rd_ptr + 1;
        new_wr_ptr  = wr_ptr + 1;
    end else if (!full && wrreq) begin
        new_counter = counter + 1;
        new_rd_ptr  = rd_ptr;
        new_wr_ptr  = wr_ptr + 1;
    end else if (!empty && rdreq) begin
        new_counter = counter - 1;
        new_rd_ptr  = rd_ptr + 1;
        new_wr_ptr  = wr_ptr;
    end else begin
        new_counter = counter;
        new_rd_ptr = rd_ptr;
        new_wr_ptr = wr_ptr;
    end
end

endmodule // SoftFIFO



module DNN2AMI_WRPath
#(
  parameter integer NUM_PU               = 2,

  parameter integer AXI_ID               = 0,

  parameter integer TID_WIDTH            = 6,
  parameter integer AXI_ADDR_WIDTH       = 32,
  parameter integer AXI_DATA_WIDTH       = 64,
  parameter integer AWUSER_W             = 1,
  parameter integer ARUSER_W             = 1,
  parameter integer WUSER_W              = 1,
  parameter integer RUSER_W              = 1,
  parameter integer BUSER_W              = 1,

  /* Disabling these parameters will remove any throttling.
   The resulting ERROR flag will not be useful */
  parameter integer C_M_AXI_SUPPORTS_WRITE             = 1,
  parameter integer C_M_AXI_SUPPORTS_READ              = 1,

  /* Max count of written but not yet read bursts.
   If the interconnect/slave is able to accept enough
   addresses and the read channels are stalled, the
   master will issue this many commands ahead of
   write responses */

  // Base address of targeted slave
  //Changing read and write addresses
  parameter         C_M_AXI_READ_TARGET                = 32'hFFFF0000,
  parameter         C_M_AXI_WRITE_TARGET               = 32'hFFFF8000,

  // CUSTOM PARAMS
  parameter         TX_SIZE_WIDTH                      = 10,

  // Number of address bits to test before wrapping
  parameter integer C_OFFSET_WIDTH                     = TX_SIZE_WIDTH,
 
  parameter integer WSTRB_W  = AXI_DATA_WIDTH/8,
  parameter integer NUM_PU_W = `C_LOG_2(NUM_PU)+1,
  parameter integer OUTBUF_DATA_W = NUM_PU * AXI_DATA_WIDTH
 
)
(
    // General signals
    input                               clk,
    input                               rst,

    // Connection to rest of memory system
    output wire                         reqValid,
    input                               reqOut_grant,

    // Writes
    // WRITE from BRAM to DDR
    input  wire  [ NUM_PU               -1 : 0 ]        outbuf_empty, // no data in the output buffer
    input  wire  [ OUTBUF_DATA_W        -1 : 0 ]        data_from_outbuf,  // data to write from, portion per PU
    input  wire  [ NUM_PU               -1 : 0 ]        write_valid,       // value is ready to be written back
    output reg   [ NUM_PU               -1 : 0 ]        outbuf_pop,   // dequeue a data item, why is this registered?
    
    // Memory Controller Interface - Write
    input  wire                                         wr_req,   // assert when submitting a wr request
    input  wire  [ NUM_PU_W             -1 : 0 ]        wr_pu_id, // determine where to write, I assume ach PU has a different region to write
    input  wire  [ TX_SIZE_WIDTH        -1 : 0 ]        wr_req_size, // size of request in bytes (I assume)
    input  wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        wr_addr, // address to write to, look like 32 bit addresses
    output wire                                         wr_ready, // ready for more writes
    output wire                                         wr_done,  // no writes left to submit
    output [`AMI_REQUEST_BUS_WIDTH - 1:0]               reqOut
);

    genvar pu_num;

    // rename the inputs from the write buffer
    wire[AXI_DATA_WIDTH-1:0] pu_outbuf_data;
    assign pu_outbuf_data = data_from_outbuf[AXI_DATA_WIDTH - 1:0];
    
    // Counter for time  stamps
    wire[63:0] current_timestamp;
    Counter64
    time_stamp_counter
    (
        .clk (clk),
        .rst (rst), 
        .increment (1'b1),
        .count (current_timestamp)
    );    
    
    // Queue to buffer Write requests
    wire             macroWrQ_empty;
    wire             macroWrQ_full;
    wire            macroWrQ_enq;
    reg             macroWrQ_deq;
    wire[`DNNWEAVER_MEMREQ_BUS_WIDTH - 1:0]  macroWrQ_in;
    wire[`DNNWEAVER_MEMREQ_BUS_WIDTH - 1:0]  macroWrQ_out;

    SoftFIFO
    #(
        .WIDTH                    (`DNNWEAVER_MEMREQ_BUS_WIDTH),
        .LOG_DEPTH                (3)
    )
    macroWriteQ
    (
        .clock                    (clk),
        .reset_n                (~rst),
        .wrreq                    (macroWrQ_enq),
        .data                   (macroWrQ_in),
        .full                   (macroWrQ_full),
        .q                      (macroWrQ_out),
        .empty                  (macroWrQ_empty),
        .rdreq                  (macroWrQ_deq)
    );    

    // Inputs to the MacroWriteQ
    assign macroWrQ_in[`DNNWeaverMemReq_valid] = wr_req;
    assign macroWrQ_in[`DNNWeaverMemReq_isWrite] = 1'b1;
    assign macroWrQ_in[`DNNWeaverMemReq_addr] = wr_addr;
    assign macroWrQ_in[`DNNWeaverMemReq_size] = wr_req_size;
    assign macroWrQ_in[`DNNWeaverMemReq_pu_id] = wr_pu_id;
    assign macroWrQ_in[`DNNWeaverMemReq_time_stamp] = current_timestamp;
    assign macroWrQ_enq = wr_req && !macroWrQ_full;        

    // Debug  // TODO: comment this out
    always@(posedge clk) begin
        if (macroWrQ_enq) begin
            $display("DNN2AMI:============================================================ Accepting macro WRITE request ADDR: %h Size: %d ",wr_addr,wr_req_size);
        end
        if (wr_req) begin
            //$display("DNN2AMI: WR_req is being asserted, macroWrQ_enq: %d, macroWrQ_deq: %d", macroWrQ_enq, macroWrQ_deq);
            $display("DNN2AMI: WR_req is being asserted");
        end    
    end    
        
    // Two important output signals
    reg wr_done_reg;

    reg new_wr_done_reg;
    
    // Current macro request being sequenced (fractured into smaller operations)
    reg macro_req_active;
    reg[AXI_ADDR_WIDTH-1:0] current_address;
    reg[TX_SIZE_WIDTH-1:0]  requests_left;
    reg                     current_isWrite;
    reg[NUM_PU_W-1:0]       current_pu_id;

    reg new_macro_req_active;
    reg[AXI_ADDR_WIDTH-1:0] new_current_address;
    reg[TX_SIZE_WIDTH-1:0]  new_requests_left;
    reg                     new_current_isWrite;
    reg[NUM_PU_W-1:0]       new_current_pu_id;
    
    always@(posedge clk) begin
        if (rst) begin
            macro_req_active <= 1'b0;
            current_address  <= 0;
            requests_left    <= 0;
            current_isWrite  <= 1'b0;
            current_pu_id    <= 0;
        end else begin
            macro_req_active <= new_macro_req_active;
            current_address  <= new_current_address;
            requests_left    <= new_requests_left;
            current_isWrite  <= new_current_isWrite;
            current_pu_id    <= new_current_pu_id;
        end
    end

    assign wr_ready = (macroWrQ_empty && !macro_req_active);
    assign wr_done  = wr_done_reg;

    integer i = 0;
    
    wire not_macroWrQ_empty = !macroWrQ_empty;

    /* COMMENTED OUT THIS BLOCK TO KEEP WORKING ON OTHER CODE!! */
    /* Something seems weird about this always block, I guess */
    always @(*) begin      
        macroWrQ_deq          = 1'b0;
        new_macro_req_active  = macro_req_active;    
    
        /* SOMETHING ABOUT THIS ASSIGNMENT CAUSES CASCADE TO HANG!!! */
        new_wr_done_reg  = 1'b0;
                
        for (i = 0; i < NUM_PU; i = i + 1) begin
            outbuf_pop[i] = 1'b0;
        end
        
            // See if there is a new operation available
        if (!macroWrQ_empty) begin
            // A new operation can become active
            macroWrQ_deq = 1'b1;
            new_macro_req_active  = 1'b1;
        end
    end // always @ (*)

    // How the memory controller determines if a wr_request should be sent
    // assign wr_req = !wr_done && (wr_ready) && wr_state == WR_BUSY; //stream_wr_count_inc;
    //  wr_ready <= pu_wr_ready[wr_pu_id] && !(wr_req && wr_ready);
    // We issue a write for a PU when the PU has no writes remaining.
    // WR_DONE is asserted when all the PUs no writes remaining.
    always@(posedge clk) begin
        if (rst) begin
            wr_done_reg  <= 1'b0;
        end else begin
            wr_done_reg  <= new_wr_done_reg;
        end
    end
    
endmodule
`endif //  `ifndef __DNN2AMI_WRPath_sv__

reg wrReq;

initial $display("Start");


DNN2AMI_WRPath tdw
(
    .clk(clock.val),
    .rst(),

    .reqValid(),
    .reqOut_grant(),

    .outbuf_empty(), // no data in the output buffer
    .data_from_outbuf(),  // data to write from(), portion per PU
    .write_valid(),       // value is ready to be written back
    .outbuf_pop(),   // dequeue a data item(), why is this registered?
    
    .wr_req(wrReq),   // assert when submitting a wr request
    .wr_pu_id(), // determine where to write(), I assume ach PU has a different region to write
    .wr_req_size(), // size of request in bytes (I assume)
    .wr_addr(), // address to write to(), look like 32 bit addresses
    .wr_ready(), // ready for more writes
    .wr_done(),  // no writes left to submit
    .reqOut()
);

initial $display("Instantiated?");

initial wrReq = 1;

initial $display("Hello");















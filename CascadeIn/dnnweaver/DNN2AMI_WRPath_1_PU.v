`ifndef __DNN2AMI_WRPath_1_PU_v__
`define __DNN2AMI_WRPath_1_PU_v__

`include "AMITypes.sv"

`include "common.vh" // TODO: Uncomment when not testing
`include "Counter64.sv"
`include "SoftFIFO.sv"
`include "FIFO.sv"

module DNN2AMI_WRPath_1_PU
#(
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
  parameter integer NUM_PU_W = 1,
  parameter integer OUTBUF_DATA_W = AXI_DATA_WIDTH
 
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
    input  wire                                         outbuf_empty, // no data in the output buffer
    input  wire  [ OUTBUF_DATA_W        -1 : 0 ]        data_from_outbuf,  // data to write from, portion per PU
    input  wire                                         write_valid,       // value is ready to be written back
    output reg                                          outbuf_pop,   // dequeue a data item, why is this registered?
    
    // Memory Controller Interface - Write
    input  wire                                         wr_req,   // assert when submitting a wr request
    input  wire                                         wr_pu_id, // determine where to write, I assume ach PU has a different region to write
    input  wire  [ TX_SIZE_WIDTH        -1 : 0 ]        wr_req_size, // size of request in bytes (I assume)
    input  wire  [ AXI_ADDR_WIDTH       -1 : 0 ]        wr_addr, // address to write to, look like 32 bit addresses
    output wire                                         wr_ready, // ready for more writes
    output wire                                         wr_done,  // no writes left to submit
    output [`AMI_REQUEST_BUS_WIDTH - 1:0]               reqOut
);

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

    generate
        if (`USE_SOFT_FIFO) begin : SoftFIFO_macroWriteQ
            SoftFIFO
            #(
                .WIDTH                    (`DNNWEAVER_MEMREQ_BUS_WIDTH),
                .LOG_DEPTH                (AMI2DNN_MACRO_WR_Q_DEPTH)
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
        end else begin : FIFO_macroWriteQ
            FIFO
            #(
                .WIDTH                    (`DNNWEAVER_MEMREQ_BUS_WIDTH),
                .LOG_DEPTH                (AMI2DNN_MACRO_WR_Q_DEPTH)
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
        end
    endgenerate    

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
    
    // reqOut queue to simplify the sequencing logic
    wire             reqQ_empty;
    wire             reqQ_full;
    reg              reqQ_enq;
    wire             reqQ_deq;
    reg[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqQ_in;
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]      reqQ_out;

    generate
        if (`USE_SOFT_FIFO) begin : SoftFIFO_reqQ
            SoftFIFO
            #(
                .WIDTH                    (`AMI_REQUEST_BUS_WIDTH),
                .LOG_DEPTH                (AMI2DNN_WR_REQ_Q_DEPTH)
            )
            reqQ
            (
                .clock                    (clk),
                .reset_n                (~rst),
                .wrreq                    (reqQ_enq),
                .data                   (reqQ_in),
                .full                   (reqQ_full),
                .q                      (reqQ_out),
                .empty                  (reqQ_empty),
                .rdreq                  (reqQ_deq)
            );    
        end else begin : FIFO_reqQ
            FIFO
            #(
                .WIDTH                    (`AMI_REQUEST_BUS_WIDTH),
                .LOG_DEPTH                (AMI2DNN_WR_REQ_Q_DEPTH)
            )
            reqQ
            (
                .clock                    (clk),
                .reset_n                (~rst),
                .wrreq                    (reqQ_enq),
                .data                   (reqQ_in),
                .full                   (reqQ_full),
                .q                      (reqQ_out),
                .empty                  (reqQ_empty),
                .rdreq                  (reqQ_deq)
            );    
        end
    endgenerate        

    // Interface to the memory system
    assign reqValid = reqQ_out[`AMIRequest_valid] && !reqQ_empty;
    assign reqOut   = reqQ_out;
    assign reqQ_deq = reqOut_grant && reqValid;

    //// TODO: comment out
    //always@(posedge clk) begin
    //    if  (reqValid) begin
    //        $display("WR PATH: Req valid and size of reqQ is %d, grant: %d, reqQ_deq:  %d", SoftFIFO_reqQ.reqQ.counter,reqOut_grant,reqQ_deq);
    //    end
    //end

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

    assign wr_ready = (macroWrQ_empty && !macro_req_active && reqQ_empty);//wr_ready_reg;
    assign wr_done  = wr_done_reg;

    wire not_macroWrQ_empty = !macroWrQ_empty;

    /* COMMENTED OUT THIS BLOCK TO KEEP WORKING ON OTHER CODE!! */
    /* Something seems weird about this always block, I guess */
    always @(*) begin      
        macroWrQ_deq          = 1'b0;
        new_macro_req_active  = macro_req_active;
        new_current_address   = current_address;
        new_requests_left     = requests_left;
        new_current_isWrite   = current_isWrite;
        new_current_pu_id     = current_pu_id;
    
    
        /* SOMETHING ABOUT THIS ASSIGNMENT CAUSES CASCADE TO HANG!!! */
        new_wr_done_reg  = 1'b0;
        
        reqQ_enq = 1'b0;
        reqQ_in[`AMIRequest_valid] = 1'b0;
        reqQ_in[`AMIRequest_isWrite] = 1'b1;
        reqQ_in[`AMIRequest_addr] = {{32{1'b0}},current_address};
        reqQ_in[`AMIRequest_data] = pu_outbuf_data;
        reqQ_in[`AMIRequest_size] = 8; // double check this size
        
        outbuf_pop = 1'b0;
        
        // An operation is being sequenced
        if (macro_req_active) begin
            // issue write requests
            if (current_isWrite == 1'b1) begin
                if (!outbuf_empty && !reqQ_full) begin // TODO: Not sure about this write_valid signal
                    outbuf_pop = 1'b1;

                    reqQ_in[`AMIRequest_valid] = 1'b1;
                    reqQ_enq = 1'b1;
                    new_current_address = current_address + 8; // 8 bytes
                    new_requests_left   = requests_left - 1;

                    if ((requests_left - 1) == 0) begin
                        new_macro_req_active = 1'b0;
                        new_wr_done_reg = 1'b1;
                    end
                end
            end
            // check if anything is left to issue
            if (requests_left == 0) begin
                new_macro_req_active = 1'b0;
                new_wr_done_reg = 1'b1;
            end
        end // if (macro_req_active)
        else begin
            // See if there is a new operation available
            if (not_macroWrQ_empty) begin
                // A new operation can become active
                macroWrQ_deq = 1'b1;
                new_macro_req_active  = 1'b1;
                
                // Select the output of the arbiter
                new_current_address = macroWrQ_out[`DNNWeaverMemReq_addr];
                new_requests_left   = macroWrQ_out[`DNNWeaverMemReq_size];
                new_current_isWrite = macroWrQ_out[`DNNWeaverMemReq_isWrite];
                new_current_pu_id   = macroWrQ_out[`DNNWeaverMemReq_pu_id];        
            end
        end // else: !if(macro_req_active)
    end // always @ (*)



    //always@(posedge clk) begin
    //    if (wr_ready && !wr_done) begin
    //        $display("DNN2: XXXXXXXXXXXX Should be able to accept a new write XXXXXXXXXXXXXXX");
    //    end
    //end
    //
    //always@(posedge clk) begin
    //    if (!outbuf_empty && !outbuf_pop) begin
    //        $display("WRPATH: Should be popping but we're not ");
    //    end
    //    if (outbuf_pop) begin
    //        $display("WRPATH: Popping outbuf data, current addr: %h , %d requests left", new_current_address, new_requests_left);
    //    end
    //end
    //
    //always@(posedge clk) begin
    //    if (!outbuf_empty) begin
    //        //$display("WRPATH: outbuf_empty %d write_valid: %d, reqQ_full %d requests_left %d, current addr: %x",outbuf_empty,write_valid,reqQ_full, requests_left,current_address);
    //        $display("WRPATH: outbuf_empty %d write_valid: %d, reqQ_full %d, requests_left %d, current addr: %h",outbuf_empty,write_valid,reqQ_full, requests_left,current_address);
    //    end/* else begin
    //        $display("Outbuf empty");
    //    end */
    //
    //end


    //always @(posedge clk) begin
    //    $display("wr_done: %d, new_wr_done_reg: %d, requests_left: %d", wr_done, new_wr_done_reg, requests_left);
    //end

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
    
endmodule // DNN2AMI_WRPath_1_PU
`endif //  `ifndef __DNN2AMI_WRPath_1_PU_v__


//reg wrReq;
//
//initial $display("Start");
//DNN2AMI_WRPath_1_PU tdw
//(
//    .clk(clock.val),
//    .rst(),
//
//    .reqValid(),
//    .reqOut_grant(),
//
//    .outbuf_empty(), // no data in the output buffer
//    .data_from_outbuf(),  // data to write from(), portion per PU
//    .write_valid(),       // value is ready to be written back
//    .outbuf_pop(),   // dequeue a data item(), why is this registered//    
//    .wr_req(wrReq),   // assert when submitting a wr request
//    .wr_pu_id(), // determine where to write(), I assume ach PU has a different region to write
//    .wr_req_size(), // size of request in bytes (I assume)
//    .wr_addr(), // address to write to(), look like 32 bit addresses
//    .wr_ready(), // ready for more writes
//    .wr_done(),  // no writes left to submit
//    .reqOut()
//);
//
//initial $display("Instantiated?");
//
//initial wrReq = 1;


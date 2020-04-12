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
    input  wire                                         wr_req   // assert when submitting a wr request
);

    reg   [ NUM_PU               -1 : 0 ]        outbuf_pop;
        
    // Queue to buffer Write requests
    wire             macroWrQ_empty;
    wire             macroWrQ_full;
    wire            macroWrQ_enq;
    reg             macroWrQ_deq;
    wire[127:0]  macroWrQ_in;
    wire[127:0]  macroWrQ_out;

    SoftFIFO
    #(
        .WIDTH                    (127),
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

    always@(posedge clk) begin
        if (macroWrQ_enq) begin
            $display("DNN2AMI:============================================================ Accepting macro WRITE request "); // ADDR: %h Size: %d ",wr_addr,wr_req_size);
        end
        if (wr_req) begin
            $display("DNN2AMI: WR_req is being asserted");
        end    
    end    

    integer i = 0;
    
    wire not_macroWrQ_empty = !macroWrQ_empty;

    always @(*) begin      
        for (i = 0; i < NUM_PU; i = i + 1) begin
            outbuf_pop[i] = 1'b0;
        end
        
        // See if there is a new operation available
        if (!macroWrQ_empty) begin
        end
    end // always @ (*)
    
endmodule
`endif //  `ifndef __DNN2AMI_WRPath_sv__

reg wrReq;

initial $display("Start");


DNN2AMI_WRPath tdw
(
    .clk(clock.val),
    .rst(),
    .wr_req(wrReq)   // assert when submitting a wr request
);

initial $display("Instantiated?");

initial wrReq = 1;

initial $display("Hello");















`ifndef __DNN2AMI_WRPath_sv__
`define __DNN2AMI_WRPath_sv__

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
reg [LOG_DEPTH-1:0] rd_ptr;

assign empty = (counter == 0);
assign full  = (counter == (1 << LOG_DEPTH));
assign q     = buffer[rd_ptr];

endmodule // SoftFIFO



module DNN2AMI_WRPath
#(
  parameter integer NUM_PU               = 2 
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
        
        if (!macroWrQ_empty) begin
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
    .wr_req(wrReq)   // assert when submitting a wr request
);

initial $display("Instantiated?");

initial wrReq = 1;

initial $display("Hello");















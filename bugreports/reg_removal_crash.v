`define AMI_ADDR_WIDTH 64
`define AMI_DATA_WIDTH (512 + 64)
`define AMI_REQ_SIZE_WIDTH 6
`define AMI_REQUEST_BUS_WIDTH  (1 + 1 + `AMI_ADDR_WIDTH + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIRequest_valid       0:0
`define AMIRequest_isWrite     1:1
`define AMIRequest_addr        (`AMI_ADDR_WIDTH + 2 - 1):2
`define AMIRequest_data        (`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_ADDR_WIDTH + 2)
`define AMIRequest_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2)

module BlockBuffer
(
    // General signals
    input               clk
);
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_out;    

    // Read data out of the block
    //reg [2:0] rd_mux_sel;

    reg wr_specific_sector;
    
    wire[`AMI_ADDR_WIDTH - 1:0] reqInQ_out_addr;
    assign reqInQ_out_addr = reqInQ_out[`AMIRequest_addr];

    always @(*) begin
        // Signals controlling writing into the block
        wr_specific_sector = 1'b0;

        //rd_mux_sel         = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
    end // FSM state transitions
    
endmodule

BlockBuffer tbb(clock.val);

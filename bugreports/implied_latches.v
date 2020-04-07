`define AMI_ADDR_WIDTH 64
`define AMI_DATA_WIDTH (512 + 64)
`define AMI_REQ_SIZE_WIDTH 6
`define AMI_REQUEST_BUS_WIDTH  (1 + 1 + `AMI_ADDR_WIDTH + `AMI_DATA_WIDTH + `AMI_REQ_SIZE_WIDTH)
`define AMIRequest_valid       0:0
`define AMIRequest_isWrite     1:1
`define AMIRequest_addr        (`AMI_ADDR_WIDTH + 2 - 1):2
`define AMIRequest_data        (`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_ADDR_WIDTH + 2)
`define AMIRequest_size        (`AMI_REQ_SIZE_WIDTH + `AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2 - 1):(`AMI_DATA_WIDTH + `AMI_ADDR_WIDTH + 2)

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
    input               rst
);
    // Sectors
    wire[7:0] sector_we;
    
    // Queue for incoming AMIRequests
    wire[`AMI_REQUEST_BUS_WIDTH - 1:0]       reqInQ_out;    

    // Read data out of the block
    reg [2:0] rd_mux_sel; // controlled by the FSM

    // FSM signals
    reg wr_all_sectors;
    reg wr_specific_sector;
    /*-------------------------- VAR WE CARE ABOUT------------------------- */
    reg[2:0] wr_sector_index;
    //wire [2:0] wr_sector_index;
    
    we_decoder
    writes_decoder
    (
        .we_all      (wr_all_sectors),
        .we_specific (wr_specific_sector),
        .index       (wr_sector_index),
        .we_out      (sector_we)
    );

    
    wire[`AMI_ADDR_WIDTH - 1:0] reqInQ_out_addr;
    assign reqInQ_out_addr = reqInQ_out[`AMIRequest_addr];
    //assign wr_sector_index    = reqInQ_out_addr[5:3];

    always @(*) begin
        // Signals controlling writing into the block
        wr_all_sectors     = 1'b0;
        wr_specific_sector = 1'b0;
        wr_sector_index    = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
        // mux out correct sector
        rd_mux_sel         = reqInQ_out_addr[5:3]; // assume bits 2-0 are 0, 8 byte alignment
    end // FSM state transitions
    
endmodule

reg rst;
BlockBuffer tbb(clock.val, rst);

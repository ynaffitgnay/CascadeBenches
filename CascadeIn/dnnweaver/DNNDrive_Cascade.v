`include "AMITypes.sv"
`include "dw_params.vh"
`include "common.vh"
`include "dnnweaver_ami_top.sv"
`include "Counter64.sv"


module DNNDrive_Cascade #(
// ******************************************************************
// Parameters
// ******************************************************************
  parameter integer MEM_FILE          = "dnnweaver_mem.txt",
  parameter integer PU_TID_WIDTH      = 16,
  parameter integer AXI_TID_WIDTH     = 6,
  parameter integer NUM_PU            = `num_pu,
  parameter integer ADDR_W            = 32,
  parameter integer OP_WIDTH          = 16,
  parameter integer AXI_DATA_W        = 64,
  parameter integer NUM_PE            = `num_pe,
  parameter integer BASE_ADDR_W       = ADDR_W,
  parameter integer OFFSET_ADDR_W     = ADDR_W,
  parameter integer TX_SIZE_WIDTH     = 20,
  parameter integer RD_LOOP_W         = 32,
  parameter integer D_TYPE_W          = 2,
  parameter integer ROM_ADDR_W        = 3,
  parameter integer SERDES_COUNT_W    = 6,
  parameter integer PE_SEL_W          = `C_LOG_2(NUM_PE),
  parameter integer DATA_W            = NUM_PE * OP_WIDTH, // double check this
  parameter integer LAYER_PARAM_WIDTH  = 10
)
(
    // User clock and reset
    input                               clk,
    input                               rst
);

    // DNNWeaver signals
    wire  dnn_start;
    wire  dnn_done;
    
    wire l_inc;
    wire [ `AMI_REQUEST_BUS_WIDTH - 1 : 0 ] dnn_read_req;
    wire                                    dnn_read_req_grant;
    wire [ `AMI_REQUEST_BUS_WIDTH - 1 : 0 ] dnn_write_req;
    wire                                    dnn_write_req_grant;
    reg  [`AMI_RESPONSE_BUS_WIDTH - 1:0]    dnn_read_resp;
    wire                                    dnn_read_resp_grant;
    reg  [`AMI_RESPONSE_BUS_WIDTH - 1:0]    dnn_write_resp;
    wire                                    dnn_write_resp_grant;
    
    dnnweaver_ami_top #(
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
    ) real_accelerator_top ( // PORTS
        .clk                      ( clk                    ),
        .reset                    ( rst                    ),
        .start                    ( dnn_start              ),
        .done                     ( dnn_done               ),
        
        // Debug signals
        /*
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
        */
        // Memory signals
        .flush_buffer (1'b0), // TODO: Actually connect it
        .mem_req0(dnn_read_req),
        .mem_req0_grant(dnn_read_req_grant),
        .mem_req1(dnn_write_req),
        .mem_req1_grant(dnn_write_req_grant),
        .mem_resp0(dnn_read_resp),
        .mem_resp0_grant(dnn_read_resp_grant),
        .mem_resp1(dnn_write_resp),
        .mem_resp1_grant(dnn_write_resp_grant),                     
        .l_inc(l_inc)
    );

        
    // copied from memdrive
    // clk and debug counter
    wire[63:0] clk_counter;


    // Actually, want to use these to count the number of reads/writes to mem there are...
    reg[3:0] wr_count;
    reg[3:0] new_wr_count;
    
    // Counter
    reg[63:0]  start_cycle;
    reg        start_cycle_we;
    reg[63:0]  end_cycle;
    reg        end_cycle_we;
    
    Counter64 
    clk_counter64
    (
        .clk             (clk),
        .rst             (rst),
        .increment       (1'b1), // clock is always incrementing
        .count           (clk_counter)
    );
    
    //always@(posedge clk) begin : start_cycle_update
    //    if (rst) begin
    //        start_cycle  <= 64'h0;
    //        end_cycle    <= 64'h0;
    //    end else begin
    //        if (start_cycle_we) begin
    //            $display("Start cycle: %d", clk_counter);
    //            start_cycle <= clk_counter;
    //        end
    //        if (end_cycle_we) begin
    //            $display("Start cycle: %d, End cycle: %d, Total Cycles: %d", start_cycle, clk_counter, (clk_counter - start_cycle));
    //            end_cycle <= clk_counter;
    //        end
    //    end
    //end
 
    // FSM states
    parameter IDLE        = 4'b0000;
    parameter PROGRAMMING = 4'b0001;
    parameter REQUESTING  = 4'b0010;
    parameter AWAIT_RESP  = 4'b0011;
    parameter CLEAN_UP1   = 4'b0100;
    parameter CLEAN_UP2   = 4'b0101;
    parameter CLEAN_UP3   = 4'b0110;
    parameter CLEAN_UP4   = 4'b0111;
    parameter CLEAN_UP5   = 4'b1000;
    
    // FSM registers
    reg[3:0]   current_state;
    //reg[3:0]   next_state;

    
    // Start logic
    reg   initiate_start; 
    //reg   start_d;
    assign dnn_start = initiate_start;


    //always @(negedge clk) begin : start_update_logic
    //    if (rst) begin
    //        start_d <= 1'b0;
    //    end else begin
    //        if (initiate_start) begin
    //            start_d <= 1'b1;
    //        end else begin
    //            // always set it to low
    //            start_d <= 1'b0;
    //        end
    //    end
    //end

    
    // FSM update logic
    always @(posedge clk) begin
        if (rst) begin
            start_cycle  <= 64'h0;
            end_cycle    <= 64'h0;
            current_state <= IDLE;
            
        end

        
        case (current_state)
            IDLE : begin
                //if (!sr_inQ_empty) begin
                //    $display("Cycle %d DNNDrive %d: Starting programming", clk_counter, srcApp);
                //    next_state = PROGRAMMING;
                //    //next_state   = CLEAN_UP1;
                //end else begin
                //    next_state = IDLE;
                //end
                current_state <= REQUESTING;

            end

            REQUESTING : begin
                //start_cycle_we = 1'b1;
                start_cycle <= clk_counter;

                // Signify start
                initiate_start <= 1'b1;
                $display("Cycle %d: Starting and transitioning to AWAIT_RESP", clk_counter);

                // Go to await state
                current_state <= AWAIT_RESP;
            end

            AWAIT_RESP : begin
                // wait for the done signal to be asserted
                //if (dnn_done == 1'b1 || (lhc_enable[0] ? l_inc : 1'b0)) begin
                if (dnn_done == 1'b1) begin
                    //end_cycle_we = 1'b1;
                    end_cycle <= clk_counter;
                    $display("Cycle %d: DNNWeaver DONE. Total Cycles: %d", clk_counter, (clk_counter - start_cycle));

                    //next_state = IDLE;
                    current_state <= IDLE;
                end 
            end // case: AWAIT_RESP

            default : begin
            end
        endcase
    end // always @ (posedge clk)


    // Deal with reads and writes
    integer instream = $fopen("dnnweaver_mem.txt", "r");
    // Address to be read at (offset into mem file)
    wire[`AMI_ADDR_WIDTH - 1:0] read_addr;   // TODO: actually use this in reads
    // Data at address
    reg[`AMI_DATA_WIDTH - 1:0] read_data;
    // size should be the same as the request size
    wire[`AMI_REQ_SIZE_WIDTH - 1:0] read_size;
    // TODO: check if read_size is ever not 64. 
    // in which case you'll have to do some finagling to ensure that 
    // the SIZE most significant bits are what get read in

    integer outstream = $fopen("dnnweaver_mem.txt");
    wire[`AMI_ADDR_WIDTH - 1:0] write_addr;  // TODO: actually use this in writes
    // Need to make a register of each possible (8-byte aligned) size for writes...
    // And you're going to have to use them in a case statement or v. long if-else
    // based on what AMIRequest_size is
    // (you need to do this so that you don't overwrite anything beyond the write_size)
    wire[63:0] write_data_8_bytes;
    wire[127:0] write_data_16_bytes;
    wire[192:0] write_data_24_bytes;
    wire[255:0] write_data_32_bytes;
    wire[319:0] write_data_40_bytes;
    wire[383:0] write_data_48_bytes;
    wire[447:0] write_data_56_bytes;
    wire[511:0] write_data_64_bytes;
    


endmodule

initial $display("start");

reg rst;


DNNDrive_Cascade dnnc(clock.val, rst);

initial $display("instantiated");

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
    //reg  [`AMI_RESPONSE_BUS_WIDTH - 1:0]    dnn_read_resp;
    wire [`AMI_RESPONSE_BUS_WIDTH - 1:0]    dnn_read_resp;
    wire                                    dnn_read_resp_grant;
    wire  [`AMI_RESPONSE_BUS_WIDTH - 1:0]   dnn_write_resp;
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
    integer r_count;
    integer w_count;
    
    // Counter
    reg[63:0]  start_cycle;
    reg[63:0]  end_cycle;
    
    Counter64 
    clk_counter64
    (
        .clk             (clk),
        .rst             (rst),
        .increment       (1'b1), // clock is always incrementing
        .count           (clk_counter)
    );
     
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

    
    // Start logic
    reg   initiate_start; 
    //reg   start_d;
    assign dnn_start = initiate_start;

    
    // FSM update logic
    always @(posedge clk) begin
        if (rst) begin
            start_cycle  <= 64'h0;
            end_cycle    <= 64'h0;
            current_state <= IDLE;
        end else begin        
            case (current_state)
                IDLE : begin
                    // TODO: make this state more useful
                    current_state <= REQUESTING;
            
                end
            
                REQUESTING : begin
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
                        end_cycle <= clk_counter;
                        $display("Cycle %d: DNNWeaver DONE. Total Cycles: %d", clk_counter, (clk_counter - start_cycle));
            
                        current_state <= IDLE;
                    end 
                end // case: AWAIT_RESP
            
                default : begin
                end
            endcase // case (current_state)
        end // else: !if(rst)
    end // always @ (posedge clk)


    // Deal with reads and writes
    integer instream = $fopen("dnnweaver_mem.txt", "r");
    reg read_resp_valid;
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


    // Deal with reads
    assign dnn_read_req_grant = dnn_read_req[`AMIRequest_valid];
    assign read_addr = dnn_read_req[`AMIRequest_addr];
    assign read_size = dnn_read_req[`AMIRequest_size];
    assign dnn_read_resp = {read_size, read_data, read_resp_valid};

    always @ (posedge clk) begin
        if (rst) begin
            r_count <= 0;
            //dnn_read_resp[`AMIResponse_valid] <= 1'b0;
            read_resp_valid <= 1'b0;
        end else begin

            if (dnn_read_req[`AMIRequest_valid]) begin
                //// Mark the request as accepted
                //dnn_read_req_grant <= 1'b1;
                $display("Read request. Addr: %h, Size: %d", dnn_read_req[`AMIRequest_addr], dnn_read_req[`AMIRequest_size]);
                
                r_count <= r_count + 1;  // Should this only happen if !isWrite?
                
                if (dnn_read_req[`AMIRequest_isWrite]) begin
                    $display("Write request sent to read port. Ignored.");
                end else begin
                    // TODO: use variable offset
                    //$fseek(instream, read_addr, 0);
                    $fseek(instream, 100000, 0);
                    $fread(instream, read_data);
                    
                    if (dnn_read_req[`AMIRequest_size] != 64) begin
                        $display("Getting a read req of size %d", dnn_read_req[`AMIRequest_size]);
                    end

                    // Mark this response as valid
                    read_resp_valid <= 1'b1;
                end
            end else begin // if (dnn_read_req[`AMIRequest_valid])
                //dnn_read_resp[`AMIResponse_valid] <= 1'b0;
                read_resp_valid <= 1'b1;
            end // else: !if(dnn_read_req[`AMIRequest_valid])
        end // else: !if(rst)
    end


    // Deal with writes
    assign dnn_write_req_grant = dnn_write_req[`AMIRequest_valid];
    assign dnn_write_resp[`AMIResponse_valid] = 1'b0;
    assign write_addr = dnn_write_req[`AMIRequest_addr];

    // Assign each var to the corresponding least significant bytes of the request
    assign write_data_8_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_16_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_24_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_32_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_40_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_48_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_56_bytes = dnn_write_req[`AMIRequest_data];
    assign write_data_64_bytes = dnn_write_req[`AMIRequest_data];
    always @ (posedge clk) begin
        if (rst) begin
            w_count <= 0;
        end else begin
            if (dnn_write_req[`AMIRequest_valid]) begin
                $display("Write request. Addr: %h, Size: %d", dnn_write_req[`AMIRequest_addr], dnn_write_req[`AMIRequest_size]);

                w_count <= w_count + 1;

                if (!dnn_write_req[`AMIRequest_isWrite]) begin
                    $display("Read request sent to write port. Ignored.");
                end else begin
                    // TODO: use variable offset
                    //$fseek(outstream, write_addr, 0);
                    $fseek(outstream, 1000000, 0);

                    if (dnn_write_req[`AMIRequest_size] % 8 != 0) begin
                        $display("Write request size not a multiple of 8 bytes...");
                    end

                    case (dnn_write_req[`AMIRequest_size])
                      8 : begin
                          $fwrite(outstream, "%h", write_data_8_bytes);
                      end

                      16 : begin
                          $fwrite(outstream, "%h", write_data_16_bytes);
                      end

                      24 : begin
                          $fwrite(outstream, "%h", write_data_24_bytes);
                      end

                      32 : begin
                          $fwrite(outstream, "%h", write_data_32_bytes);
                      end

                      40 : begin
                          $fwrite(outstream, "%h", write_data_40_bytes);
                      end

                      48 : begin
                          $fwrite(outstream, "%h", write_data_48_bytes);
                      end

                      56 : begin
                          $fwrite(outstream, "%h", write_data_56_bytes);
                      end

                      64 : begin
                          $fwrite(outstream, "%h", write_data_64_bytes);
                      end

                      default : begin
                          $display("Write request for unexpected number of bytes");
                      end                      
                    endcase // case (dnn_write_req[`AMIRequest_size])

                    // Flush the outstream
                    $fflush(outstream);

                end
            end
        end
    end // always @ (posedge clk)

endmodule

initial $display("start");

reg rst;


DNNDrive_Cascade dnnc(clock.val, rst);

initial $display("instantiated");

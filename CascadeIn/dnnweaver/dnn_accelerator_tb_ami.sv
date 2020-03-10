`include "include/dw_params.vh"
`include "common.vh"

import ShellTypes::*;
import AMITypes::*;

module dnn_accelerator_tb_ami;

  localparam integer TID_WIDTH         = 6;
  localparam integer ADDR_W            = 32;
  localparam integer OP_WIDTH          = 16;
  localparam integer DATA_W            = 64;
  localparam integer NUM_PU            = `num_pu;
  localparam integer NUM_PE            = `num_pe;
  localparam integer BASE_ADDR_W       = ADDR_W;
  localparam integer OFFSET_ADDR_W     = ADDR_W;
  localparam integer TX_SIZE_WIDTH     = 20;
  localparam integer RD_LOOP_W         = 32;
  localparam integer D_TYPE_W          = 2;
  localparam integer ROM_ADDR_W        = 3;

  localparam integer LAYER_PARAM_WIDTH  = 10;
  
  localparam integer ROM_WIDTH = (BASE_ADDR_W + OFFSET_ADDR_W +
    RD_LOOP_W)*2 + D_TYPE_W;

  wire [ RD_LOOP_W            -1 : 0 ]        pu_id;
  wire [ D_TYPE_W             -1 : 0 ]        d_type;

  reg [324-1:0] mmap_ram[0:1023];

  wire                                        clk;
  wire                                        reset;
  reg                                         start;
  wire                                        done;
  wire                                        rd_req;
  wire                                        rd_ready;
  wire [ TX_SIZE_WIDTH        -1 : 0 ]        rd_req_size;
  wire [ TX_SIZE_WIDTH        -1 : 0 ]        rd_rvalid_size;
  wire [ ADDR_W               -1 : 0 ]        rd_addr;
  wire                                        wr_req;
  wire                                        wr_done;
  wire [ ADDR_W               -1 : 0 ]        wr_addr;
  wire [ TX_SIZE_WIDTH        -1 : 0 ]        wr_req_size;

  integer read_count;
  integer write_count;

 /* initial begin
    $dumpfile("dnn_accelerator_tb.vcd");
    $dumpvars(0,dnn_accelerator_tb_ami);
  end
*/
  reg [2-1:0] _l_type;
  reg [TX_SIZE_WIDTH-1:0] _stream_rvalid_size;
  reg [BASE_ADDR_W-1:0] _stream_rd_base_addr;
  reg [TX_SIZE_WIDTH-1:0] _stream_rd_size;
  reg [OFFSET_ADDR_W-1:0] _stream_rd_offset;
  reg [RD_LOOP_W-1:0] _stream_rd_loop_ic;
  reg [RD_LOOP_W-1:0] _stream_rd_loop_oc;
  reg [TX_SIZE_WIDTH-1:0] _buffer_rvalid_size;
  reg [BASE_ADDR_W-1:0] _buffer_rd_base_addr;
  reg [TX_SIZE_WIDTH-1:0] _buffer_rd_size;
  reg [OFFSET_ADDR_W-1:0] _buffer_rd_offset;
  reg [RD_LOOP_W-1:0] _buffer_rd_loop_max;

  integer max_layers;
  integer rom_idx;
  integer ddr_idx;
  integer tmp;

  integer ii, jj;


// AMI Stuff

    // Simple Dram instances
    MemReq  sd_mem_req_in[AMI_NUM_CHANNELS-1:0];
    MemResp sd_mem_resp_out[AMI_NUM_CHANNELS-1:0];
    wire    sd_mem_resp_grant_in[AMI_NUM_CHANNELS-1:0];
    wire    sd_mem_req_grant_out[AMI_NUM_CHANNELS-1:0];

    genvar channel_num;
    generate
        for (channel_num = 0; channel_num < AMI_NUM_CHANNELS; channel_num = channel_num + 1) begin: sd_inst
            SimSimpleDram
            #(
                .DATA_WIDTH(512), // 64 bytes (512 bits)
                .LOG_SIZE(10),
                .LOG_Q_SIZE(4)
            )
            simpleDramChannel
            (
                .clk(clk),
                .rst(reset),
                .mem_req_in(sd_mem_req_in[channel_num]),
                .mem_req_grant_out(sd_mem_req_grant_out[channel_num]),
                .mem_resp_out(sd_mem_resp_out[channel_num]),
                .mem_resp_grant_in(sd_mem_resp_grant_in[channel_num])
            );
        end
    endgenerate

    // From apps to AMI
    reg         app_enable[AMI_NUM_APPS-1:0];
    reg         port_enable[AMI_NUM_APPS-1:0][AMI_NUM_PORTS-1:0];
    AMIRequest  mem_req_in[AMI_NUM_APPS-1:0][AMI_NUM_PORTS-1:0];
    wire        mem_resp_grant_in[AMI_NUM_APPS-1:0][AMI_NUM_PORTS-1:0];
    
    // From AMI to apps
    wire        mem_req_grant_out[AMI_NUM_APPS-1:0][AMI_NUM_PORTS-1:0];    
    AMIResponse mem_resp_out[AMI_NUM_APPS-1:0][AMI_NUM_PORTS-1:0];
    
    AmorphOSMem2SDRAM ami_mem_system
    (
    // User clock and reset
        .clk(clk),
        .rst(reset),
        // Enable signals
        .app_enable (app_enable),
        .port_enable (port_enable),
        // SimpleDRAM interface to the apps
        // Submitting requests
        .mem_req_in(mem_req_in),
        .mem_req_grant_out(mem_req_grant_out),
        // Reading responses
        .mem_resp_out(mem_resp_out),
        .mem_resp_grant_in(mem_resp_grant_in),
        // Interface to SimpleDRAM modules per channel
        .ch2sdram_req_out(sd_mem_req_in),
        .ch2sdram_req_grant_in(sd_mem_req_grant_out),
        .ch2sdram_resp_in(sd_mem_resp_out),
        .ch2sdram_resp_grant_out(sd_mem_resp_grant_in)
    );

    initial begin
        app_enable[0] = 1'b1;
        port_enable[0][0] = 1'b1;
        port_enable[0][1] = 1'b1;    
    end
    
    
// End AMI Stuff  
  
  always @(posedge clk)
    if (reset || start)
      read_count <= 0;
    // else if (M_AXI_RVALID && M_AXI_RREADY)
    else if ((mem_req_in[0][0].valid && mem_req_grant_out[0][0] && !mem_req_in[0][0].isWrite) || (mem_req_in[0][1].valid && mem_req_grant_out[0][1] && !mem_req_in[0][1].isWrite))  
      read_count <= read_count + 1;

  always @(posedge clk)
    if (reset || start)
      write_count <= 0;
    //else if (M_AXI_WVALID && M_AXI_WREADY)
    else if ((mem_req_in[0][1].valid && mem_req_grant_out[0][0] && mem_req_in[0][0].isWrite) || (mem_req_in[0][1].valid && mem_req_grant_out[0][1] && mem_req_in[0][1].isWrite))  
      write_count <= write_count + 1;
  
// ==================================================================
  clk_rst_driver
  clkgen(
    .clk                      ( clk                      ),
    .reset_n                  (                          ),
    .reset                    ( reset                    )
  );
// ==================================================================
    
// ==================================================================
// DnnWeaver
//
// Debug signals
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_kw;
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_kh;
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_iw;
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_ih;
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_ic;
   wire [ LAYER_PARAM_WIDTH                   -1 : 0 ]        dbg_oc;

   wire [ 32                   -1 : 0 ]        buffer_read_count;
   wire [ 32                   -1 : 0 ]        stream_read_count;
   wire [ 11                   -1 : 0 ]        inbuf_count;
   wire [ NUM_PU               -1 : 0 ]        pu_write_valid;
   wire [ ROM_ADDR_W           -1 : 0 ]        wr_cfg_idx;
   wire [ ROM_ADDR_W           -1 : 0 ]        rd_cfg_idx;
   wire [ NUM_PU               -1 : 0 ]        outbuf_push;

   wire [ 3                    -1 : 0 ]        pu_controller_state;
   wire [ 2                    -1 : 0 ]        vecgen_state;
   wire [ 16                   -1 : 0 ]        vecgen_read_count;

// ==================================================================
  dnnweaver_ami_top #(
  // INPUT PARAMETERS
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
  ) accelerator ( // PORTS
    .clk                      ( clk                      ),
    .reset                    ( reset                    ),
    .start                    ( start                    ),
    .done                     ( done                     ),

    // Debug signals
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
    // Memory signals
    .flush_buffer (1'b0), // TODO: Actually connect it
    .mem_req(mem_req_in[0]),
    .mem_req_grant(mem_req_grant_out[0]),
    .mem_resp(mem_resp_out[0]),
    .mem_resp_grant(mem_resp_grant_in[0])
  );
// ==================================================================



assign rd_req = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.rd_req;
assign rd_req_size = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.rd_req_size;

assign wr_done = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.wr_done;
assign wr_req = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.wr_req;
assign wr_req_size = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.wr_req_size;
assign wr_addr = dnn_accelerator_tb_ami.accelerator.accelerator_inst.mem_ctrl_top.wr_addr;

wire wr_flush;

// ==================================================================
  dnn_accelerator_tb_driver_ami #(
  // INPUT PARAMETERS
    .NUM_PE                   ( NUM_PE                   ),
    .NUM_PU                   ( NUM_PU                   ),
    .ADDR_W                   ( ADDR_W                   ),
    .BASE_ADDR_W              ( BASE_ADDR_W              ),
    .OFFSET_ADDR_W            ( OFFSET_ADDR_W            ),
    .RD_LOOP_W                ( RD_LOOP_W                ),
    .TX_SIZE_WIDTH            ( TX_SIZE_WIDTH            ),
    .D_TYPE_W                 ( D_TYPE_W                 ),
    .ROM_ADDR_W               ( ROM_ADDR_W               )
  ) driver ( // PORTS
    .clk                      ( clk                      ),
    .reset                    ( reset                    ),
    .start                    ( start                    ),
    .done                     ( done                     ),
    .rd_req                   ( rd_req                   ),
    .rd_ready                 (                          ),
    .rd_req_size              ( rd_req_size              ),
    .rd_addr                  ( rd_addr                  ),
    .wr_req                   ( wr_req                   ),
    .wr_done                  ( wr_done                  ),
    .wr_req_size              ( wr_req_size              ),
    .wr_addr                  ( wr_addr                  ),
    .wr_flush                 ( wr_flush)
  );

// ==================================================================

localparam integer ADDR_SIZE_W = ADDR_W + TX_SIZE_WIDTH;

reg [ADDR_SIZE_W-1:0] buffer [0:1023];
integer rd_ptr;
integer wr_ptr;
initial begin
  rd_ptr = 0;
  wr_ptr = 0;
end

always @(posedge clk)
  if (wr_req)
    put_addr_size;

always @(posedge clk)
  if (wr_done)
    get_addr_size;

task put_addr_size;
  reg [ADDR_W-1:0] addr;
  reg [TX_SIZE_WIDTH-1:0] tx_size;
  begin
    addr = wr_addr;
    tx_size = wr_req_size;
    buffer[wr_ptr] = {addr, tx_size};
    {addr, tx_size} = buffer[wr_ptr];
    wr_ptr = wr_ptr + 1;
    //$display ("Write pointer = %d", wr_ptr);
    //$display ("Requesting %d transactions at addr = %h", tx_size, addr);
  end
endtask

task get_addr_size;
  integer num_writes_finished;
  reg [ADDR_W-1:0] addr;
  reg [TX_SIZE_WIDTH-1:0] tx_size;
  begin
    num_writes_finished = wr_ptr - rd_ptr;
    repeat (num_writes_finished) begin
      {addr, tx_size} = buffer[rd_ptr];
      //$display("Finished %d transactions at address %h",
        //tx_size, addr);
      print_mem(addr, tx_size);
      rd_ptr = rd_ptr+1;
    //$display ("Read pointer = %d", rd_ptr);
    end
  end
endtask

task print_mem;
  input [ADDR_W-1:0] addr;
  input [TX_SIZE_WIDTH-1:0] tx_size;
  integer ii;
  reg signed [16-1:0] tmp;
  begin
    addr = (addr-32'h08000000)>>1;
    $display("Printing memory at address %h", addr);
    for (ii=0; ii<tx_size*4; ii=ii+1) begin
      tmp = 1;//u_axim_driver.ddr_ram[addr+ii];
      $write("%6d ", tmp);
      if (ii%4==3) $display;
    end
    $display;
  end
endtask

integer in_addr;
integer in_dim[0:3];
integer w_addr;
integer w_dim[0:3];
integer num_layers;
integer l_count;
reg [4-1:0] l_type;
integer tmp_var;
integer tmp_var2;
initial begin
  $display("Getting MMAP from file ./hardware/include/tb_mmap.txt");
  $readmemb("./include/tb_mmap.vh", mmap_ram);
  num_layers = mmap_ram[0];
  for (l_count=0; l_count<num_layers; l_count=l_count+1)
  begin
    {l_type, in_addr, in_dim[0], in_dim[1], in_dim[2], in_dim[3], w_addr, w_dim[0], w_dim[1], w_dim[2], w_dim[3]} = mmap_ram[l_count+1];

    $display("*********************");
    $display("Layer Number %d", l_count);
    $display("Layer Type %d", l_type);

    $display("Input address = %h", in_addr);
    $display("Input size = %d x %d x %d x %d", in_dim[0], in_dim[1], in_dim[2], in_dim[3]);

    $display("Weight address = %h", w_addr);
    $display("Weight size = %d x %d x %d x %d", w_dim[0], w_dim[1], w_dim[2], w_dim[3]);
    $display("*********************");

    if (l_type == 0 && l_count == 0) begin
      initialize_stream(in_addr, in_dim[0], in_dim[1], in_dim[2], in_dim[3]);
      initialize_buffer(w_addr, w_dim[0], w_dim[1], w_dim[2], w_dim[3], 4);
    end
    else if (l_type == 1) begin
      initialize_buffer(in_addr, in_dim[0], in_dim[1], in_dim[2], in_dim[3], 0);
      tmp_var =  (w_dim[2] < NUM_PE ? 1 : w_dim[2] % NUM_PE == 0 ? w_dim[2]/NUM_PE : w_dim[2]/NUM_PE+1);
      tmp_var2 = ((w_dim[0] < NUM_PE ? 1 : w_dim[0] % NUM_PE == 0 ? w_dim[0]/NUM_PE : w_dim[0]/NUM_PE+1) )*NUM_PE;
      initialize_stream(w_addr, 1, 1, tmp_var2, w_dim[2]+1);
    end

  end
end

task initialize_stream;
  input integer addr;
  input integer dim0;
  input integer dim1;
  input integer dim2;
  input integer dim3;
  integer d0, d1, d2, d3;
  integer offset;
  integer d2_padded;
  integer val;
  begin
    $display("Initializing stream data at %h", addr);
    $display("Stream dimensions %d, %d, %d, %d", dim0, dim1, dim2, dim3);
    d2_padded = (dim2 < NUM_PE ? 1 : dim2 % NUM_PE == 0 ? dim2/NUM_PE : dim2/NUM_PE+1)  * (NUM_PE < 4 ? 1 : NUM_PE % 4 == 0 ? NUM_PE/4 : NUM_PE/4+1)  * 4;
                                                                        

    addr = (addr - 32'h08000000) >> 1;
    $display("Padded dimensions = %d", d2_padded);
    for (d0=0; d0<1; d0=d0+1) begin
      for (d1=0; d1<dim1; d1=d1+1) begin
        for (d3=0; d3<dim3; d3=d3+1) begin
          for (d2=0; d2<d2_padded; d2=d2+1) begin
            offset = d2+d2_padded*(d3 + dim3 * d1);
            if (d2 < dim2)
              val = d2+dim2*(d3);
            else
              val = 0;
            //u_axim_driver.ddr_ram[addr+offset] = val;
            //$display("Address %h: Value: %d", addr+offset, val);
          end
        end
      end
    end
  end
endtask

task initialize_buffer;
  input integer addr;
  input integer dim0;
  input integer dim1;
  input integer dim2;
  input integer dim3;
  input integer bias_size;
  integer d0, d1, d2, d3;
  integer offset, val;
  integer wlen;
  begin
    $display("Initializing buffer data at %h", addr);
    $display("Buffer dimensions %d, %d, %d, %d", dim0, dim1, dim2, dim3);
    addr = (addr-32'h08000000)>>1; 
    wlen = ((dim2*dim3) < 4 ? 1 : (dim2*dim3) % 4 == 0 ? (dim2*dim3)/4 : (dim2*dim3)/4+1) *4+bias_size; //  
    //d1 = input channels
    //d0 = output channels
    for (d1=0; d1<dim1; d1=d1+1) begin
      for (d0=0; d0<dim0; d0=d0+1) begin
        for (d2=0; d2<wlen; d2=d2+1) begin
          offset = d2+wlen*(d1+dim1*d0);
          if (d2 >= bias_size)
            val = d2-bias_size;
          else
            val = 0;
         // u_axim_driver.ddr_ram[addr+offset] = val;
          //$display("Address %h: Value: %d", addr+offset, val);
        end
      end
    end
  end
endtask

  initial begin
    driver.status.start;
    max_layers = `max_layers;

    rom_idx = 0;

    repeat (2) begin
      wait(accelerator.accelerator_inst.u_controller.state == 0);
      driver.send_start;
      wait(accelerator.accelerator_inst.u_controller.state == 4)
      wait(accelerator.accelerator_inst.u_controller.state == 0);
      wait(accelerator.accelerator_inst.mem_ctrl_top.u_mem_ctrl.done);
      repeat(100) begin
        @(negedge clk);
      end
      $display("Read count = %d\nWrite_count = %d", read_count, write_count);
    end
    driver.status.test_pass;
  end

endmodule

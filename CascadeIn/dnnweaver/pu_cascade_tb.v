 /** This module tests the PU module
   * The testbench instantiates the driver
   * and the PU module */
`include "common.vh"
`include "dw_params.vh"
module PU_tb;
// ******************************************************************
// local parameters
// ******************************************************************
  localparam integer NUM_PE             = `num_pe;
  localparam integer OP_WIDTH           = 16;
  localparam integer DATA_WIDTH         = NUM_PE * OP_WIDTH;
  localparam integer TID_WIDTH          = 16;
  localparam integer PAD_WIDTH          = 3;
  localparam integer STRIDE_SIZE_W      = 3;
  localparam integer LAYER_PARAM_WIDTH  = 10;
  localparam integer L_TYPE_WIDTH       = 2;

  localparam integer PE_CTRL_WIDTH      = 10 + 2*PE_BUF_ADDR_WIDTH;
  localparam integer PE_BUF_ADDR_WIDTH  = 10;
  localparam integer VECGEN_CTRL_W      = 9;
  localparam integer WR_ADDR_WIDTH      = 7;
  localparam integer RD_ADDR_WIDTH      = WR_ADDR_WIDTH+`C_LOG_2(NUM_PE);
  localparam integer PE_OP_CODE_WIDTH   = 3;
  localparam integer DATA_IN_WIDTH      = OP_WIDTH * NUM_PE;
  localparam integer VECGEN_CFG_W       = STRIDE_SIZE_W + PAD_WIDTH;
  localparam integer D_TYPE_W           = 2;
  localparam integer POOL_CTRL_WIDTH    = 7;
  localparam integer POOL_CFG_WIDTH     = 3;
  localparam integer SERDES_COUNT_W     = 6;

  localparam integer PE_SEL_W           = `C_LOG_2(NUM_PE);
// ******************************************************************
// IO
// ******************************************************************

  wire                                        pe_neuron_bias;
  wire [ PE_SEL_W             -1 : 0 ]        pe_neuron_sel;
  wire                                        pe_neuron_read_req;

  wire [ DATA_WIDTH           -1 : 0 ]        pu_data_out;
  reg  [ DATA_WIDTH           -1 : 0 ]        pu_data_in;
  reg                                         pu_data_in_v;
  reg                                         start;
  wire [ SERDES_COUNT_W       -1 : 0 ]        pu_serdes_count;
  wire [ PE_CTRL_WIDTH        -1 : 0 ]        pe_ctrl;
  wire [ RD_ADDR_WIDTH        -1 : 0 ]        wb_read_addr;
  wire pu_rd_req;
  //-----------vectorgen-----------
  wire [ DATA_IN_WIDTH        -1 : 0 ]        vecgen_rd_data;
  wire                                        vecgen_rd_req;
  wire                                        vecgen_rd_ready;
  wire [ VECGEN_CTRL_W        -1 : 0 ]        vecgen_ctrl;
  wire [ VECGEN_CFG_W         -1 : 0 ]        vecgen_cfg;
  wire                                        vecgen_ready;
  wire [ DATA_IN_WIDTH        -1 : 0 ]        vecgen_wr_data;
  wire                                        vecgen_wr_valid;
  wire [ NUM_PE               -1 : 0 ]        vecgen_mask;

  // PU Source and Destination Select
  wire [ `SRC_0_SEL_WIDTH     -1 : 0 ]        src_0_sel;
  wire [ `SRC_1_SEL_WIDTH     -1 : 0 ]        src_1_sel;
  wire [ `SRC_2_SEL_WIDTH     -1 : 0 ]        src_2_sel;
  wire [ `OUT_SEL_WIDTH       -1 : 0 ]        out_sel;
  wire [ `DST_SEL_WIDTH       -1 : 0 ]        dst_sel;

  //Pooling
  wire [ POOL_CTRL_WIDTH      -1 : 0 ]        pool_ctrl;
  wire [ POOL_CFG_WIDTH       -1 : 0 ]        pool_cfg;
// ******************************************************************
// Driver
// ******************************************************************
 /** Driver for the PU tests
   * Generates inputs and tests output */
  reg [63:0] buffer_read_data_out;
  reg buffer_read_empty;
  reg buffer_read_data_valid;
  reg buffer_read_last;
  reg pass;
  reg fail;

  
  
  //PU_tb_driver #(
  //  .OP_WIDTH                 ( OP_WIDTH                 ),
  //  .NUM_PE                   ( NUM_PE                   )
  //) driver (
  //  .clk                      ( clk                      ),
  //  .reset                    ( reset                    ),
  //  .buffer_read_data_valid   ( buffer_read_data_valid   ), //output
  //  .buffer_read_data_out     ( buffer_read_data_out     ), //output
  //  .buffer_read_empty        ( buffer_read_empty        ), //output
  //  .buffer_read_req          ( buffer_read_req          ), //input
  //  .buffer_read_last         ( buffer_read_last         ), //output
  //  .pu_rd_req                ( pu_rd_req                 ),
  //  .pu_rd_ready              ( pu_rd_ready              ),
  //  .pu_wr_req                ( pu_wr_req              ),
  //  .pu_data_out              ( pu_data_out              ),
  //  .pu_data_in               ( pu_data_in               ),
  //  .pass                     ( pass                     ),
  //  .fail                     ( fail                     )
  //);

  /* Internal vars to PU_driver */
  reg signed  [OP_WIDTH-1:0] data_in  [0:1<<20];
  reg signed  [OP_WIDTH-1:0] weight   [0:1<<20];
  reg signed  [OP_WIDTH-1:0] buffer   [0:1<<20];
  reg signed  [OP_WIDTH-1:0] expected_out [0:1<<20];
  reg signed  [OP_WIDTH-1:0] expected_pool_out [0:1<<20];
  integer expected_writes;
  integer output_fm_size;
  reg signed [OP_WIDTH-1:0] norm_lut [1<<6:0];

  integer lutstream = $fopen("input_files/dnnweaver/norm_lut.mif", "r");
  integer idx = 0;
  reg[OP_WIDTH-1:0] val = 0;

  reg rd_ready;
  integer max_data_in_count;
  integer data_in_counter;
  integer write_count;
  integer delay_count;
  

  /* Init mem */
  initial begin
    //$readmemb ("hardware/include/norm_lut.vh", norm_lut);
    for (idx = 0; idx < (1<<6); idx = idx + 1) begin
      if (!($feof(lutstream))) begin
        $fscanf(lutstream, "%b", val);
        norm_lut[idx] = val;  
      end 
      else begin
        norm_lut[idx] = 0;
      end // else: !if(!($feof(lutstream)))
    end // for (i = 0; i < ROM_DEPTH; i = i + 1)

    data_in_counter = 0;
    rd_ready = 0;
    write_count = 0;
    delay_count = 0;

    buffer_read_data_valid = 0;
    buffer_read_last = 1'b0;
    buffer_read_empty = 1'b1;
  end // initial begin
  
  /* Test config */
  integer input_fm_dimensions  [3:0];
  integer input_fm_size;
  integer output_fm_dimensions [3:0];
  integer pool_fm_dimensions [3:0];
  integer weight_dimensions    [4:0];
  integer buffer_dimensions[4:0];
  reg pool_enabled;

  /* expected_pooling_output vars */
  integer epo_pool_w;  /* input */
  integer epo_pool_h;  /* input */
  integer epo_stride;  /* input */
  integer epo_iw, epo_ih, epo_ic;
  integer epo_ow, epo_oh;
  integer epo_ii, epo_jj;
  integer epo_kk, epo_ll;
  integer epo_output_index, epo_input_index;
  integer epo_max;
  integer epo_in_w, epo_in_h;
  integer epo_tmp;

  /* print_pooled_output vars */
  integer ppoo_w, ppoo_h;

  /* print_pe_output vars */
  integer ppeo_w, ppeo_h;

  /* expected_output_fc vars */
  integer eofc_input_channels;  /* input */
  integer eofc_output_channels;  /* input */
  integer eofc_max_threads;  /* input */
  integer eofc_ic, eofc_oc;
  integer eofc_input_index, eofc_output_index, eofc_kernel_index;
  integer eofc_in;
  reg signed [48-1:0] eofc_acc;

  /* expected_output_norm vars */
  integer eon_input_width;  /* input */
  integer eon_input_height;  /* input */
  integer eon_input_channels;  /* input */
  integer eon_batchsize;  /* input */
  integer eon_kernel_width;  /* input */
  integer eon_kernel_height;  /* input */
  integer eon_kernel_stride;  /* input */
  integer eon_output_channels;  /* input */
  integer eon_pad_w;  /* input */
  integer eon_pad_r_s;  /* input */
  integer eon_pad_r_e;  /* input */
  integer eon_output_width;
  integer eon_output_height;
  integer eon_iw, eon_ih, eon_ic, eon_b, eon_kw, eon_kh, eon_ow, eon_oh;
  integer eon_input_index, eon_output_index, eon_kernel_index;
  integer eon_in, eon_in_w, eon_in_h;
  reg [6-1:0] eon_lrn_weight_index;


  /* expected_output vars */
  integer eo_input_width;  /* input */
  integer eo_input_height;  /* input */
  integer eo_input_channels;  /* input */
  integer eo_batchsize;  /* input */
  integer eo_kernel_width;  /* input */
  integer eo_kernel_height;  /* input */
  integer eo_kernel_stride;  /* input */
  integer eo_output_channels;  /* input */
  integer eo_pad_w;  /* input */
  integer eo_pad_r_s;  /* input */
  integer eo_pad_r_e;  /* input */
  integer eo_output_width;
  integer eo_output_height;
  integer eo_iw, eo_ih, eo_ic, eo_b, eo_kw, eo_kh, eo_ow, eo_oh;
  integer eo_input_index, eo_output_index, eo_kernel_index;
  integer eo_in, eo_in_w, eo_in_h;

  /* initialize_weight_fc vars */
  integer iwfc_input_channels;  /* input */
  integer iwfc_output_channels;  /* input */
  integer iwfc_i, iwfc_j, iwfc_k;
  integer iwfc_idx, iwfc_val;
  integer iwfc_width, iwfc_height;

  /* initialize_input_fc vars */
  integer iifc_input_channels;  /* input */
  integer iifc_i, iifc_j, iifc_k, iifc_l;
  integer iifc_index;

  /* initialize_input vars */
  integer ii_width;  /* input */
  integer ii_height;  /* input */
  integer ii_channels;  /* input */
  integer ii_output_channels;  /* input */
  integer ii_i, ii_j, ii_c;
  integer ii_idx;

  /* initialize_weight vars */
  integer iw_width;  /* input */
  integer iw_height;  /* input */
  integer iw_input_channels;  /* input */
  integer iw_output_channels;  /* input */
  integer iw_i, iw_j, iw_k, iw_l;
  integer iw_index;

  /* pu_read vars */
  integer pr_i;
  integer pr_input_idx;
  integer pr_tmp;

  /* pu_write vars */
  integer pw_i;
  reg signed [OP_WIDTH-1:0] pw_tmp;
  reg signed [OP_WIDTH-1:0] pw_exp_data;
  integer pw_idx;

  /* send_buffer_data vars */
  integer sbd_num_buffer_reads;
  integer sbd_num_data;
  integer sbd_idx;
  integer sbd_ii;

  
  
// ******************************************************************

  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _kw, _kh, _ks;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _iw, _ih, _ic, _batch, _oc;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _endrow_iw;
  reg                                         _skip;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _ow;
  reg  [ PAD_WIDTH            -1 : 0 ]        _pad;
  reg  [ PAD_WIDTH            -1 : 0 ]        _pad_row_start;
  reg  [ PAD_WIDTH            -1 : 0 ]        _pad_row_end;
  reg  [ STRIDE_SIZE_W        -1 : 0 ]        _stride;
  reg  [ TID_WIDTH            -1 : 0 ]        _max_threads;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        max_layers;
  reg  [ L_TYPE_WIDTH         -1 : 0 ]        l_type;
  reg                                         _pool;
  reg  [ 1                       : 0 ]        _pool_kernel;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _pool_oh;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        _pool_iw;
  reg  [ LAYER_PARAM_WIDTH    -1 : 0 ]        input_width;

  integer ii;

  integer conv_ic, conv_oc;

  integer state_ctr;
  reg[3:0] state;

  initial begin
    state_ctr <= 0;
    state <= INIT_AND_START;
  end
  

  parameter INIT_AND_START = 4'd0;  /* state 0 */
  parameter CNTRLLR_STARTED = 4'd1;  /* state 1 */
  parameter LAYER_OUTER_LOOP_INIT_TOP = 4'd2;  /* state 1.5 */
  parameter INIT_LAYER_VALS = 4'd3;   /* state 2 */
  parameter DO_WRITECOUNT = 4'd4;  /* state 4 */
  parameter OUTER_CONV_LOOP_TOP = 4'd5;  /* state 4.3 */
  parameter INNER_CONV_LOOP_TOP = 4'd6;  /* state 5 */
  parameter WAIT_CONV_START_CHANGE = 4'd7;  /* state 6 */
  parameter WAIT_CONV_FINISH = 4'd8;  /* state 7 */
  parameter INNER_CONV_LOOP_END = 4'd9;  /* state 8 */
  parameter WAIT_WRITES_NO_CONV = 4'd10;  /* state 4.7 */
  parameter DELAY_AFTER_WRITES = 4'd11;  /* state 9 */
  parameter WAIT_CNTRLLR_STATE_CHANGE  = 4'd12;  /* state 10 */
  parameter WAIT_TEST_PASS = 4'd13;  /* state 11 */
  
  always @(posedge clk) begin
    state_ctr <= state_ctr + 1;
    pass <= 0;
    fail <= 0;

    case (state)
      
    end
  
      
  end
  
  


  initial begin
    // State 0
    driver.status.start;
    start = 0;

    @(negedge clk);

    start = 1;

    wait (u_controller.state != 0);  // if, then transition to state 1

    /* State 1 */
    start = 0;

    max_layers = u_controller.max_layers+1;
    $display;
    $display("**************************************************");
    $display ("Number of layers = %d", max_layers);
    $display("**************************************************");
    $display;

    /* You do this state machine for each layer */
    for (ii=0; ii<max_layers; ii++)
    begin
      {_stride, _pool_iw, _pool_oh, _pool_kernel, _pool, l_type, _max_threads, _pad, _pad_row_start, _pad_row_end, _skip, _endrow_iw, _ic, _ih, _iw, _oc, _kh, _kw} =
        u_controller.cfg_rom[ii];
      $display("**************************************************");
      $display("Layer configuration: ");
      $display("**************************************************");
      case (l_type)
        0: $display("Type    : Convolution");
        1: $display("Type    : InnerProduct");
        1: $display("Type    : Normalization");
      endcase
      if (_pool == 1) $display ("Pooling\t: Enabled");
      else            $display ("Pooling\t: Disabled");

      input_width = _max_threads + _kh - 2*_pad;

      $display("Input  FM : %4d x %4d x %4d", input_width, _ih+1, _ic+1);
      $display("Output FM :             %4d", _oc+1);
      $display("Kernel    : %4d x %-4d", _kh+1, _kw+1);
      $display("Padding   : %4d", _pad);
      $display("Stride    : %4d", _stride);
      $display("**************************************************");

      wait (u_controller.state == 1);  /* transition to state 2 */

      /* State 2 */
      @(negedge clk);
      /* Might be worthwhile to have a switch statement inside of pu_driver and an input that you add */
      /* Basically would just be like "state" input and "type/related var" input */
      if (l_type == 0) /* When state transitions, at beginning of next cycle you're here */
      begin
        driver.initialize_input(input_width, _ih+1, 1, 1);  /* you initialize the input */
        driver.initialize_weight(_kh+1, _kh+1, _ic+1, _oc+1);  /* then you initialize the state */
        /* I think these things happen sequentially bc they're between a begin/end */
        driver.expected_output(input_width,_ih+1,_ic+1,1, _kw+1,_kh+1,_stride, _oc+1, _pad, _pad_row_start, _pad_row_end);
      end
      else if (l_type == 2)
      begin
        driver.initialize_input(input_width, _ih+1, 1, 1);
        driver.initialize_weight(0,0,0,0);
        driver.expected_output_norm(input_width,_ih+1,_ic+1,1, _kw+1,_kh+1,_stride, _oc+1, _pad, _pad_row_start, _pad_row_end);
      end
      else begin
        driver.initialize_input_fc(_ic+1);
        driver.initialize_weight_fc(_ic+1, (_oc+1)*NUM_PE);
        driver.expected_output_fc(_ic+1,(_oc+1)*NUM_PE, _max_threads);
      end
      //driver.print_pe_output;
      /* This needs to happen after each block of initialized input */
      if (_pool)
      begin
        /* Can probably combine expected_pooling_output commands w print_pooled_output */
        driver.expected_pooling_output(_pool_kernel, _pool_kernel, 2);
        //driver.print_pooled_output;
      end
      else
        driver.pool_enabled = 1'b0;

      /* Stage 4 */
      if (l_type == 0)
      begin
        /* Maybe stage 4.3 is init values */
        for (conv_oc = 0; conv_oc <= _oc; conv_oc = conv_oc + 1)
        begin
          /* Stage 5 */
          for (conv_ic = 0; conv_ic <= _ic; conv_ic = conv_ic + 1)
          begin
            $display ("OC (%d/%d) : IC (%d/%d)", conv_oc , _oc, conv_ic, _ic);
            driver.initialize_input(input_width, _ih+1, 1, 1);
            driver.initialize_weight(_kh+1, _kh+1, _ic+1, _oc+1);
            $display ("Conv Started");
            wait (u_controller.state == 4);  /* Transition to stage 6 */

            /* Stage 6 */
            wait (u_controller.state != 4);
            repeat(1000) @(negedge clk); /* Transition to stage 7 */

            /* Stage 7 */
            $display ("Conv finished"); /* Transition to stage 5 */
            
          end // for (conv_ic = 0; conv_ic <= _ic; conv_ic = conv_ic + 1)
          /* If conv_ic <= _ic, transition to stage 5, else transition to stage 8 */

          /* Stage 8 */
          //wait (driver.write_count/NUM_PE == driver.expected_writes);
          repeat(100) @(negedge clk);
          driver.write_count = 0;
          /* If conv_oc <= _oc, transition to stage 4.5, else transition to stage 9 */
        end
      end // if (l_type == 0)
      else /* Stage 4.7 */
        wait (driver.write_count/NUM_PE == driver.expected_writes); /* Transition to stage 9 */
      /* Stage 9 */
      repeat (100) begin
        @(negedge clk);
      end
      /* Count to 100, then wait for u_controller.state to not be 4 (can be in the same state), then*/
      /* Transition to stage 10 */
    end
    wait (u_controller.state != 4);

    repeat (1000) @(negedge clk);
    driver.status.test_pass;
  end

  //initial
  //begin
  //  $dumpfile("PU_tb.vcd");
  //  $dumpvars(0,PU_tb);
  //end

// ******************************************************************
// PU
// ******************************************************************
  always @(posedge clk)
    pu_data_in_v <= pu_rd_req;
  assign pu_rd_req = vecgen_rd_req;
  PU #(
    // Parameters
    .OP_WIDTH                 ( OP_WIDTH                 ),
    .NUM_PE                   ( NUM_PE                   )
   ) u_PU (
    // IO
    .clk                      ( clk                      ), //input
    .reset                    ( reset                    ), //input
    .buffer_read_data_valid   ( buffer_read_data_valid   ), //input
    .read_data                ( buffer_read_data_out     ), //input
    .pe_ctrl                  ( pe_ctrl                  ), //input
    .lrn_enable               ( lrn_enable               ), //input
    .pu_serdes_count          ( pu_serdes_count          ), //input
    .pe_neuron_sel            ( pe_neuron_sel            ), //input
    .pe_neuron_bias           ( pe_neuron_bias           ), //output
    .pe_neuron_read_req       ( pe_neuron_read_req       ), //input
    .vecgen_mask              ( vecgen_mask              ), //input
    .vecgen_wr_data           ( vecgen_wr_data           ), //input
    .wb_read_addr             ( wb_read_addr             ), //input
    .wb_read_req              ( wb_read_req              ), //input
    .bias_read_req            ( bias_read_req            ), //input
    .src_0_sel                ( src_0_sel                ), //input
    .src_1_sel                ( src_1_sel                ), //input
    .src_2_sel                ( src_2_sel                ), //input
    .out_sel                  ( out_sel                  ), //input
    .dst_sel                  ( dst_sel                  ), //input
    .pool_cfg                 ( pool_cfg                 ), //input
    .pool_ctrl                ( pool_ctrl                ), //input
    .read_id                  ( 10'b0                    ), //input
    .read_d_type              ( 2'b0                     ), //input
    .read_req                 ( pu_rd_req                ), //output
    .write_data               ( pu_data_out              ), //output
    .write_req                ( pu_wr_req                ), //output
    .write_ready              ( 1'b1                     )  //input
  );
// ******************************************************************

// ==================================================================
// Generate Vectors
// ==================================================================
  wire [D_TYPE_W-1:0] pu_read_d_type = 0;
  assign vecgen_rd_data = pu_data_in;
  wire vecgen_rd_data_v;
  assign vecgen_rd_data_v = pu_data_in_v;
  assign vecgen_rd_ready = pu_rd_ready;
  //assign write_data = vecgen_wr_data;
  //assign write_req = vecgen_wr_valid;
  vectorgen # (
    .OP_WIDTH                 ( OP_WIDTH                 ),
    .TID_WIDTH                ( TID_WIDTH                ),
    .NUM_PE                   ( NUM_PE                   )
  ) vecgen (
    .clk                      ( clk                      ),
    .reset                    ( reset                    ),
    .ready                    ( vecgen_ready             ),
    .ctrl                     ( vecgen_ctrl              ),
    .cfg                      ( vecgen_cfg               ),
    .read_data                ( vecgen_rd_data           ),
    .read_ready               ( vecgen_rd_ready          ),
    .read_req                 ( vecgen_rd_req            ),
    .write_data               ( vecgen_wr_data           ),
    .write_valid              ( vecgen_wr_valid          )
  );
// ==================================================================

// ==================================================================
// PU controller
// ==================================================================
  wire [ PE_OP_CODE_WIDTH     -1 : 0 ]        pe_op_code;
  wire                                        pe_enable;
  wire                                        pe_write_req;
  wire [ DATA_IN_WIDTH        -1 : 0 ]        pe_write_data;

  PU_controller
  #(  // PARAMETERS
    .NUM_PE                   ( NUM_PE                   ),
    .WEIGHT_ADDR_WIDTH        ( RD_ADDR_WIDTH            ),
    .PE_CTRL_W                ( PE_CTRL_WIDTH            ),
    .VECGEN_CTRL_W            ( VECGEN_CTRL_W            ),
    .TID_WIDTH                ( TID_WIDTH                ),
    .PAD_WIDTH                ( PAD_WIDTH                ),
    .LAYER_PARAM_WIDTH        ( LAYER_PARAM_WIDTH        )
  ) u_controller (   // PORTS
    .clk                      ( clk                      ), //input
    .reset                    ( reset                    ), //input
    .start                    ( start                    ), //input
    .done                     ( done                     ), //output
    .lrn_enable               ( lrn_enable               ), //output
    .pu_serdes_count          ( pu_serdes_count          ), //output
    .pe_neuron_sel            ( pe_neuron_sel            ), //output
    .pe_neuron_bias           ( pe_neuron_bias           ), //output
    .pe_neuron_read_req       ( pe_neuron_read_req       ), //output
    .pe_ctrl                  ( pe_ctrl                  ), //output
    .buffer_read_empty        ( buffer_read_empty        ), //input
    .buffer_read_req          ( buffer_read_req          ), //output
    .buffer_read_last         ( buffer_read_last         ), //input
    .pu_vecgen_ready          ( vecgen_ready             ), //input
    .vectorgen_ready          ( vecgen_ready             ), //input
    .vectorgen_ctrl           ( vecgen_ctrl              ), //output
    .vectorgen_cfg            ( vecgen_cfg               ), //output
    .pe_piso_read_req         ( pe_piso_read_req         ), //output
    .wb_read_req              ( wb_read_req              ), //output
    .wb_read_addr             ( wb_read_addr             ), //output
    .pe_write_mask            ( vecgen_mask              ), //output
    .pool_cfg                 ( pool_cfg                 ), //output
    .pool_ctrl                ( pool_ctrl                ), //output
    .src_0_sel                ( src_0_sel                ), //output
    .src_1_sel                ( src_1_sel                ), //output
    .src_2_sel                ( src_2_sel                ), //output
    .bias_read_req            ( bias_read_req            ), //output
    .out_sel                  ( out_sel                  ), //output
    .dst_sel                  ( dst_sel                  )  //output
  );
// ==================================================================



endmodule

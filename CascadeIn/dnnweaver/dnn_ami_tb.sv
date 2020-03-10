`timescale 1ns/1ps
`include "include/dw_params.vh"
`include "common.vh"

import ShellTypes::*;
import AMITypes::*;

module dnn_ami_tb();

  // params
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


  // General signals
  reg clk;
  reg rst;
  reg start;
  wire done;

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
        .rst(rst),
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
    .rst(rst),
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

  // dnn accelerator
  dnnweaver_ami_top 
  #(
  .NUM_PU(NUM_PU),
  .NUM_PE(NUM_PE)
  ) 
  my_weaver
  (
    .clk(clk),
    .reset(rst), 
    .start(start),
    .flush_buffer (1'b0), // TODO: Actually connect it
    .done(done),
    .mem_req(mem_req_in[0]),
    .mem_req_grant(mem_req_grant_out[0]),
    .mem_resp(mem_resp_out[0]),
    .mem_resp_grant(mem_req_grant_out[0])

  );

  initial begin
    $display("Starting Combined DNNWeaver/AmorphOS Test\n");
    app_enable[0] = 1'b1;
    port_enable[0][0] = 1'b1;
    port_enable[0][1] = 1'b1;
    start = 1'b0;
    clk = 1'b0;
    rst = 1'b1;
    #2
    rst = 1'b0;
    #2
    start = 1'b1;
    #2 // might need to be 2
    start = 1'b0;
    #2
    $display("Should have started by now.");
    #2;
  end
  
// Clock
always #1 clk = !clk;

initial begin
  #10
  while (!done) begin
    #1;
  end
  $display("Encountered stop signal from DNNWeaver!!!!\n");
end

endmodule


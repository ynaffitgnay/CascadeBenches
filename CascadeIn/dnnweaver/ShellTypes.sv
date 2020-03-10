//
// Academic Shell Types
//
`ifndef SHELLTYPES_SV_INCLUDED
`define SHELLTYPES_SV_INCLUDED

`include "common.vh"

//package ShellTypes;

// 
// Global constants, should not be changed
//

`ifdef USE_ECC_DDR
parameter USE_ECC                 = 1; // change this
`else
parameter USE_ECC                 = 0;
`endif

parameter AVL_ADDR_WIDTH          = 26;
parameter AVL_DATA_WIDTH          = USE_ECC == 1 ? 512 : 576;
parameter AVL_SPARE_WIDTH         = USE_ECC == 1 ? 0   : 64;
parameter AVL_BE_WIDTH            = USE_ECC == 1 ? 64  : 72;
parameter AVL_SIZE                = 7;

parameter NUM_UMI                 = 1;

parameter UMI_ADDR_WIDTH          = 64;
parameter UMI_DATA_WIDTH          = USE_ECC == 0 ? 576 : 512;
parameter UMI_SPARE_WIDTH         = USE_ECC == 0 ?  64 :   0;
parameter UMI_MASK_WIDTH          = UMI_DATA_WIDTH / 8;

parameter PCIE_DATA_WIDTH         = 128;
parameter PCIE_SLOT_WIDTH         = 16; // 16 bits are available, but only first 6 bits are valid (64 slots)
parameter PCIE_PAD_WIDTH          = `C_LOG_2(PCIE_DATA_WIDTH/8);

`define MEMREQ_BUS_WIDTH (1 + 1 + UMI_ADDR_WIDTH + UMI_DATA_WIDTH)
`define MemReq_valid 0:0
`define MemReq_isWrite 1:1
`define MemReq_addr (UMI_ADDR_WIDTH + 1):2
`define MemReq_data (UMI_DATA_WIDTH - 1 + UMI_ADDR_WIDTH + 2):(UMI_ADDR_WIDTH + 2)


//typedef struct packed {
//  logic                      valid;
//  logic                      isWrite;
//  logic [UMI_ADDR_WIDTH-1:0] addr;
//  logic [UMI_DATA_WIDTH-1:0] data;
//} MemReq;
//
//typedef struct packed {
//  logic                      valid;
//  logic [UMI_DATA_WIDTH-1:0] data;
//} MemResp;
//
//typedef struct packed {
//  logic                       valid;
//  logic                       isWrite;
//  logic [31:0]                addr;
//  logic [63:0]                data;
//} SoftRegReq;
//
//typedef struct packed {
//  logic                       valid;
//  logic [63:0]                data;
//} SoftRegResp;
//
//typedef struct packed {
//  logic                       valid;
//  logic [PCIE_DATA_WIDTH-1:0] data;
//  logic [PCIE_SLOT_WIDTH-1:0] slot;
//  logic [PCIE_PAD_WIDTH-1:0]  pad;
//  logic                       last;
//} PCIEPacket;

//endpackage
`endif


// This is how you would use these "structs"
//wire [`MEMREQ_BUS_WIDTH - 1:0] x;
//assign x[`MemReq_valid] = 1;
//assign x[`MemReq_isWrite] = 0;
//assign x[`MemReq_addr] = 64'hdeaddeaddeaddead; //64'h1234123412341234;
//
//initial $display("%h", x[`MemReq_addr]);
//
//wire[UMI_ADDR_WIDTH - 1:0] y;
//assign y = 64'hDEADDEADDEADDEAD;
//
//initial $display("%h", y);


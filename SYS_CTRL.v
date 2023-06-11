module SYS_CTRL #(
    parameter DATA_WIDTH=8,
    REG_NO=16,
    ADDRESS_WIDTH=4
    
) (
    // inputs to SYS_RX
    input [DATA_WIDTH-1 : 0]       RX_P_DATA,
    input                          RX_D_VLD,
    // inputs to SYS_TX
    input [DATA_WIDTH-1 : 0] RdData,
    input                    RdData_Valid,
    input [2*DATA_WIDTH-1:0] ALU_OUT,
    input                    OUT_VALID,
    input Busy,
    
    input clk, reset,
    
    //outputs from SYS_RX
    output        ALU_EN,
    output  [3:0] ALU_FUN,
    output        CLK_EN,
    output  [ADDRESS_WIDTH-1:0] address,
    output                      WrEN,
    output  [DATA_WIDTH-1 : 0]  WrData,
    output                      RdEN,
    output  clk_div_en,
    //outputs from SYS_TX
    output  [DATA_WIDTH-1 : 0] TX_P_DATA,
    output                     TX_D_VLD
);

SYS_CTRL_RX U0_SYS_CTRL_RX (
    .RX_P_DATA(RX_P_DATA),
    .RX_D_VLD(RX_D_VLD),
    
    .clk(clk), .reset(reset),
    
    .ALU_EN(ALU_EN),
    .ALU_FUN(ALU_FUN),
    .CLK_EN(CLK_EN),
    .address(address),
    .WrEN(WrEN),
    .WrData(WrData),
    .RdEN(RdEN),
    .clk_div_en(clk_div_en)
);

SYS_CTRL_TX U0_SYS_CTRL_TX(
    .RdData(RdData),
    .RdData_Valid(RdData_Valid),
    .ALU_OUT(ALU_OUT),
    .OUT_VALID(OUT_VALID),
    .Busy(Busy),

    .clk(clk), .reset(reset),
    
    .TX_P_DATA(TX_P_DATA),
    .TX_D_VLD(TX_D_VLD)
);



endmodule
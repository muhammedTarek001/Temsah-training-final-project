module SYS_TOP #(
    parameter DATA_WIDTH=8,
    REG_NO=16,
    ADDRESS_WIDTH=4
) (
    input RX_IN,

    input REF_CLK, UART_CLK, RST,

    output TX_OUT, parity_err, start_err, stop_err
);


wire [DATA_WIDTH-1 : 0]       RX_P_DATA;
wire                          RX_D_VLD;
    // inputs to SYS_TX
wire [DATA_WIDTH-1 : 0] RdData;
wire                    RdData_Valid;
wire [2*DATA_WIDTH-1:0] ALU_OUT;
wire                    OUT_VALID;
wire Busy;
    
    
    //outputs from SYS_RX
wire        ALU_EN;
wire  [3:0] ALU_FUN;
wire        CLK_EN;
wire  [ADDRESS_WIDTH-1:0] address;
wire                      WrEN;
wire  [DATA_WIDTH-1 : 0]  WrData;
wire                      RdEN;
wire  clk_div_en;
    //outputs from SYS_TX
wire  [DATA_WIDTH-1 : 0] TX_P_DATA;
wire                     TX_D_VLD;


//o/p of Data sync from UART_RX to SYS_CTRL_RX
wire [DATA_WIDTH-1 : 0] RX_P_DATA_sync;
wire                    RX_D_VLD_sync;


//o/p of Data sync from SYS_CTRL_TX to UART_RX 
wire [DATA_WIDTH-1 : 0] TX_P_DATA_sync;
wire                    TX_D_VLD_sync;



//o/p from reg_file
wire [DATA_WIDTH-1:0] REG2,     //I/P TO UART
                      REG3;     //I/P TO CLK_DIV
wire [DATA_WIDTH-1:0] OpA, OpB; //I/P TO ALU


//o/p of clk_div to UART_TX
wire o_div_clk;


//o/p of BIT_SYNC (from UART_TX to SYS_TX)
reg Busy_sync;
reg bit_sync; 

//o/p of clk gating unit
wire ALU_CLK;
wire clk_extend;
wire CLK_EN_extended;

wire SYNC_RST1; // FOR REF_CLK DOMAIN EXCEPT ALU
wire SYNC_RST2; //FOR ALU_CLK BECAUSE IT'S SKEWED FROM REF_CLK
wire SYNC_RST3; //FOR UART_CLK DOMAIN

assign clk_extend      = (OUT_VALID == 1 && ALU_EN == 0) ? 1:0;
assign CLK_EN_extended = (CLK_EN || clk_extend)          ? 1:0;

// always @(posedge REF_CLK or negedge SYNC_RST1) 
// begin
//     if(!SYNC_RST1)
//     begin
//         clk_extend <= 0;
//     end

//     else
//     begin
//         if(OUT_VALID == 1 && ALU_EN == 0)
//         begin
//             clk_extend <= 1;
//         end

//         else
//         begin
//             clk_extend <= 0;
//         end

//     end
    
// end

always @(posedge REF_CLK or negedge SYNC_RST1) 
begin
    if(!SYNC_RST1)
    begin
        bit_sync  <= 0;
        Busy_sync <= 0;
    end
    else
    begin
        bit_sync  <= Busy;
        Busy_sync <= bit_sync; 
    end

end



RST_SYNC U0_RST_SYNC(
    .reset(RST),
    .clk(REF_CLK),
    .SYNC_RST(SYNC_RST1)
);

RST_SYNC U1_RST_SYNC(
    .reset(RST),
    .clk(ALU_CLK),
    .SYNC_RST(SYNC_RST2)
);

RST_SYNC U2_RST_SYNC(
    .reset(RST),
    .clk(UART_CLK),
    .SYNC_RST(SYNC_RST3)
);

data_sync U0_data_sync(
    .Unsync_bus(RX_P_DATA),
    .bus_enable(RX_D_VLD),
    
    .clk(REF_CLK), .reset(SYNC_RST1),
    
    .sync_bus(RX_P_DATA_sync),
    .enable_pulse(RX_D_VLD_sync)
);

data_sync U1_data_sync(
    .Unsync_bus(TX_P_DATA),
    .bus_enable(TX_D_VLD),
    
    .clk(o_div_clk), .reset(SYNC_RST3),
    
    .sync_bus(TX_P_DATA_sync),
    .enable_pulse(TX_D_VLD_sync)
);

SYS_CTRL U0_SYS_CTRL(
    .RX_P_DATA(RX_P_DATA_sync),
    .RX_D_VLD(RX_D_VLD_sync),
    .RdData(RdData),
    .RdData_Valid(RdData_Valid),
    .ALU_OUT(ALU_OUT),
    .OUT_VALID(OUT_VALID),
    .Busy(Busy_sync),
    
    .clk(REF_CLK), .reset(SYNC_RST1),
    
    .ALU_EN(ALU_EN),
    .ALU_FUN(ALU_FUN),
    .CLK_EN(CLK_EN),
    .address(address),
    .WrEN(WrEN),
    .WrData(WrData),
    .RdEN(RdEN),
    .clk_div_en(clk_div_en),
    .TX_P_DATA(TX_P_DATA),
    .TX_D_VLD(TX_D_VLD)
);

reg_file U0_reg_file (
    .RdEN(RdEN),
    .WrEN(WrEN),
    .WrData(WrData),
    .address(address),

    .clk(REF_CLK), .reset(SYNC_RST1),
    
    .RdData_Valid(RdData_Valid),
    .RdData(RdData),
    .REG0(OpA),
    .REG1(OpB),
    .REG2(REG2),
    .REG3(REG3)
);


clk_div U0_clk_div(
    .I_ref_clk(UART_CLK),
    .I_rst_n(SYNC_RST1),
    .I_clk_en(clk_div_en),
    .I_div_ratio(REG3[3:0]),

    .o_div_clk(o_div_clk)
);

UART_TOP U0_UART_TOP (
    .RX_IN(RX_IN),
    .prescale(REG2[6:2]),
    .PAR_EN(REG2[0]),
    .PAR_TYP(REG2[1]),
    .TX_P_DATA(TX_P_DATA_sync), //still needs to be defined /????
    .TX_D_VLD(TX_D_VLD_sync),
    
    .clk(UART_CLK), .divided_clk(o_div_clk) ,.reset(SYNC_RST3),

    .RX_P_DATA(RX_P_DATA),
    .RX_D_VLD(RX_D_VLD),
    .parity_err(parity_err),
    .start_err(start_err),
    .stop_err(stop_err),
    .TX_OUT(TX_OUT),
    .Busy(Busy) //needs to be syncronized using BIT_SYNC
);

CLK_GATE U0_CLK_GATE(
    .CLK_EN(CLK_EN_extended),
    .CLK(REF_CLK),
    .GATED_CLK(ALU_CLK)
);


ALU U0_ALU(
    .A(OpA), .B(OpB),
    .ALU_FUN(ALU_FUN),
    .Enable(ALU_EN),

    .clk(ALU_CLK), .reset(SYNC_RST2),

    .ALU_OUT(ALU_OUT),
    .OUT_VALID(OUT_VALID)
);

endmodule
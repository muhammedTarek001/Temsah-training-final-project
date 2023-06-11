module UART_TOP #(
    parameter WIDTH=8,
    STOP=1,
    START =0
) (
    //UART_RX inputs
    input RX_IN,
    input [4:0] prescale,
    input PAR_EN,
    input PAR_TYP,
    //UART_TX inputs
    input [WIDTH-1:0] TX_P_DATA,
    input             TX_D_VLD,
    
    input clk, divided_clk, reset,

    //UART_RX outputs
    output [WIDTH-1:0] RX_P_DATA,
    output             RX_D_VLD,
    output             parity_err,
    output             start_err,
    output             stop_err,
    //UART_TX outputs
    output TX_OUT,
    output Busy
);



UART_RX U0_UART_RX (
    .SRL_data(RX_IN),
    .prescale(prescale),
    .PAR_EN(PAR_EN),
    .PAR_TYP(PAR_TYP),
    
    .clk(clk),
    .rst(reset),
    
    .P_DATA(RX_P_DATA),
    .Data_Valid_reg(RX_D_VLD),
    .parity_err(parity_err),
    .start_err(start_err),
    .stop_err(stop_err)
);


uart_tx U0_uart_tx (
    .P_DATA(TX_P_DATA),
    .DATA_VALID(TX_D_VLD),
    .PAR_EN(PAR_EN), .PAR_TYP(PAR_TYP),

    .clk(divided_clk),
    .rst(reset),
    
    .TX_OUT(TX_OUT),
    .Busy(Busy)
);




endmodule
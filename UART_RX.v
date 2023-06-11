module UART_RX #(
    parameter DATA_WIDTH=8,
    START_BIT=0,

    IDLE=0,
    START_REC=1,
    DATA_REC=2,
    PAR_REC=3,
    STOP_REC=4
) (
    input SRL_data,
    input [4:0] prescale,
    input PAR_EN,
    input PAR_TYP,

    input clk,
    input rst,

    output [DATA_WIDTH-1:0] P_DATA,
    output reg         Data_Valid_reg,

    output             parity_err,
    output             start_err,
    output             stop_err
);


//FSM o/p's
wire bit_count_enable;
wire edge_count_enable;
wire start_check_enable;
wire stop_check_enable;
wire parity_check_enable;
wire Data_Valid;


//parity_calc o/p's
wire parity_bit;

// data_sample o/p's
wire sampled_data;
wire deserializer_enable;

//edge_bit_counters o/p's
wire data_sample_enable;
wire state_change_enable;
wire stop_edge_enable;

//counter for maintaining data_valid for 1 clk_period
reg [3:0] data_valid_counter;
reg       Data_Valid_extended;




always @(*) 
begin
    if(data_valid_counter>0 && data_valid_counter<4'b1001)
    begin
        Data_Valid_extended=1;
    end

    else
    Data_Valid_extended=0;
end

always @(posedge clk or negedge rst) 
begin

    if(!rst)
    begin
        data_valid_counter<=0;
    end
    else
    begin
        if((Data_Valid==1) || (data_valid_counter>3 && data_valid_counter<4'b1001))
        begin
            data_valid_counter<=data_valid_counter+1;
        end

        else
        begin
            data_valid_counter<=0;
        end
    end

    

end


always @(posedge clk or negedge rst)
begin
    if(!rst)
    begin
        Data_Valid_reg<=0;
    end

    else
    begin
        Data_Valid_reg<=Data_Valid_extended;
    end
end

edge_bit_counters U0_edge_bit_counters(
    .prescale(prescale),
    .bit_count_enable(bit_count_enable),
    .edge_count_enable(edge_count_enable),
    .stop_err(stop_err),

    .clk(clk),
    .rst(rst),

    .data_sample_enable(data_sample_enable),
    .data_transmitted_finished_flag(data_transmitted_finished_flag),
    .state_change_enable(state_change_enable),
    .stop_edge_enable(stop_edge_enable)
);

UART_RX_FSM U0_UART_FSM (
    .PAR_EN(PAR_EN),
    .SRL_data(SRL_data),
    .data_transmitted_finished_flag(data_transmitted_finished_flag),
    .state_change_enable(state_change_enable),
    .stop_edge_enable(stop_edge_enable),
    .start_err(start_err),
    .stop_err(stop_err),
    .parity_err(parity_err),

    .clk(clk),
    .rst(rst),

    .bit_count_enable(bit_count_enable),
    .edge_count_enable(edge_count_enable),
    .start_check_enable(start_check_enable),
    .stop_check_enable(stop_check_enable),
    .parity_check_enable(parity_check_enable),
    .Data_Valid(Data_Valid)
);


start_check U0_START_CHECK(
    .start_check_enable(start_check_enable),
    .sampled_data(sampled_data),

    .start_err(start_err)
);

parity_calc U0_PAR_CALC (
    .P_DATA(P_DATA),
    .PAR_TYP(PAR_TYP),

    .clk(clk),
    .rst(rst),

    .parity_bit(parity_bit)
);

parity_check U0_PAR_CHECK(
    .parity_bit(parity_bit),
    .sampled_data(sampled_data),
    .parity_check_enable(parity_check_enable),
    
    .parity_err(parity_err)
);

stop_check U0_STOP_CHECK (
    .stop_check_enable(stop_check_enable),
    .sampled_data(sampled_data),

    .stop_err(stop_err)
);

data_sample U0_DATA_SAMPLE(
    .data_sample_enable(data_sample_enable),
    .SRL_data(SRL_data),
    .stop_check_enable(stop_check_enable),
    .start_check_enable(start_check_enable),
    .data_transmitted_finished_flag(data_transmitted_finished_flag),
    .parity_check_enable(parity_check_enable),
    
    .clk(clk),
    .rst(rst),

    .sampled_data(sampled_data),
    .deserializer_enable(deserializer_enable)
);

deserializer U0_DESERIALIZER(
    .deserializer_enable(deserializer_enable),
    .sampled_data(sampled_data),

    .clk(clk),
    .rst(rst),

    .P_DATA(P_DATA)
);

endmodule
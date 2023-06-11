module edge_bit_counters #(
    parameter BIT_COUNTER_WIDTH=8,
              EDGE_COUNTER_WIDTH=8,
              DATA_WIDTH=8
) (
    input [4:0] prescale,
    input bit_count_enable, //after start bit this will be 1 till 
                            //the last bit before parity bit
                            //deserializer will recieve data at bit_count = 0:7

    input edge_count_enable, //when not idle ---> start to count edges
    input stop_err,
    
    input clk,
    input rst,

    output reg     data_sample_enable,
    output wire    data_transmitted_finished_flag,
    output reg     state_change_enable,
    output reg     stop_edge_enable
    
);

//start or stop signal----> instead of outputting bit_counter to FSM
reg [BIT_COUNTER_WIDTH-1:0]  bit_counter;
reg [EDGE_COUNTER_WIDTH-1:0] edge_counter;

reg [3:0] midlle_edge_no;

//DATA_WIDTH+1 or +2 or +0 ???
assign data_transmitted_finished_flag= (bit_counter == DATA_WIDTH)? 1:0;

always @(*) 
begin
    if(prescale == 16)
    begin
        midlle_edge_no=8;
    end

    if(prescale == 8)
    begin
        midlle_edge_no=4;
    end

    else
    midlle_edge_no=4;
end


always @(*) 
begin
    if(edge_counter==1 && stop_err==0)
    stop_edge_enable=1;
    
    else
    stop_edge_enable=0;
end

//when to change state of FSM
always @(*) 
begin
    if(edge_counter==1)
    state_change_enable=1;

    else
    state_change_enable=0;
end



always @(posedge clk or negedge rst) 
begin
    if(!rst)
    begin
        bit_counter<=0;
        edge_counter<=0;
    end

    else
    begin

        if(edge_count_enable)
        begin
            if(edge_counter <= EDGE_COUNTER_WIDTH-2)  //-1 ??
            edge_counter<=edge_counter+1;
            
            else
            begin
                edge_counter<=0;
                
                if(bit_count_enable || bit_counter==BIT_COUNTER_WIDTH)
                begin
                    if(bit_counter <= BIT_COUNTER_WIDTH -1)  //-1 or 0 ??
                    bit_counter<=bit_counter+1;
                
                    else
                       bit_counter<=0;
                    
                end
                
            end
        end

        else
        edge_counter<=0;

    end
    
end


always @(*) 
begin
    
    if((edge_counter==midlle_edge_no -2 || edge_counter==midlle_edge_no -1 
    || edge_counter==midlle_edge_no    || edge_counter==midlle_edge_no +1)
    && (edge_count_enable))

    begin
    data_sample_enable=1;
    end

    else
    data_sample_enable=0;
end


endmodule
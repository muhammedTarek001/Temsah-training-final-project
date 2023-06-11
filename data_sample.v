
module data_sample#(
    parameter DATA_WIDTH=8,
              SAMPLES_NO=3
) (
    input data_sample_enable,
    input SRL_data,
    input stop_check_enable,
    input start_check_enable,
    input data_transmitted_finished_flag,
    input parity_check_enable,
    
    input clk,
    input rst,

    output reg sampled_data,
    output reg deserializer_enable
);

reg [1:0] samples_counter;
reg [2:0] sampled_bits;




//sampled data generation
always @(*) 
begin  
    if(sampled_bits[0]== sampled_bits[1] || sampled_bits[0]==sampled_bits[2])
    begin
        sampled_data=sampled_bits[0];
    end

    else if(sampled_bits[1] == sampled_bits[2])
    begin
        sampled_data=sampled_bits[1];
    end

    else
    sampled_data=0;
end


//deserializer_enable generation
always @(*) 
begin
    if(data_sample_enable)
        begin

            if(!(samples_counter < SAMPLES_NO) && !stop_check_enable && !start_check_enable 
            && !data_transmitted_finished_flag && !parity_check_enable) //we want deserializer to recieve data but not stop bit nor start bit
            begin
                deserializer_enable=1;
            end

            else
            begin
               deserializer_enable=0;
            end
        end

    else
        deserializer_enable=0;

end


//counting 3 samples
always @(posedge clk or negedge rst) 
begin

    if(!rst)
    begin
        samples_counter<=0;
        sampled_bits<=0;
    end

    else
    begin
        if(data_sample_enable)
        begin
            if(samples_counter < SAMPLES_NO)
            begin
               samples_counter<=samples_counter+1; 
               sampled_bits[samples_counter]<=SRL_data; //demux during synthesis
            end

            else
            begin
                samples_counter<=0;
            end
        end

        else
        samples_counter<=0;
    end
     
end


endmodule
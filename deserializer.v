module deserializer #(
    parameter DATA_WIDTH=8
) (
    input deserializer_enable,//should not be 1 all the time
                              //it should be 1 at 
    input sampled_data,

    input clk,
    input rst,

    output reg [DATA_WIDTH-1:0] P_DATA
);



always @(posedge clk or negedge rst) 
begin
    if(!rst)
    begin
        P_DATA<=0;
    end

    else
    begin

        if(deserializer_enable)
        begin
            P_DATA[6:0]<={P_DATA[7:1]};
            P_DATA[DATA_WIDTH-1]<= sampled_data ;  
        end

    end
end

endmodule
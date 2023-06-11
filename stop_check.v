module stop_check #(
    parameter STOP_BIT=1
) (
    input stop_check_enable,  //if it is time for stop bit
    input sampled_data,

    output reg stop_err
);

always @(*) 
begin
    if(stop_check_enable)
    begin
        
        if(sampled_data == STOP_BIT)
        stop_err=0;

        else
        stop_err=1;
    end

    else
    stop_err=1;
end

endmodule
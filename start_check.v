module start_check #(
    parameter START_BIT=0
) (
    input start_check_enable, 
    input sampled_data,

    output reg start_err
);

always @(*) 
begin
    if(start_check_enable)
    begin
        
        if(sampled_data == START_BIT)
        start_err=0;

        else
        start_err=1;
    end

    else
    start_err=1;
end

endmodule
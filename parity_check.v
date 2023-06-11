module parity_check(
    input parity_bit,
    input sampled_data,
    input parity_check_enable, //if par_en && data has been transmmited
   
    output reg parity_err   
);

always @(*) 
begin
    if(parity_check_enable)
    begin
        
        if(parity_bit == sampled_data)
        parity_err=0;

        else
        parity_err=1;
    end

    else
    parity_err=1;
end

endmodule
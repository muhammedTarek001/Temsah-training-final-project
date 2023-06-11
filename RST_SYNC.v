module RST_SYNC (
    input reset,
    input clk,

    output reg SYNC_RST
);

reg ff1;

always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        ff1 <= 0;
        SYNC_RST <= 0;
    end

    else
    begin
        ff1 <= 1;
        SYNC_RST <= ff1;
    end
end
    
endmodule
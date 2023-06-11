
module clk_div #()(
    input I_ref_clk,
        I_rst_n,
        I_clk_en,
    input [3:0] I_div_ratio,

    output reg o_div_clk
);

reg [3:0] counter;


always @(posedge I_ref_clk or negedge I_rst_n) 
begin
    
    if(!I_rst_n)
    begin
        o_div_clk <= 0;
    end
    else
    begin
      if(I_clk_en)
      begin
        if(I_div_ratio[0] == 0)
        begin

          if(counter < ( (I_div_ratio>>1) + 1 ))
          begin
            o_div_clk<=1;
          end

          else
          begin
            o_div_clk<=0;
          end
        end

        else
        begin
          if(counter <= ( (I_div_ratio>>1) + 1 ) && I_ref_clk==1)
          begin
            o_div_clk<=1;
          end

          else
          begin
            o_div_clk<=0;
          end
        end


      end

      else
      begin
        o_div_clk = I_ref_clk;
      end
    end

    
    
end


always @(posedge I_ref_clk or negedge I_rst_n) 
begin
    if(!I_rst_n) //required for what
    counter <= 1;

    else
    begin
        if(counter < I_div_ratio)
        begin
            counter <= counter+1;
        end

        else
        begin
            counter <= 1;
        end
    end
end
    
endmodule
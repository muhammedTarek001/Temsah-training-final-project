module UART_RX_FSM #(
    parameter DATA_WIDTH=8,
    START_BIT=0,

    IDLE=0,
    START_REC=1,
    DATA_REC=2,
    PAR_REC=3,
    STOP_REC=4
) (
    input PAR_EN,
    input SRL_data,
    input data_transmitted_finished_flag, // i/p from edge_bit_counters to indicate if data is transmmited or not

    input state_change_enable,
    input stop_edge_enable,

    //i/p's from check blocks
    input start_err,
    input stop_err,
    input parity_err,
    input clk,
    input rst,
    

    output reg bit_count_enable,
    output reg edge_count_enable, //will be 1 once we recieve a new bit

    //check blocks i/p's
    output reg start_check_enable,
    output reg stop_check_enable,
    output reg parity_check_enable,

    output reg Data_Valid  //will be 1 once we check start ,parity ,stop bits 
);

reg [2:0] current_state;
reg [2:0] next_state;

wire deserializer_enable;


//Data_Valid will NOT get 1 if any bit check failed

always @(posedge clk or negedge rst) 
begin
    if(!rst)
    begin
        current_state<=0;
    end
    else if (state_change_enable==1) 
    begin
        current_state<=next_state;
    end
end

//control signals generation.
always @(*) 
begin 

    case (current_state)
        IDLE:
        begin
            if(SRL_data == START_BIT)
            begin 
                edge_count_enable=1;
                bit_count_enable=0;

                start_check_enable=1;
                stop_check_enable=0;
                parity_check_enable=0;

                Data_Valid=0;
            end

            else
            begin
                edge_count_enable=0;
                bit_count_enable=0;

                start_check_enable=0;
                stop_check_enable=0;
                parity_check_enable=0;

                Data_Valid=0;
            end
        end

        START_REC:
        begin
                edge_count_enable=1;
                bit_count_enable=0;

                start_check_enable=1;
                stop_check_enable=0;
                parity_check_enable=0;

                Data_Valid=0;
            
        end

        DATA_REC: 
        begin
            if(!data_transmitted_finished_flag)
            begin
                edge_count_enable=1;
                bit_count_enable=1;

                start_check_enable=0;
                stop_check_enable=0;
                parity_check_enable=0;
                
                Data_Valid=0;
            end

            else
            begin
                edge_count_enable=1;
                bit_count_enable=1;  

                start_check_enable=0;
                stop_check_enable=0;
                parity_check_enable=0;
                
                Data_Valid=0;
            end
        end

        PAR_REC:
        begin
            edge_count_enable=1;
            bit_count_enable=1;

            start_check_enable=0;
            stop_check_enable=0;
            parity_check_enable=1;
                
            Data_Valid=0;
        end

        STOP_REC:
        begin
            stop_check_enable=1;
            edge_count_enable=1;
            if(!stop_err)
            begin
                // if(stop_edge_enable)       //black box edited !!!!
                // begin
                //     edge_count_enable=0;    
                // end
                // else
                // begin
                //    edge_count_enable=1;    
                // end
                bit_count_enable=0;

                start_check_enable=0;     
                parity_check_enable=0;
                
                Data_Valid=1;
            end

            else
            begin
                
                bit_count_enable=0;

                start_check_enable=0;
                parity_check_enable=0;
                
                Data_Valid=0;
            end
        end
        default:
        begin
            edge_count_enable=0;
            bit_count_enable=0;

            start_check_enable=0;
            stop_check_enable=0;
            parity_check_enable=0;

            Data_Valid=0;
                
        end
         
        
    endcase

end


//next_state generation
always @(*) 
begin
    case (current_state)
        IDLE:
        begin
            if(SRL_data == START_BIT)
            begin
                next_state=START_REC;
            end
            else
            begin
                next_state=IDLE;
            end
        end

        START_REC:
        begin
            if(!start_err)
            next_state=DATA_REC;

            else
            next_state=START_REC;
            
            
        end

        DATA_REC:
        begin
            if (data_transmitted_finished_flag) 
            begin
                if(PAR_EN)
                next_state=PAR_REC;

                else
                begin
                    next_state=STOP_REC;
                end
            end

            else 
            begin
                next_state=DATA_REC;
            end
            
        end

        PAR_REC:
        begin
            if(parity_err)
            begin
                next_state=IDLE;
            end

            else
            begin
                next_state=STOP_REC;
            end
        end

         STOP_REC:
         begin
            if(SRL_data == START_BIT)
            next_state=START_REC;

            else
            next_state=IDLE;
         end

         default:
         begin
            next_state=IDLE;
         end
        
    endcase
    
end
    
endmodule
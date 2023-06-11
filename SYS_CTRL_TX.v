module SYS_CTRL_TX #(
    parameter DATA_WIDTH=8,
    REG_NO=16,
    ADDRESS_WIDTH=4,
    
    //states for SYS_CTRL_TX
    IDLE                         = 0,

    SEND_RdData_BUSY_WAIT        = 1, //IN BUSY_WAIT SIGNALS WE ARE WAITING FOR BUSY TO BE LOW
    SEND_RdData_BUSY_RESERVED    = 2, //IN BUSY_RESERVED SIGNALS WE ARE WAITING FOR BUSY TO BE HIGH
    SEND_RdData_BUSY_FREE        = 3, //IN BUSY_FREE WE ARE WAITING FOR BUSY TO BE LOW AGAIN
    
    SEND_ALU_OUT_1_BUSY_WAIT     = 4,
    SEND_ALU_OUT_1_BUSY_RESERVED = 5,
    SEND_ALU_OUT_1_BUSY_FREE     = 6,

    SEND_ALU_OUT_2_BUSY_WAIT     = 7,
    SEND_ALU_OUT_2_BUSY_RESERVED = 8,
    SEND_ALU_OUT_2_BUSY_FREE     = 9,

    //states for overdata unit
    OVERDATA_ALU_RESERVED       = 1,
    OVERDATA_RdData_RESERVED    = 2,
    OVERDATA_ALU_WAITING        = 3,
    OVERDATA_RdData_WAITING     = 4
) (
    //from RF
    input [DATA_WIDTH-1 : 0] RdData,
    input                    RdData_Valid,
    //from ALU
    input [2*DATA_WIDTH-1:0] ALU_OUT, //how to o/p that
    input                    OUT_VALID,
    //from UART_TX
    input Busy,
    // //from SYS_CTRL_RX
    // input RX_D_VLD,

    input clk, reset,

    //to UART_TX
    output reg [DATA_WIDTH-1 : 0] TX_P_DATA,
    output reg                    TX_D_VLD
);

reg [3:0] next_state;
reg [3:0] current_state;

reg [2:0] overdata_next_state;
reg [2:0] overdata_current_state;

reg [2*DATA_WIDTH-1 : 0] overdata;
reg overdata_flag;
reg overdata_ALU_flag;
reg overdata_RdData_flag;

reg overdata_finished_flag;


///////////////////////////////////// OVERDATA UNIT  //////////////////////////////////// 
always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        overdata_current_state <= IDLE;
    end

    else
    begin
        overdata_current_state <= overdata_next_state;
    end   
end

//overdata register assigning
always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        overdata             <= 0;
        overdata_ALU_flag    <= 0;
        overdata_RdData_flag <= 0;
    end

    else
    begin
        case (overdata_current_state)         //next_state or current_state
            
            IDLE:
            begin
                overdata_ALU_flag    <= 0;
                overdata_RdData_flag <= 0;
            end

            OVERDATA_RdData_RESERVED:
            begin
                if(overdata_next_state != OVERDATA_RdData_WAITING)
                begin
                    overdata             <= RdData;
                    overdata_ALU_flag    <= 0;
                    overdata_RdData_flag <= 1;
                end
            end

            OVERDATA_ALU_RESERVED:
            begin
                if(overdata_next_state != OVERDATA_ALU_WAITING)
                begin
                    overdata             <= ALU_OUT;
                    overdata_ALU_flag    <= 1;
                    overdata_RdData_flag <= 0;
                end
            end 
        endcase
    end
end

always @(*) 
begin
    case (overdata_current_state)
        IDLE:
        begin
            if(overdata_flag && !overdata_finished_flag)
            begin
                if(RdData_Valid && !OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_RdData_RESERVED;
                end

                else if(!RdData_Valid && OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_ALU_RESERVED;
                end

                else  //IMPOSSIBLE TO HAPPEN
                overdata_next_state = IDLE;  
            end

            else
            begin
                overdata_next_state = IDLE;  
            end 
        end
        
        OVERDATA_RdData_RESERVED:
        begin
            if(overdata_flag)
            begin
                if(RdData_Valid && !OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_RdData_WAITING;
                end

                else if(!RdData_Valid && OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_ALU_WAITING;
                end

                else  //IMPOSSIBLE TO HAPPEN
                overdata_next_state = IDLE;  
            end
            
            else if(!overdata_finished_flag)
            begin
                overdata_next_state = OVERDATA_RdData_RESERVED;
            end

            else
            begin
                overdata_next_state = IDLE;  
            end 
        end

        OVERDATA_ALU_RESERVED:
        begin
            if(overdata_flag)
            begin
                if(RdData_Valid && !OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_RdData_WAITING;
                end

                else if(!RdData_Valid && OUT_VALID)
                begin
                    overdata_next_state = OVERDATA_ALU_WAITING;
                end

                else  //IMPOSSIBLE TO HAPPEN
                overdata_next_state = IDLE;  
            end
            
            else if(!overdata_finished_flag)
            begin
                overdata_next_state = OVERDATA_ALU_RESERVED;
            end
            
            else
            begin
                overdata_next_state = IDLE;  
            end
        end

        OVERDATA_RdData_WAITING:
        begin
            if(overdata_finished_flag)
            begin
                overdata_next_state = OVERDATA_RdData_RESERVED;
            end

            else
            begin
                overdata_next_state = OVERDATA_RdData_WAITING;
            end
        end

        OVERDATA_ALU_WAITING:
        begin
            if(overdata_finished_flag)
            begin
                overdata_next_state = OVERDATA_ALU_RESERVED;
            end

            else
            begin
                overdata_next_state = OVERDATA_ALU_WAITING;
            end
        end

        default: overdata_next_state =IDLE;
    endcase
    
end
/////////////////////////////////////////////////////////////////////////////////////////


always @(*)
begin
    if(current_state != IDLE                                     && 
       !(current_state == SEND_RdData_BUSY_FREE    && Busy == 0) &&
       !(current_state == SEND_ALU_OUT_2_BUSY_FREE && Busy == 0) &&
       (RdData_Valid   || OUT_VALID)
      )
    begin
        overdata_flag = 1;
    end

    else
    begin
        overdata_flag = 0;
    end
end


//remove overdata from this block ????????????
//hashed
// always @(posedge clk or negedge reset) 
// begin
//     if(!reset)
//     begin
//         overdata_ALU_flag    <= 0;
//         overdata_RdData_flag <= 0;
//     end

//     else
//     begin
//         if(overdata_flag && !overdata_finished_flag)
//         begin
//             if(RdData_Valid && !OUT_VALID )
//             begin
//                 overdata_ALU_flag    <= 0;
//                 overdata_RdData_flag <= 1;
//             end
            
//             else if(!RdData_Valid && OUT_VALID)
//             begin
//                 overdata_ALU_flag    <= 1;
//                 overdata_RdData_flag <= 0;
//             end

//             else
//             begin
//                 overdata_ALU_flag    <= 0;
//                 overdata_RdData_flag <= 0;
//             end
//         end
        
//         else if(overdata_finished_flag)
//         begin
//             overdata_ALU_flag    <= 0;
//             overdata_RdData_flag <= 0;
//         end
        
//         // else
//         // begin
//         //     overdata_ALU_flag    <= 0;
//         //     overdata_RdData_flag <= 0;
//         // end
            
//     end
// end


always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        TX_P_DATA <= 0;
        TX_D_VLD  <= 0;
    end

    else
    begin
        case (current_state) //next_state or current_state
            IDLE:
            begin
                TX_D_VLD  <= 0;
            end 

            SEND_RdData_BUSY_RESERVED:
            begin
                TX_D_VLD  <= 1;     //هنكمل من هنا ولو في اي فلاج اترفع هنخزن من الريجستر بتاع الاوفر داتا
                
                if(overdata_RdData_flag)
                begin
                    TX_P_DATA <= overdata[DATA_WIDTH-1 : 0];
                    if(Busy)
                    overdata_finished_flag <= 1;

                end

                else
                begin
                    TX_P_DATA <= RdData;
                    overdata_finished_flag <= 0;
                end
                
            end

            SEND_ALU_OUT_1_BUSY_RESERVED:
            begin
                TX_D_VLD  <= 1;

                if(overdata_ALU_flag)
                begin
                    TX_P_DATA <= overdata[DATA_WIDTH-1 : 0];
                    // overdata_finished_flag <= 1;
                end
                

                else
                begin
                    TX_P_DATA <= ALU_OUT[DATA_WIDTH-1 : 0];
                    overdata_finished_flag <= 0;
                end
                
            end
            
            SEND_ALU_OUT_2_BUSY_RESERVED:  ///???????
            begin
                TX_D_VLD  <= 1;

                if(overdata_ALU_flag)
                begin
                    TX_P_DATA <= overdata[2*DATA_WIDTH-1 : DATA_WIDTH];
                    if(Busy)
                    overdata_finished_flag <= 1;
                end

                else
                begin
                    TX_P_DATA <= ALU_OUT[2*DATA_WIDTH-1 : DATA_WIDTH];
                    overdata_finished_flag <= 0;
                end
                
            end
            
            default:begin TX_D_VLD <= 0; overdata_finished_flag <= 0; end ///?????
            //اول ما نرجع هنكرر الفلاج الجديد و هنحط كوندشن ع الفلاجز الاخري معتمد ع الفلاج الجديد
        endcase
    end
end


always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        current_state <= IDLE;
    end

    else
    begin
        current_state <= next_state;
    end
end

always @(*) 
begin
    case (current_state)
        IDLE:
        begin
            if(overdata_RdData_flag)
            begin
                next_state = SEND_RdData_BUSY_WAIT;
            end

            else if (overdata_ALU_flag)
            begin
                next_state = SEND_ALU_OUT_1_BUSY_WAIT;               
            end

            else
            begin
                if(RdData_Valid && !OUT_VALID)
                begin
                   next_state = SEND_RdData_BUSY_WAIT;
                end
            
                else if(!RdData_Valid && OUT_VALID)
                begin
                    next_state = SEND_ALU_OUT_1_BUSY_WAIT;
                end

                else
                begin
                    next_state = IDLE;
                end
            end
            
        end

        SEND_RdData_BUSY_WAIT:
        begin
            if(!Busy)
            next_state = SEND_RdData_BUSY_RESERVED;

            else
            next_state = SEND_RdData_BUSY_WAIT;
        end

        SEND_RdData_BUSY_RESERVED:
        begin
            if(Busy)
            next_state = SEND_RdData_BUSY_FREE;

            else
            next_state = SEND_RdData_BUSY_RESERVED;
        end

        SEND_RdData_BUSY_FREE:  
        begin
            if(!Busy)
            begin
               if(overdata_RdData_flag)
               begin
                   next_state = SEND_RdData_BUSY_WAIT;
               end

               else if (overdata_ALU_flag)
               begin
                   next_state = SEND_ALU_OUT_1_BUSY_WAIT;               
               end

               else
               begin
                   if(RdData_Valid && !OUT_VALID)
                   begin
                       next_state = SEND_RdData_BUSY_WAIT;
                   end
                   else if(!RdData_Valid && OUT_VALID)
                   begin
                       next_state = SEND_ALU_OUT_1_BUSY_WAIT;
                   end
                   else
                   begin
                       next_state = IDLE;
                   end
              end
            end
            
            else
            begin
                next_state = SEND_RdData_BUSY_FREE;
            end
        end
        

        SEND_ALU_OUT_1_BUSY_WAIT:
        begin
            if (!Busy)
            next_state = SEND_ALU_OUT_1_BUSY_RESERVED;
            else
            next_state = SEND_ALU_OUT_1_BUSY_WAIT;
            
        end
        

        SEND_ALU_OUT_1_BUSY_RESERVED:
        begin
            if(Busy)
            next_state = SEND_ALU_OUT_2_BUSY_WAIT;
            else
            next_state = SEND_ALU_OUT_1_BUSY_RESERVED;
        end


        SEND_ALU_OUT_1_BUSY_FREE:
        begin
            if(!Busy)
            next_state = SEND_ALU_OUT_2_BUSY_WAIT;
            else
            next_state = SEND_ALU_OUT_1_BUSY_FREE;
        end


        SEND_ALU_OUT_2_BUSY_WAIT:
        begin
            if(!Busy)
            next_state = SEND_ALU_OUT_2_BUSY_RESERVED;
            else
            next_state = SEND_ALU_OUT_2_BUSY_WAIT;   
        end


        SEND_ALU_OUT_2_BUSY_RESERVED:
        begin
            if(Busy)
            next_state = SEND_ALU_OUT_2_BUSY_FREE;
            else
            next_state = SEND_ALU_OUT_2_BUSY_RESERVED;
        end


        SEND_ALU_OUT_2_BUSY_FREE:
        begin
            if(!Busy)
            begin
               if(overdata_RdData_flag)
               begin
                   next_state = SEND_RdData_BUSY_WAIT;
               end

               else if (overdata_ALU_flag)
               begin
                   next_state = SEND_ALU_OUT_1_BUSY_WAIT;               
               end

               else
               begin
                   if(RdData_Valid && !OUT_VALID)
                   begin
                       next_state = SEND_RdData_BUSY_WAIT;
                   end
                   else if(!RdData_Valid && OUT_VALID)
                   begin
                       next_state = SEND_ALU_OUT_1_BUSY_WAIT;
                   end
                   else
                   begin
                       next_state = IDLE;
                   end
              end
            end
            
            else
            begin
                next_state = SEND_RdData_BUSY_FREE;
            end
        end


        default: next_state = IDLE;
    endcase
    
end

endmodule
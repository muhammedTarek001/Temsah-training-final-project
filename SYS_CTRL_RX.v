module SYS_CTRL_RX #(
    parameter DATA_WIDTH=8,
    REG_NO=16,
    ADDRESS_WIDTH=4,
    
    //commands
    RF_Wr_CMD         = 8'hAA,
    RF_Rd_CMD         = 8'hBB,
    ALU_OPER_W_OP_CMD = 8'hCC,
    ALU_OPER_W_NOP_CMD= 8'hDD,

    //states
    IDLE=0,
    WR_ADD_WAIT  = 8'hAB,
    WR_DATA_WAIT = 8'hAC,

    Rd_ADD_WAIT  = 8'hBC,  

    OpA_WAIT     = 8'hCD,
    OpB_WAIT     = 8'hCE,
    ALU_FUN_WAIT = 8'hCF,
    
    //ALU OPERATIONS
    ADD=0, SUB=1, MUL=2, DIV=3, AND=4, OR=5, NAND=6, 
    NOR=7, XOR=8, XNOR=9, CMPEQ=10, CMPGT=11, CMPLE=12,
    SHR=13, SHL=14

) (
    //from UART_RX
    input [DATA_WIDTH-1 : 0] RX_P_DATA,
    input                    RX_D_VLD,

    input clk,reset,
    
    //to ALU
    output reg       ALU_EN,
    output reg [3:0] ALU_FUN,
    //to clk_gating
    output reg      CLK_EN,
    //to RF
    output reg [ADDRESS_WIDTH-1:0] address,
    output reg                     WrEN,
    output reg [DATA_WIDTH-1 : 0]  WrData,
    output reg                     RdEN,
    //to clk_div
    output reg clk_div_en
);

reg [7:0] next_state, current_state;


always @(posedge clk or negedge reset) 
begin
    if(!reset)
    begin
        current_state <= IDLE;
    end
    else
    begin
        if(RX_D_VLD ) 
        current_state <= next_state;
    end
end



//control signals generation
always @(posedge clk or negedge reset) 
begin
    //we want to register 
    if(!reset)
    begin
        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        address    <= 'b0; //can be x
        WrEN       <= 0;
        WrData     <= 'b0;//can be x
        RdEN       <= 0;
        clk_div_en <= 1;
    end
    
    else
    begin
      case (current_state)
        IDLE:
        begin
            
        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        address    <= 'b0; //can be x
        WrEN       <= 0;
        WrData     <= 'b0;//can be x
        RdEN       <= 0;
        clk_div_en <= 1;
        end 
        
        default:

        if(RX_D_VLD)
        begin
        case (current_state) //next_state or current_state  ???????? 

        WR_ADD_WAIT:
        begin
            address <= RX_P_DATA;

        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        WrEN       <= 0;
        WrData     <= 'b0;//can be x
        RdEN       <= 0;
        clk_div_en <= 1;
        end

        WR_DATA_WAIT:
        begin
            WrEN   <= 1;
            WrData <= RX_P_DATA;

        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        // address    <= 'b0;
        RdEN       <= 0;
        clk_div_en <= 1;
        end

        Rd_ADD_WAIT:
        begin
            RdEN    <= 1;
            address <= RX_P_DATA;

        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        WrEN       <= 0;
        WrData     <= 'b0;//can be x
        clk_div_en <= 1;
        end
        
        OpA_WAIT: //in this state we will store RX_P_DATA in reg0
        begin
            WrEN    <= 1;
            WrData  <= RX_P_DATA;
            address <= 0;

        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        CLK_EN     <= 0;
        RdEN       <= 0;
        clk_div_en <= 1;
        end

        OpB_WAIT:
        begin
            WrEN    <= 1;
            WrData  <= RX_P_DATA;
            address <= 1;
            CLK_EN  <= 1;   //this should be 1 before the arrival of alu_fun frame

        ALU_EN     <= 0;
        ALU_FUN    <= 'b1111; //this code is undefined
        RdEN       <= 0;
        clk_div_en <= 1;
        end

        ALU_FUN_WAIT:
        begin
            ALU_EN <= 1;
            ALU_FUN <= RX_P_DATA;
            CLK_EN  <= 1;

        address    <= 'b0; //can be x
        WrEN       <= 0;
        WrData     <= 'b0;//can be x
        RdEN       <= 0;
        clk_div_en <= 1;
        end

       endcase
      end
            
      endcase

      
        
    end

end



//next state generation
always @(*) 
begin
    case (current_state)
        IDLE:
        begin

            case (RX_P_DATA)
                RF_Wr_CMD:         begin next_state = WR_ADD_WAIT; end 
                RF_Rd_CMD:         begin next_state = Rd_ADD_WAIT; end
                ALU_OPER_W_OP_CMD: begin next_state = OpA_WAIT; end
                ALU_OPER_W_NOP_CMD: begin next_state = ALU_FUN_WAIT; end
                default: next_state = IDLE;
            endcase
                
        end

        WR_ADD_WAIT:
        begin
            next_state = WR_DATA_WAIT;
        end
        
        WR_DATA_WAIT:
        begin
            case (RX_P_DATA) //for consecutive commands
                RF_Wr_CMD:         begin next_state = WR_ADD_WAIT; end 
                RF_Rd_CMD:         begin next_state = Rd_ADD_WAIT; end
                ALU_OPER_W_OP_CMD: begin next_state = OpA_WAIT; end
                ALU_OPER_W_NOP_CMD: begin next_state = ALU_FUN_WAIT; end
                default: next_state = IDLE;
            endcase
        end

        Rd_ADD_WAIT:
        begin
            case (RX_P_DATA) 
                RF_Wr_CMD:         begin next_state = WR_ADD_WAIT; end 
                RF_Rd_CMD:         begin next_state = Rd_ADD_WAIT; end
                ALU_OPER_W_OP_CMD: begin next_state = OpA_WAIT; end
                ALU_OPER_W_NOP_CMD: begin next_state = ALU_FUN_WAIT; end
                default: next_state = IDLE;
            endcase
        end
        
        OpA_WAIT:
        begin
            next_state = OpB_WAIT;
        end

        OpB_WAIT:
        begin
            next_state = ALU_FUN_WAIT;
        end

        ALU_FUN_WAIT:
        begin
            case (RX_P_DATA)
                RF_Wr_CMD:         begin next_state = WR_ADD_WAIT; end 
                RF_Rd_CMD:         begin next_state = Rd_ADD_WAIT; end
                ALU_OPER_W_OP_CMD: begin next_state = OpA_WAIT; end
                ALU_OPER_W_NOP_CMD: begin next_state = ALU_FUN_WAIT; end
                default: next_state = IDLE;
            endcase
        end

        default: next_state = IDLE;
    endcase
end


endmodule
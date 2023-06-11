`timescale 1ns/1ns

module SYS_TOP_tb #(
    parameter DATA_WIDTH=8,
    REG_NO=16,
    ADDRESS_WIDTH=4,
    SYS_period = 20,
    SYS_half_period=0.5*SYS_period,
    UART_period = 10000,
    UART_half_period=0.5*UART_period,
    UART_divided_period = 8*UART_period,

    //commands
    RF_Wr_CMD         = 8'hAA,
    RF_Rd_CMD         = 8'hBB,
    ALU_OPER_W_OP_CMD = 8'hCC,
    ALU_OPER_W_NOP_CMD= 8'hDD,
    
    //ALU OPERATIONS
    ADD=8'd0, SUB=8'd1, MUL=8'd2, DIV=8'd3, AND=8'd4, OR=8'd5, NAND=8'd6, 
    NOR=8'd7, XOR=8'd8, XNOR=8'd9, CMPEQ=8'd10, CMPGT=8'd11, CMPLE=8'd12,
    SHR=8'd13, SHL=8'd14

) ();

reg RX_IN_tb;
reg REF_CLK_tb, UART_CLK_tb, RST_tb;

wire TX_OUT_tb, parity_err_tb, start_err_tb, stop_err_tb;

integer i;
integer temp_value;

integer l;
reg [DATA_WIDTH-1 : 0] net_data;

integer k;
reg [DATA_WIDTH+1 : 0] temp_data, temp_frame;

always #SYS_half_period   REF_CLK_tb = ~REF_CLK_tb;
always #UART_half_period  UART_CLK_tb = ~UART_CLK_tb;

SYS_TOP U0_SYS_TOP(
    .RX_IN(RX_IN_tb),
    .REF_CLK(REF_CLK_tb),
    .UART_CLK(UART_CLK_tb),
    .RST(RST_tb),

    .TX_OUT(TX_OUT_tb),
    .parity_err(parity_err_tb),
    .start_err(start_err_tb),
    .stop_err(stop_err_tb)
);

initial 
begin
    REF_CLK_tb  = 0;
    UART_CLK_tb = 0;
    RST_tb      = 1;
    RX_IN_tb    = 1;
end


//THIS BLOCK IS TO CHECK OUTPUT FRAMES DUE TO READ AND ALU COMMANDS
initial 
begin
    
    check_TX_OUT(10'b1_0_0_01000_1_1);

    check_TX_OUT(10'b1_0_0000_1000);

    check_TX_OUT(10'b1_1_0000_1111);
    check_TX_OUT(10'b1_1_0000_0000);
    
    check_TX_OUT(10'b1_1_0000_0101);
    check_TX_OUT(10'b1_1_1100_0000);

    check_TX_OUT(10'b1_1_0001_0100);
    check_TX_OUT(10'b1_1_0000_0000);

    check_TX_OUT(10'b1_1_0000_1010);

    check_TX_OUT(10'b1_1_0000_0101);
    check_TX_OUT(10'b1_1_1100_0000);

    check_TX_OUT(10'b1_0_0000_0111);

    check_TX_OUT(10'b1_1_0000_0000);
    check_TX_OUT(10'b1_0_0000_0010);

    check_TX_OUT(10'b1_1_0000_1001);

    check_TX_OUT(10'b1_1_0000_0000);
    check_TX_OUT(10'b1_1_0000_0000);

    check_TX_OUT(10'b1_1_1111_1111);
    check_TX_OUT(10'b1_1_1111_1111);

    check_TX_OUT(10'b1_1_0000_0000);
    check_TX_OUT(10'b1_1_0000_0000);

    check_TX_OUT(10'b1_1_1111_1111);
    check_TX_OUT(10'b1_1_1111_1111);
    
    check_TX_OUT(10'b1_0_0000_1000);
    $display("final cmd reached !!!! @time =%d", $time);
end




initial 
begin
    $dumpfile("SYS_TOP.vcd");   
    $dumpvars;
    reset ();
    #UART_divided_period
    
    /////////////////////////config commands//////////////////////////////////////
    //REG2 CONFIG
    send_frame('b1_1010_1010_0);
    send_frame('b1_0000_0010_0);
    send_frame('b1_0_01000_1_1_0); //odd parity bit
    
    
    //REG3 CONFIG
    send_frame('b1_1010_1010_0);
    send_frame('b1_0000_0011_0);
    send_frame('b1_0000_1000_0);
    ///////////////////////////////////////////////////////////////////////////////


    ////////////////////////////////CONFIG TEST////////////////////////////////////
    #UART_divided_period
    if(U0_SYS_TOP.U0_reg_file.reg_bank[2][1] == 1 && U0_SYS_TOP.U0_reg_file.reg_bank[3] == 8)
    begin
        $display("config. assigned successfully !! parity bit = %d @time = %d", U0_SYS_TOP.U0_reg_file.reg_bank[2][1], $time);
    end
    else
    begin
        $display("config. failed !! parity bit = %d @time = %t", U0_SYS_TOP.U0_reg_file.reg_bank[2][1], $time);
    end
    ////////////////////////////////////////
    //READ REG2
    send_frame('b1_1011_1011_0); //RF_Rd_CMD
    send_frame('b1_0000_0010_0);
    
    //READ REG3
    send_frame('b1_1011_1011_0); //RF_Rd_CMD
    send_frame('b1_0000_0011_0);
    //////////////////////////////////////////////////////////////////////////////////
    
    
    ////////////WRITE INTO REG_FILE///////////////////////////////////////////////
    for ( l=4 ; l < REG_NO ; l = l+1) 
    begin
        net_data = l;
        send_frame('b1_1010_1010_0);
        send_frame({1'b1, net_data ,1'b0});
        send_frame({1'b1, net_data ,1'b0}); //odd parity bit 
    end
    //////////////////////////////////////////////////////////////////////////////





    ////////////////////////////////ALU OPERATIONS///////////////////////////////////
    // 10(opA)-5(opB) = 5
    send_frame({1'b1,ALU_OPER_W_OP_CMD,1'b0});
    send_frame({1'b1, 8'b0000_1010 , 1'b0});
    send_frame({1'b1, 8'b0000_0101 , 1'b0});
    send_frame({1'b1, 8'b0000_0000 , 1'b0});

    send_frame({1'b1,ALU_OPER_W_NOP_CMD,1'b0});
    send_frame({1'b1, CMPGT , 1'b0});
    //////////////////////////////////////////////////////////////////////////////////


/////////////////////////////// GENERAL CASES /////////////////////////////////////
    /////TEST 1//////
    send_frame({1'b1,ALU_OPER_W_NOP_CMD,1'b0});
    send_frame({1'b1, SHL , 1'b0});

    send_frame({1'b1, RF_Rd_CMD   , 1'b0});
    send_frame({1'b1, 8'b0000_0000, 1'b0});
    ////////////////
    

    /////////TEST 2 ///////////
    send_frame({1'b1, ALU_OPER_W_OP_CMD,1'b0});
    send_frame({1'b1, 8'b0000_1010     , 1'b0});
    send_frame({1'b1, 8'b0000_0101     , 1'b0});
    send_frame({1'b1, CMPGT            , 1'b0});

    send_frame({1'b1, RF_Rd_CMD   , 1'b0});
    send_frame({1'b1, 8'b0000_0111, 1'b0});
    ///////////////////////////
    
    /////////TEST 3 ///////////
    send_frame({1'b1, ALU_OPER_W_OP_CMD,1'b0});
    send_frame({1'b1, 8'b1000_0000     , 1'b0});
    send_frame({1'b1, 8'b0000_0100     , 1'b0});
    send_frame({1'b1, MUL              , 1'b0});

    send_frame({1'b1, RF_Rd_CMD   , 1'b0});
    send_frame({1'b1, 8'b0000_1001, 1'b0});
    ///////////////////////////
    

    /////////TEST 4 ///////////
    send_frame({1'b1, ALU_OPER_W_OP_CMD,1'b0});
    send_frame({1'b1, 8'b1000_0000     , 1'b0});
    send_frame({1'b1, 8'b0000_0100     , 1'b0});
    send_frame({1'b1, CMPEQ            , 1'b0});

    send_frame({1'b1, ALU_OPER_W_NOP_CMD   , 1'b0});
    send_frame({1'b1, NAND                 , 1'b0});
    ///////////////////////////

    /////////TEST 5 //////////// (SEPARATED FRAMES)
    send_frame({1'b1, ALU_OPER_W_OP_CMD,1'b0});
    #UART_divided_period
    #UART_divided_period
    #UART_divided_period
    send_frame({1'b1, 8'b1000_0000     , 1'b0});
     #UART_divided_period
    #UART_divided_period
    #UART_divided_period
    send_frame({1'b1, 8'b0000_0100     , 1'b0});
     #UART_divided_period
    #UART_divided_period
    #UART_divided_period
    send_frame({1'b1, CMPEQ            , 1'b0});
    #UART_divided_period
    #UART_divided_period
    #UART_divided_period

    send_frame({1'b1, ALU_OPER_W_NOP_CMD   , 1'b0});
     #UART_divided_period
    #UART_divided_period
    #UART_divided_period
    send_frame({1'b1, NAND                 , 1'b0});
    #UART_divided_period
    #UART_divided_period
    #UART_divided_period

    send_frame({1'b1, RF_Rd_CMD   , 1'b0});
    send_frame({1'b1, 8'b0000_1000, 1'b0});
    ///////////////////////////

//////////////////////////////////////////////////////////////////////////////////
end



task send_frame(input [DATA_WIDTH+1 : 0] frame);
begin
    for(i=0; i < DATA_WIDTH+3 ; i=i+1)
    begin
        #UART_divided_period
        if(i == 9) //parity bit location
        begin
            if(U0_SYS_TOP.U0_reg_file.reg_bank[2][0] == 1) //PARITY BIT IS ENABLED
            begin
                if (U0_SYS_TOP.U0_reg_file.reg_bank[2][1] == 1)//PARITY BIT IS odd
                begin
                    RX_IN_tb = ~^frame[8:1];
                    // $display("parity bit is odd, parity_bit = %d  @time= %d !!",RX_IN_tb, $time);//tempo
                end
                else                                           //PARITY BIT IS even
                begin
                    RX_IN_tb = ^frame[8:1];
                    // $display("parity bit is even, parity_bit = %d  @time= %d !!",RX_IN_tb, $time);//tempo

                end
            end
        end
        else
        begin
            if(i == DATA_WIDTH+2)
            RX_IN_tb = frame [i-1];

            else
            RX_IN_tb = frame [i];
        end
    end
end
endtask




task check_TX_OUT (input [DATA_WIDTH+1 : 0] serial_out);
begin
    wait(!TX_OUT_tb)
    $display("tx started to send !! time = %d", $time);
    #5
    for (k = 0; k < DATA_WIDTH+2 ;k=k+1) 
    begin
        #UART_divided_period
        temp_data [k] = TX_OUT_tb;
    end
    
    if(temp_data == serial_out)
        $display("UART_TX sent data successfully, temp_data=%b @time =%d !!",temp_data, $time );

    else
        $display("UART_TX did NOT send data successfully, temp_data=%b, TX_P_DATA= %b @time =%d !!",temp_data, U0_SYS_TOP.TX_D_VLD_sync ,$time );
end
endtask



task reset();
begin
    RST_tb=0;
    #2
    RST_tb=1;
end
endtask

endmodule
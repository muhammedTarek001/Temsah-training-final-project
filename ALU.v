
module ALU #(
    parameter
    DATA_WIDTH=8,

    ADD=0, SUB=1, MUL=2, DIV=3, AND=4, OR=5, NAND=6, 
    NOR=7, XOR=8, XNOR=9, CMPEQ=10, CMPGT=11, CMPLE=12,
    SHR=13, SHL=14
)(
input [DATA_WIDTH-1:0]A,B,
input [3:0]ALU_FUN, //its value not known-->> ALU_OUT=16'b0
input Enable,

input clk, reset,
output reg [2*DATA_WIDTH-1:0] ALU_OUT,
output reg OUT_VALID  //??????????
);  

  wire subFlag;
  wire [2*DATA_WIDTH-1:0]  Result, addendOrSubbed;
  
  reg [2*DATA_WIDTH-1:0] ALU_OUT_wire;
  reg OUT_VALID_wire;

  always@(posedge clk or negedge reset)
  begin
    if(!reset)
    begin
        ALU_OUT <=0;
        OUT_VALID<=0;
    end

    else
    begin
        if(Enable)  
        begin
            ALU_OUT   <= ALU_OUT_wire;
        end

        OUT_VALID <= OUT_VALID_wire;
    end
  end
  
  assign subFlag=(ALU_FUN == 4'b0000)? 0:1;
  
  assign addendOrSubbed=B ^ { (2*DATA_WIDTH){subFlag} };
  assign Result=A+addendOrSubbed+subFlag;
  
  
  always@(*)
  begin 
    
    if(Enable)
    begin
      
      case(ALU_FUN)
      ADD:ALU_OUT_wire      = Result;
      SUB: ALU_OUT_wire     = Result;
      
      MUL: ALU_OUT_wire      = A*B;
      DIV: ALU_OUT_wire = A/B;
      AND: ALU_OUT_wire      = A&B;
      OR: ALU_OUT_wire       = A|B;
      NOR: ALU_OUT_wire      = ~(A|B);
      NAND: ALU_OUT_wire     = ~(A&B);
      XOR: ALU_OUT_wire      = A^B;
      XNOR: ALU_OUT_wire     = ~(A^B);
      
      CMPEQ:begin if(A==B) ALU_OUT_wire=1; else ALU_OUT_wire=0; end
      CMPGT:begin if(A > B) ALU_OUT_wire='b1100_0000_0000_0101; else ALU_OUT_wire=0; end
      CMPLE:begin if(A < B) ALU_OUT_wire=3; else ALU_OUT_wire=0; end

      SHR: ALU_OUT_wire = A>>1;
      SHL: ALU_OUT_wire = A<<1;
      
      default:ALU_OUT_wire='b0;
      endcase
      
      OUT_VALID_wire =1;
    end

    else
    begin
        ALU_OUT_wire   =0;
        OUT_VALID_wire =0;

    end
    
      
    
    
  end
  
  
endmodule


module Multiplier_STG_0(product,Ready,word1,word2,Start,clock,reset);
parameter                L_word = 4;
output    [2*L_word-1:0]  product;
output                   Ready;
input     [L_word-1:0]   word1,word2;
input                    Start,clock,reset;
wire                     m0,Load_words,Shift;
Datapath M1(product,m0,word1,word2,Load_words,Shift,Add,clock,reset);
Controller M2(L_words,Shift,Add,Ready,m0,Start,clock,reset);
endmodule

module Controller(Load_words,Shift,Add,Ready,m0,Start,clock,reset);
parameter                 L_word=4;
parameter                 L_state=4;
output                    Load_words,Shift,Add,Ready;
input                     m0,Start,clock,reset;
reg       [L_state-1:0]   state,next_state;
parameter                 S_idle = 0,S_1=1,S_2=2;
parameter                 S_3=3,S_4=4,S_5=5,S_6=6;
parameter                 S_7 = 7,S_8 = 8;
reg                       Load_words,Shift,Add;
wire                      Ready = ((state == S_idle) && !reset) || (state == S_8);
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state <= next_state;
end

always @(state or Start or m0) begin
    Load_words=0;
    Shift=0;
    Add=0;
    case (state)
        S_idle: 
        if(Start) begin
          Load_words=1;
          next_state= S_2;
        end 
        else next_state=S_idle;
        S_1:
        if(m0) begin
          Add=1;
          next_state= S_2;
        end 
        else begin
          Shift=1;
          next_state=S_3;
        end
        S_2:
        begin
          Shift=1;
          next_state=S_3;
        end
        S_3:
        if(m0) begin
          Add=1;
          next_state= S_4;
        end 
        else begin
          Shift=1;
          next_state=S_5;
        end
        S_4:
        begin
          Shift=1;
          next_state=S_5;
        end
        S_5:
        if(m0) begin
          Add=1;
          next_state= S_6;
        end 
        else begin
          Shift=1;
          next_state=S_7;
        end
        S_6:
        begin
          Shift=1;
          next_state=S_7;
        end
        S_7:
        if(m0) begin
          Add=1;
          next_state= S_8;
        end 
        else begin
          Shift=1;
          next_state=S_8;
        end
        S_8:
        if(Start) begin
          Load_words=1;
          next_state= S_1;
        end 
        else begin
          next_state=S_8;
        end
        default: next_state=S_8;
    endcase
end
endmodule

module Datapath(product,m0,word1,word2,Load_words,Shift,Add,clock,reset);
parameter                   L_word = 4;
output     [2*L_word-1:0]   product;
output                      m0;
input      [L_word-1:0]     word1,word2;
input                       Load_words,Shift,Add,clock,reset;
reg        [2*L_word-1:0]   product,multiplicand;
reg        [L_word-1:0]     multiplier;
wire                        m0=multiplier[0];
always @(posedge clock or posedge reset) begin
    if(reset) begin
      multiplier <= 0;
      multiplicand <= 0;
      product <= 0;
    end
    else if(Load_words) begin
      multiplicand <= word1;
      multiplier <= word2;
      product <= 0;
    end
    else if(Shift) begin
      multiplier <= multiplier >>1;
      multiplicand <= multiplicand <<1;
    end  
    else if(Add)  
      product <= product+multiplicand;
end
endmodule

module test_Multiplier_STG_0();
parameter               L_word=4;
wire     [2*L_word-1:0] product;
wire                    Ready;
integer                 word1,word2;//被乘数,乘数
reg                     Start,clock,reset;
Multiplier_STG_0 M1 (product,Ready,word1,word2,Start,clock,reset);//详细测试平台
reg       [2*L_word-1:0]  expected_value;
reg                       code_error;
initial #80000 $finish;//超时
always @(posedge clock)   //将乘机与期望值比较
  if(Start) begin
    #5  expected_value = 0;
    expected_value = word2*word1;
    //expected_value = word2*word1+1;//用来进行错误检测
    code_error=0;
  end
  else begin
    code_error=(M1.M2.state== M1.M2.S_8) ?|(expected_value ^ product):0;
  end

initial begin
    clock=0;
    forever #10 clock=~clock;
end
initial begin
    #2 reset =1;
    #15 reset=0;
end
initial begin
    #5 Start=1;
    #10 Start=15;
end
initial begin
    for(word1=0;word1 <= 15;word1=word1+1)begin
      for(word2=0;word2<=15;word2=word2+1) begin
        Start=0;
        #40 Start=1;
        #20 Start=0;
        #200;
      end
      #140;
    end
end
initial begin
    $dumpfile("test_Multiplier_STG_0.vcd");        //生成的vcd文件名称
    $dumpvars(0, test_Multiplier_STG_0);    //tb模块名称
end
endmodule
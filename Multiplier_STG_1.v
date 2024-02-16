module Multiplier_STG_1(product,Ready,word1,word2,Start,clock,reset);
parameter                  L_word=4;
output     [2*L_word-1:0]  product;
output                     Ready;
input      [L_word-1:0]    word1,word2;
input                      Start,clock,reset;
wire                       m0,Empty,Load_words,Shift,Add_shift;
wire                       Ready;
Datapath M1(product,m0,Empty,word1,word2,Ready,Start,Load_words,Shift,Add_shift,clock,reset);
Controller M2(Load_words,Shift,Add_shift,Ready,m0,Empty,Start,clock,reset);
endmodule
module Controller(Load_words,Shift,Add_shift,Ready,m0,Empty,Start,clock,reset);
parameter               L_word = 4;
parameter               L_state = 3;
output                  Load_words,Shift,Add_shift,Ready;
input                   Empty;
input                   m0,Start,clock,reset;
reg     [L_state-1:0]   state,next_state;
parameter               S_idle = 0,S_1=1,S_2=2,S_3=3,S_4=4,S_5=5;
reg                     Load_words,Shift,Add_shift;
wire                    Ready=((state == S_idle)&&!reset) || (state==S_5);
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state  <= next_state;
end
always @(state or Start or m0 or Empty) begin
    Load_words=0;
    Shift = 0;
    Add_shift = 0;
    case (state)
        S_idle:
        begin
          if(Start && Empty)next_state=S_5;
          else if(Start) begin
            Load_words=1;
            next_state=S_1;
          end
          else
          next_state=S_idle;
        end 
        S_1:
        begin
          if(m0)
          Add_shift=1;
          else 
          Shift=1;
          next_state=S_2;
        end
        S_2:
        begin
          if(m0)
          Add_shift=1;
          else 
          Shift=1;
          next_state=S_3;
        end
        S_3:
        begin
          if(m0)
          Add_shift=1;
          else 
          Shift=1;
          next_state=S_4;
        end
        S_4:
        begin
          if(m0)
          Add_shift=1;
          else 
          Shift=1;
          next_state=S_5;
        end
        S_5:
        begin
          if(Empty) next_state=S_5;
          else if(Start)
          begin
            Load_words=1;
            next_state=S_1;
          end
          else 
          next_state=S_5;
        end
        default: next_state=S_idle;
    endcase
end
endmodule
module Datapath(product,m0,Empty,word1,word2,Ready,Start,Load_words,Shift,Add_shift,clock,reset);
parameter                  L_word = 4;
output   [2*L_word-1:0]    product;
output                     m0,Empty;
input    [L_word-1:0]      word1,word2;
input                      Ready,Start,Load_words,Shift;
input                      Add_shift,clock,reset;
reg      [2*L_word-1:0]    product,multiplicand;
reg      [L_word-1:0]      multiplier;
wire                       m0=multiplier[0];
wire                       Empty=(~|word1)||(~|word2);
always @(posedge clock or posedge reset) begin
    if(reset) begin
      multiplier <= 0;
      multiplicand <= 0;
      product <= 0;
    end
    else if(Start && Empty && Ready)
    product <= 0;
    else if(Load_words)
    begin
      multiplicand <= word1;
      multiplier <= word2;
      product <= 0;
    end
    else if(Shift)
    begin
      multiplier <= multiplier >> 1;
      multiplicand <= multiplicand << 1;
    end
    else if(Add_shift)
    begin
      product <= product+multiplicand;
      multiplier <= multiplier >> 1;
      multiplicand <= multiplicand << 1;
    end
end
endmodule
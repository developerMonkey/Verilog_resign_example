//基于ASMD的高效时序二进制乘法器
module Multiplier_ASM_1(product,Ready,word1,word2,Start,clock,reset);
parameter                   L_word=4;
output    [2*L_word-1:0]    product;
output                      Ready;
input     [L_word-1:0]      word1,word2;
input                       Start,clock,reset;
reg                         state,next_state;
reg       [2*L_word-1:0]    multiplicand;
reg       [L_word-1:0]      multiplier;
reg                         product,Load_words;
reg                         Flush,Shift,Add_shift;
parameter                   S_idle=0,S_running=1;
wire                        Empty=(word1 == 0)||(word2 ==2);
wire                        Ready=(state == S_idle) && (!reset);  
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state<=next_state;
end

always @(state or Start or Empty or multiplier) begin
    Flush=0;
    Load_words=0;
    Shift = 0;
    Add_shift=0;
    case (state)
        S_idle: 
        begin
          if(!Start) next_state=S_idle;
          else if(Empty) begin
            next_state=S_idle;
            Flush=1;
          end
          else begin
            Load_words = 1;
            next_state=S_running;
          end
        end
        S_running: 
        begin
          if(~|multiplier) next_state=S_idle;
          else if(multiplier==1)
          begin
            Add_shift=1;
            next_state=S_idle;
          end
          else if(multiplier[0])
          begin
            Add_shift=1;
            next_state=S_running; 
          end
          else 
          begin 
            Shift=1;
            next_state=S_running;
          end
        end
        default: next_state=S_idle;
    endcase
end

always @(posedge clock or posedge reset) begin
    if(reset)
    begin
      multiplier <= 0;
      multiplicand <= 0;
      product <= 0;
    end
    else begin
      if(Flush)  product <= 0;
      else if(Load_words==1)
      begin 
        multiplicand <= word1;
        multiplier <= word2;
        product <= 0;
      end
      else if(Shift) begin
        multiplicand <= multiplicand << 1;
        multiplier <= multiplier >> 1;
      end
      else if(Add_shift) begin
        product <= product+multiplicand;
        multiplier <= multiplier >> 1;
      end
    end
end
endmodule
module Multiplier_ASM_0(product,Ready,word1,word2,Start,clock,reset);
parameter                L_word = 4;
output  [2*L_word-1:0]   product;
output                   Ready;
input   [L_word-1:0]     word1,word2;
input                    Start,clock,reset;
reg    [1:0]             state,next_state;
reg    [2*L_word-1:0]    multiplicand;
reg    [L_word-1:0]      multiplier;
reg                      product;
reg                      Flush,Load_words,Shift,Add;
parameter                S_idle = 0,S_shifting=1,S_adding=2,S_done=3;
wire                     Empty=((word1 == 0) || (word2 == 0));
wire                     Ready = ((state == S_idle) && !reset)||(state==S_done);
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state <= next_state;
end
always @(state or Start or Empty or multiplier) begin
    Flush=0;
    Load_words=0;
    Shift=0;
    Add=0;
    case (state)
        S_idle: 
        begin
          if (!Start) begin
            next_state=S_idle;
          end  
          else if(Start && !Empty)
          begin
            Load_words=1;
            next_state=S_shifting;
          end  
          else if (Start && Empty) begin
            Flush=1;
            next_state=S_done;
          end
          
        end
        S_shifting:
        begin
          if (multiplier == 1) begin
            Add=1;
            next_state=S_done;
          end  
          else if(multiplier[0])
          begin
            Add=1;
            next_state=S_shifting;
          end  
          else if (Start && Empty) begin
            Shift=1;
            next_state=S_shifting;
          end
        end
        S_adding:
        begin
          Shift=1;
          next_state=S_shifting;
        end
        S_done:
        begin
          if(Start == 0)
          next_state=S_done;
          else if(Empty)
          begin
            Flush=1;
            next_state=S_done;
          end
          else 
          begin
            Load_words=1;
            next_state=S_shifting;
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
    else if (Flush) begin
        product <= 0;
    end
    else if(Load_words == 1)
    begin
      multiplicand <= word1;
      multiplier <= word2;
    end
end
endmodule
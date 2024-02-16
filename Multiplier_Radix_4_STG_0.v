`define All_Ones       8'b1111_1111
`define All_Zeros      8'b0000_0000
module Multiplier_Radix_4_STG_0(product,Ready,word1,word2,Start,clock,reset);
parameter                    L_word = 8;
output    [2*L_word-1:0]     product;
output                       Ready;
input     [L_word-1:0]       word1,word2;
input                        Start,clock,reset;
wire                         Load_words,Shift,Add_sub,Ready;
wire      [2:0]              BPEB;
Datapath_Radix_4_STG_0 M1 (product,BPEB,word1,word2,Load_words,Shift_1,Shift_2,Add,Sub,clock,reset);
Controller_Radix_4_STG_0 M2 (Load_words,Shift_1,Shift_2,Add,Sub,Ready,BPEB,Start,clock,reset);
endmodule

module Datapath_Radix_4_STG_0 (product,BPEB,word1,word2,Load_words,Shift_1,Shift_2,Add,Sub,clock,reset);
parameter                          L_word = 8;
output      [2*L_word-1:0]         product;
output      [2:0]                  BPEB;
input       [L_word-1:0]           word1,word2;
input                              Load_words,Shift_1,Shift_2;
input                              Add,Sub,clock,reset;
reg         [2*L_word-1:0]         product,multiplicand;
reg         [L_word-1:0]           multiplier;
reg                                m0_del;
wire        [2:0]                  BPEB={multiplier[1:0],m0_del};
always @(posedge clock or posedge reset) begin
    if(reset)begin
      multiplier <= 0;
      m0_del <= 0;
      multiplicand <= 0;
      product <= 0;
    end
    else if(Load_words)begin
      m0_del <= 0;
      if(word1[L_word-1]==0) multiplicand <= word1;
      else multiplicand <= {`All_Ones,word1[L_word-1:0]};
      multiplier <= word2;
      m0_del <= 0;
      product <= 0;
    end
    else if(Shift_1)begin 
        {multiplier,m0_del} <= {multiplier,m0_del}>1;
        multiplicand <= multiplicand <<1;
    end
    else if(Shift_2)begin 
        {multiplier,m0_del} <= {multiplier,m0_del}>>2;
        multiplicand <= multiplicand <<2;
    end
    else if(Add)begin 
        product <= product+multiplicand;
    end
    else if(Sub)begin 
        product <= product-multiplicand;
    end
end
endmodule

module Controller_Radix_4_STG_0(Load_words,Shift_1,Shift_2,Add,Sub,Ready,BPEB,Start,clock,reset);
parameter                      L_word = 8;
output                         Load_words,Shift_1,Shift_2,Add,Sub,Ready;
input                          Start,clock,reset;
input          [2:0]           BPEB;
reg            [4:0]           state,next_state;
parameter                      S_idle = 0,S_1 = 1,S_2 = 2,S_3 = 3;
parameter                      S_4 = 4,S_5 = 5,S_6 = 6,S_7 = 7,S_8 = 8;
parameter                      S_9 = 9,S_10 = 10,S_11 = 11,S_12 = 12;
parameter                      S_13 = 13,S_14 = 14,S_15 = 15;
parameter                      S_16 = 16,S_17 = 17;
reg                            Load_words,Shift_1,Shift_2,Add,Sub;
wire                           Ready=((state == S_idle) && !reset) || (next_state == S_17);
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state <= next_state;
end
always @(state or Start or BPEB) begin
    Load_words = 0;
    Shift_1 = 0;
    Shift_2 = 0;
    Add = 0;
    Sub = 0;
    case (state)
        S_idle: 
        if (Start) begin
            Load_words=1;
            next_state=S_1;
        end
        else next_state=S_idle;
        S_1:
        case (BPEB)
            0: begin
              Shift_2=1;
              next_state=S_5;
            end 
            2: begin
              Add=1;
              next_state=S_2;
            end
            4: begin
              Shift_1=1;
              next_state=S_3;
            end
            6: begin
              Sub=1;
              next_state=S_2;
            end
            default: next_state=S_idle;
        endcase
        S_2:
        begin
            Shift_2=1;
            next_state=S_5;
        end
        S_3:
        begin
            Sub=1;
            next_state=S_4;
        end
        S_4:
        begin
            Shift_1=1;
            next_state=S_5;
        end
        S_5:
        case (BPEB)
            0,7: begin
              Shift_2=1;
              next_state=S_9;
            end 
            1,2: begin
              Add=1;
              next_state=S_6;
            end
            3,4: begin
              Shift_1=1;
              next_state=S_7;
            end
            5,6: begin
              Sub=1;
              next_state=S_6;
            end
        endcase
        S_6:
        begin
            Shift_2=1;
            next_state=S_9;
        end
        S_7:
        begin
          if(BPEB[1:0]==2'b01) Add=1;
          else Sub=1;
               next_state=S_8;
        end
        S_8:
        begin
            Shift_1=1;
            next_state=S_9;
        end
        S_9:
        case (BPEB)
            0,7: begin
              Shift_2=1;
              next_state=S_13;
            end 
            1,2: begin
              Add=1;
              next_state=S_10;
            end
            3,4: begin
              Shift_1=1;
              next_state=S_11;
            end
            5,6: begin
              Sub=1;
              next_state=S_10;
            end
        endcase
        S_10:
        begin
            Shift_2=1;
            next_state=S_13;
        end
        S_11:
        begin
          if(BPEB[1:0] == 2'b01) Add=1;
          else Sub=1; next_state=S_12;
        end
        S_12:
        begin
            Shift_1=1;
            next_state=S_13;
        end
        S_13:
        case (BPEB)
            0,7: begin
              Shift_2=1;
              next_state=S_17;
            end 
            1,2: begin
              Add=1;
              next_state=S_14;
            end
            3,4: begin
              Shift_1=1;
              next_state=S_15;
            end
            5,6: begin
              Sub=1;
              next_state=S_14;
            end
        endcase
        S_14:
        begin
            Shift_2=1;
            next_state=S_17;
        end
        S_15:
        begin
          if(BPEB[1:0] == 2'b01) Add=1;
          else Sub=1; next_state=S_16;
        end
        S_16:
        begin
            Shift_1=1;
            next_state=S_17;
        end
        S_17:
        begin
          if(Start) begin
            Load_words=1;
            next_state=S_17;
          end
          else  next_state=S_17;
        end
        default:  next_state = S_17;
    endcase
end
endmodule

module Divider_STG_0(quotient,remainder,Ready,Error,word1,word2,Start,clock,reset);
parameter                      L_divn = 8;
parameter                      L_divr = 4;
parameter                      S_idle = 0,S_1=1,S_2=2,S_3=3,S_Err=4;
parameter                      L_state = 3;
output         [L_divn-1:0]    quotient;
output         [L_divn-1:0]    remainder;
output                         Ready,Error;
input          [L_divn-1:0]    word1;
input          [L_divr-1:0]    word2;
input                          Start,clock,reset;
reg            [L_state-1:0]   state,next_state;
reg                            Load_words,Subtract;
reg            [L_divn-1:0]    dividend;
reg            [L_divr-1:0]    divisor;
reg                            quotient;
wire                           GTE=(dividend >= divisor);
wire                           Ready=((state == S_idle) && !reset) || (state == S_3);
wire                           Error= (state == S_Err);
assign                         remainder=dividend;
always @(posedge clock or posedge reset) begin
    if(reset) state <= S_idle;
    else state <= next_state;
end
always @(state or word1 or word2 or Start or GTE) begin
    Load_words=0;
    Subtract=0;
    case(state)
    S_idle:
    case (Start)
        0: next_state = S_idle;
        1:if(word2==0) next_state=S_Err;
          else if(word1) begin
            next_state=S_1;
            Load_words=1;
          end
          else next_state=S_3;
    endcase
    S_1:
    if(GTE) begin
      next_state = S_2;
      Subtract=1;
    end
    else next_state=S_3;
    S_2:
    if (GTE) begin
        next_state=S_2;
        Subtract=1;
    end
    else next_state=S_3;
    S_3:
    case (Start)
        0: next_state=S_3;
        1:
        if(word2) next_state=S_Err;
        else if(word1==0)next_state=S_3;
        else begin next_state=S_1;Load_words=1; end
    endcase
    S_Err:next_state=S_Err;
    default:next_state=S_Err;
    endcase
end
always @(posedge clock or posedge reset) begin
  if(reset) begin
    divisor <= 0;
    dividend <= 0;
    quotient <= 0;
  end
  else if(Load_words == 1) begin
    dividend <= word1;
    divisor <= word2;
    quotient <= 0;
  end
  else if(Subtract) begin 
    dividend <= dividend[L_divn-1:0]+1'b1+{{(L_divn-L_divr){1'b1}},~divisor[L_divr-1:0]};
    quotient <= quotient +1;
  end
end
endmodule

module Divider_STG_0_sub(quotient,remainder,Ready,Error,word1,word2,Start,clock,reset);
parameter                    L_divn = 8;
parameter                    L_divr = 4;
parameter                    S_idle = 0,S_1=1,S_2=2,S_3=3,S_Err=4;
parameter                    L_state = 3;
output     [L_divn-1:0]      quotient;
output     [L_divn-1:0]      remainder;
output                       Ready,Error;
input      [L_divn-1:0]      word1;
input      [L_divr-1:0]      word2;
input                        Start,clock,reset;
reg        [L_state-1:0]     state,next_state;
reg                          Load_words,Subtract;
reg        [L_divn-1:0]      dividend;
reg        [L_divr-1:0]      divisor;
reg                          quotient;
wire                         Ready=((state == S_idle) && !reset) || (state == S_3);
wire                         Error=(state == S_Err);
wire       [L_divn-1:0]      difference;
wire                         carry;
assign                       {carry,difference} = dividend[L_divn-1:0]+{{(L_divn-L_divr){1'b1}},~divisor[L_divr-1:0]}+1'b1;
assign                       remainder=dividend;
always @(posedge clock or posedge reset) begin
  if(reset) state <= S_idle;
  else state <= next_state;
end
always @(state or word1 or word2 or Start or carry) begin
  Load_words=0;
  Subtract=0;
  case (state)
    S_idle:begin
      case (Start)
      0:next_state=S_idle;
      1:if(word2==0)next_state=S_Err;
        else if(word1) begin 
          next_state=S_1;
          Load_words=1;
        end
        else next_state=S_3;
      endcase
      end 
    S_1:if(!carry) next_state=S_3;
        else begin
          next_state=S_2;
          Subtract=1;
        end  
    S_2:begin
      if(!carry) next_state=S_3;
      else begin
        next_state=S_3;
        Subtract=1;
      end
    end 
    S_3:case (Start)
      0: next_state=S_3;
      1:if(word2==0) next_state=S_Err;
        else if(word1==0) next_state=S_3;
        else  begin
          next_state=S_1;
          Load_words=1;
        end
    endcase   
    S_Err:next_state=S_Err;
    default: next_state=S_Err;
  endcase
end
always @(posedge clock or posedge reset) begin
  if(reset) begin
    divisor <= 0;
    dividend <= 0;
    quotient <= 0;
  end
  else if(Load_words==1) begin
    dividend <= word1;
    divisor <= word2;
    quotient <= 0;
  end
  else if(Subtract) begin
    dividend <= difference;
    quotient <= quotient+1;
  end
end
endmodule

module Divider_STG_1(quotient,remainder,Ready,Error,word1,word2,Start,clock,reset);
parameter                           L_divn = 8;
parameter                           L_divr = 4;
parameter                           S_idle = 0,S_Adivr=1,S_Adivn=2,S_div=3,S_Err=4;
parameter                           L_state = 3,L_cnt=4,Max_cnt=L_divn-L_divr;
output        [L_divn-1:0]          quotient;
output        [L_divn-1:0]          remainder;
output                              Ready,Error;
input         [L_divn-1:0]          word1;
input         [L_divr-1:0]          word2;
input                               Start,clock,reset;
reg           [L_state-1:0]         state,next_state;
reg                                 Load_words,Subtract,Shift_dividend,Shift_divisor;
reg           [L_divn-1:0]          quotient;
reg           [L_divn-1:0]          dividend;
reg           [L_divr-1:0]          divisor;
reg           [L_cnt-1:0]           num_shift_dividend,num_shift_divisor;
reg           [L_divr:0]            comparison;
wire                                MSB_divr=divisor[L_divr-1];
wire                                Ready=((state == S_idle) && !reset);
wire                                Error=(state==S_Err);
wire                                Max=(num_shift_dividend == Max_cnt+num_shift_divisor);
wire                                sign_bit=comparison[L_divr];
always @(state or dividend or divisor or MSB_divr) begin
  case (state)
    S_Adivr:
    if (MSB_divr==0) begin
      comparison=dividend[L_divn:L_divn-L_divr]+{1'b1,~(divisor<<1)}+1'b1;
    end
    else comparison=dividend[L_divn:L_divn-L_divr]+{1'b1,~divisor[L_divr-1:0]}+1'b1;
    default: comparison=dividend[L_divn:L_divn-L_divr]+{1'b1,~divisor[L_divr-1:0]}+1'b1;
  endcase
  
end

always @(posedge clock or posedge reset) begin
  if(reset) state<=S_idle;
  else state <= next_state;
end

always @(state or word1 or word2 or Start or comparison or sign_bit or Max) begin
  Load_words=0;
  Shift_dividend=0;
  Shift_divisor=0;
  Subtract=0;
  case (state)
    S_idle: 
    case(Start)
    0:next_state=S_idle;
    1:if(word2==0) next_state=S_Err;
      else if(word1) begin
        next_state=S_Adivr;
        Load_words=1;
      end
      else next_state=S_idle;   
    endcase  
    S_Adivr:
    case(MSB_divr)
    0:if(sign_bit==0) begin
      next_state=S_Adivr;
      Shift_divisor=1;
    end
      else if(sign_bit==1) begin
        next_state=S_Adivn;
      end
      else next_state=S_Adivn;
    
    1:next_state=S_div;
    endcase 
    S_Adivn:
    case ({Max,sign_bit})
      2'b00: next_state=S_div;
      2'b01: begin
        next_state=S_Adivn;
        Shift_dividend=1;
      end
      2'b10: 
      begin
        next_state=S_idle;
        Subtract=1;
      end
      2'b11: next_state=S_idle;
    endcase
    S_div:
    case ({Max,sign_bit})
      2'b00: begin
        next_state=S_div;
        Subtract=1;
      end 
      2'b01: begin
        next_state=S_Adivn;
      end
      2'b10: 
      begin
        next_state=S_div;
        Subtract=1;
      end
      2'b11: begin
        next_state=S_div;
        Shift_dividend=1;
      end
    endcase
    default:next_state=S_Err;
  endcase
end
always @(posedge clock or posedge reset) begin
  if(reset)begin
    divisor<=0;
    dividend <= 0;
    quotient <= 0;
    num_shift_dividend <= 0;
    num_shift_divisor <= 0;
  end
  else if(Load_words==1) begin
    dividend <= word1;
    divisor<=word2;
    quotient <= 0;
    num_shift_dividend <= 0;
    num_shift_divisor <= 0;
  end
  else if(Shift_divisor)begin
    divisor<=divisor<<1;
    num_shift_divisor <= num_shift_divisor+1;
  end
  else if(Shift_dividend)begin
    dividend <= word1;
    quotient <= 0;
    num_shift_dividend <= num_shift_dividend+1;
  end
  else if(Subtract)begin
    dividend[L_divn:L_divn-L_divr] <= comparison;
    quotient[0]<=1;
  end
end
endmodule

module test_Divider_STG_1();
parameter                        L_divn = 8;
parameter                        L_divr = 4;
parameter                        word_1_max = 255;
parameter                        word_1_min = 1;
parameter                        word_2_max = 15;
parameter                        word_2_min = 1;
parameter                        max_time = 850000;
parameter                        half_cycle = 10;
parameter                        start_duration = 20;
parameter                        start_offset = 30;
parameter                        delay_for_exhaustive_patterns = 490;
parameter                        reset_offset = 50;
parameter                        reset_toggle = 5;
parameter                        reset_duration = 20;
parameter                        word_2_delay = 20;
wire      [L_divn-1:0]           quotient;
wire      [L_divn-1:0]           remainder;
wire                             Ready,Div_zero;
integer                          word1;
integer                          word2;
reg                              Start,clock,reset;
reg       [L_divn-1:0]           expected_value;
reg       [L_divn-1:0]           expected_remainder;
wire                             quotient_error,rem_error;
integer                          k,m;
wire      [L_divr-1:0]           Left_bits=M1.dividend[L_divn-1:L_divn-L_divr];
Divider_STG_1 M1(quotient,remainder,Ready,Error,word1,word2,Start,clock,reset);
initial #max_time $finish;
initial begin
  clock=0;
  forever #half_cycle clock=~clock;
end
assign quotient_error=(!reset && Ready) ?|(expected_value ^quotient):0;
assign rem_error=(!reset && Ready) ?| (expected_remainder ^ remainder):0;
initial begin
  #2 reset=1;
  #15 reset=0;Start=0;
  #10 Start=1; 
  #5  Start=0;
end
initial begin
  #reset_offset reset=1;
  #reset_toggle Start=1;
  #reset_toggle reset=0;
  word1=0;
  word2=1;
  while (word2 <= word_2_max) #20 word2=word2+1;
  #start_duration Start=0;
end
initial begin
  #delay_for_exhaustive_patterns
  word1=word_1_min;
  while (word1 <= word_1_max) begin
    word2=1;
    while(word2 <= 15)begin
      #0 Start=0;
      #start_offset Start=1;
      #start_duration Start=0;
    @(posedge Ready) #0;
    word2=word2+1;end
    word1=word1+1;end  
end
endmodule  

module Divider_RR_STG(quotient,remainder,Ready,Error,word1,word2,Start,clock,reset);
parameter                                      L_divn = 8;
parameter                                      L_divr = 4;
parameter                                      S_idle = 0,S_Adivr=1,S_ShSub=2,S_Rec=3,S_Err=4;
parameter                                      L_state = 3,L_cnt=4,Max_cnt=L_divn-L_divr;
parameter                                      L_Rec_Ctr=3;
output          [L_divn-1:0]                   quotient;
output          [L_divr-1:0]                   remainder;
output                                         Ready,Error;
input           [L_divn-1:0]                   word1;
input           [L_divr-1:0]                   word2;
input                                          Start,clock,reset;
reg             [L_state-1:0]                  state,next_state,Load_words,Subtract_and_Shift,Subtract,Shift_dividend,Shift_divisor,Flush_divr,Xfer_Rem;
reg             [L_divn-1:0]                   dividend;
reg             [L_divr-1:0]                   divisor;
reg             [L_cnt-1:0]                    num_shift_dividend,num_shift_divisor;
reg             [L_Rec_Ctr-1:0]                Rec_Ctr;
reg             [L_divr:0]                     comparison;
wire                                           MSB_divr=divisor[L_divr-1];
wire                                           Ready=((state==S_idle)&& !reset);
wire                                           Error=(state == S_Err);
wire                                           Max=(num_shift_dividend == Max_cnt+num_shift_divisor);
always @(state or dividend or divisor or MSB_divr) begin
  case (state)
    S_ShSub: 
    comparison=dividend[L_divn+1:L_divn-L_divr+1]+{1'b1,~divisor[L_divr-1:0]}+1'b1; 
    default: begin
    if(MSB_divr==0)
    comparison=dividend[L_divn+1:L_divn-L_divr+1]+{1'b1,~(divisor << 1)}+1'b1;
    else
    comparison=dividend[L_divn+1:L_divn-L_divr+1]+{1'b1,~divisor[L_divr-1:0]}+1'b1;
    end
  endcase 
end
wire                         sign_bit=comparison[L_divr];
wire                         overflow=Subtract_and_Shift && ((dividend[0]==1) || (num_shift_dividend == 0)); 
assign                       quotient=((divisor==1) && (num_shift_divisor==0))?dividend[L_divn:1]:(num_shift_divisor==0)?dividend[L_divn-L_divr:0]:dividend[L_divn+1:0];
assign                       remainder=(num_shift_divisor==0)?(divisor==1)?0:(dividend[L_divn:L_divn-L_divr+1]):divisor;
always @(posedge clock or posedge reset) begin
  if(reset) state <= S_idle;
  else state <= next_state;
end
always @(state or word1 or word2 or divisor or Start or comparison or sign_bit or Max or Rec_Ctr) begin
  Load_words=0;
  Shift_dividend=0;
  Shift_divisor=0;
  Subtract_and_Shift=0;
  Subtract=0;
  Flush_divr=0;
  Flush_divr=0;
  Xfer_Rem=0;
  case (state)
    S_idle: 
    case (Start)
      0: next_state=S_idle;
      1:if(word2==0) next_state=S_Err;
        else if(word1) begin
          next_state=S_Adivr;
          Load_words=1;
        end 
        else if(sign_bit==1) next_state=S_ShSub;
        else next_state=S_idle;
      default: next_state=S_Err;
    endcase 
    S_Adivr:if(divisor == 1)
     begin
       next_state=S_idle;
     end
     else
     case ({Max,sign_bit})
      2'b00: 
      begin
        next_state=S_ShSub;
        Subtract_and_Shift=1;
      end
      2'b01: 
      begin
        next_state=S_ShSub;
        Shift_dividend=1;
      end
      2'b10: 
      if(num_shift_divisor==0)
      begin
        next_state=S_idle;
        Subtract=1;
      end
      else begin
        next_state=S_ShSub;
        Subtract=1;
      end
      2'b11: 
      if(num_shift_divisor==0)
      begin
        next_state=S_idle;
        Subtract=1;
      end
      else if(num_shift_divisor !=0)
      begin
        next_state=S_Rec;
        Flush_divr=1;
      end
     endcase
    S_Rec: 
    if(Rec_Ctr==L_divr-num_shift_divisor)
    begin
      next_state = S_Rec;
      Flush_divr=1;
    end
    default: next_state=S_Err;
  endcase
end
always @(posedge clock or posedge reset) begin
  if(reset)begin
    divisor<=0;
    dividend <= 0;
    num_shift_dividend <= 0;
    num_shift_divisor <= 0;
    Rec_Ctr<=0;
  end
  else if(Load_words == 1)begin
    dividend[L_divn+1:0] <= {1'b0,word1[L_divn-1:0],1'b0};
    divisor <= word2;
    num_shift_dividend <= 0;
    num_shift_divisor<=0;
    Rec_Ctr <= 0;
  end
  else if(Shift_divisor)begin
    divisor <= divisor << 1;
    num_shift_divisor<=num_shift_divisor+1;
  end
  else if(Shift_dividend)begin
    dividend <= dividend << 1;
    num_shift_dividend<=num_shift_dividend+1;
  end
  else if(Subtract_and_Shift)begin
    dividend[L_divn+1:0] <= {comparison[L_divr-1:0],dividend[L_divn-L_divr:1],2'b10};
    num_shift_dividend<=num_shift_dividend+1;
  end
  else if(Subtract)begin
    dividend[L_divn+1:1] <= {comparison[L_divr-1:0],dividend[L_divn-L_divr:1]};
    dividend[0] <= 1;
  end
  else if(Flush_divr)begin
    Rec_Ctr <= 0;
    divisor <= 1;
  end
  else if(Xfer_Rem)begin
    divisor[Rec_Ctr] <= dividend[L_divn-L_divr+num_shift_divisor+1+Rec_Ctr];
    dividend[L_divn-L_divr+num_shift_divisor+1+Rec_Ctr]<=0; 
    Rec_Ctr <= Rec_Ctr+1;
  end
end
endmodule
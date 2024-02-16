module Boundary_Scan_Register(data_out,data_in,scan_out,scan_in,shiftDR,mode,clockDR,updateDR);
parameter                             size=14;
output       [size-1:0]               data_out;
output                                scan_out;
input        [size-1:0]               data_in;
input                                 scan_in;
input                                 shiftDR,mode,clockDR,updateDR;
reg          [size-1:0]               BSC_Scan_Register,BSC_Output_Register;
always @(posedge clockDR) begin
    BSC_Scan_Register <= shiftDR?{scan_in,BSC_Scan_Register[size-1:1]}:data_in;
end
always @(posedge updateDR) BSC_Output_Register <= BSC_Scan_Register;
assign scan_out=BSC_Scan_Register[0];
assign data_out=mode?BSC_Output_Register:data_in;
endmodule 

module Instruction_Register(data_out,data_in,scan_out,scan_in,shiftIR,clockIR,updateIR,reset_bar);
parameter                               IR_size = 3;
output [IR_size-1:0]                    data_out;
output                                  scan_out;
input  [IR_size-1:0]                    data_in;
input                                   scan_in;
input                                   shiftIR,clockIR,updateIR,reset_bar;
reg    [IR_size-1:0]                    IR_Scan_Register,IR_Output_Register;
assign                                  data_out=IR_Output_Register;
assign                                  scan_out=IR_Scan_Register;
always @(posedge clockIR) begin
    IR_Scan_Register <= shiftIR?{scan_in,IR_Scan_Register[IR_size-1:1]}:data_in;
end
always @(posedge updateIR or negedge reset_bar) begin
    if(reset_bar == 0) IR_Output_Register <= ~(0);
    else IR_Output_Register <= IR_Scan_Register;
end
endmodule

module TAP_Controller(reset_bar,selectIR,shiftIR,clockIR,updateIR,shiftDR,clockDR,updateDR,enableTDO,TMS,TCK);
output reset_bar,selectIR,shiftIR,clockIR,updateIR;
output shiftDR,clockDR,updateDR,enableTDO;
input TMS,TCK;
reg    reset_bar,selectIR,shiftIR,shiftDR,enableTDO;
parameter    S_Reset = 0,
             S_Run_Idle = 1,
             S_Select_DR = 2,
             S_Capture_DR = 3,
             S_Shift_DR = 4,
             S_Exit1_DR = 5,
             S_Pause_DR = 6,
             S_Exit2_DR = 7,
             S_Update_DR = 8,
             S_Select_IR = 9,
             S_Capture_IR = 10,
             S_Shift_IR = 11,
             S_Exit1_IR = 12,
             S_Pause_IR =13,
             S_Exit2_IR = 14,
             S_Update_IR =15;
reg [3:0]    state,next_state;
pullup(TMS);
pullup(TDI);      
always @(negedge TCK) reset_bar <= (state == S_Reset)?0:1;  
always @(negedge TCK) begin
  shiftDR <= (state == S_Shift_DR)?1:0;
  shiftIR <= (state == S_Shift_IR)?1:0;
  enableTDO <= ((state == S_Shift_DR) || (state == S_Shift_IR))?1:0;
end
assign clockDR =!(((state==S_Capture_DR)||(state==S_Shift_DR))&&(TCK==0));
assign clockIR =!(((state==S_Capture_IR)||(state==S_Shift_IR))&&(TCK==0));

assign updateDR = (state == S_Update_DR) && (TCK == 0);
assign updateIR = (state == S_Update_IR) && (TCK == 0);
always @(posedge TCK) state <= next_state;
always @(state or TMS) begin
    selectIR=0;
    next_state=state;
    case(state)
    S_Reset: begin
      selectIR=1;
      if(TMS==0)next_state=S_Run_Idle;
    end
    S_Run_Idle:begin
      selectIR=1;
      if(TMS) next_state=S_Select_DR;
    end
    S_Select_DR:next_state=TMS?S_Select_IR:S_Capture_DR;
    S_Capture_DR:begin
      next_state=TMS?S_Exit1_DR:S_Shift_DR;
    end
    S_Shift_DR:if(TMS) next_state=S_Exit1_DR;
    S_Exit1_DR:next_state=TMS?S_Update_DR:S_Pause_DR;
    S_Pause_DR:if(TMS) next_state=S_Exit2_DR;
    S_Exit2_DR:next_state=TMS?S_Update_DR:S_Shift_DR;
    S_Update_DR:begin
      next_state=TMS?S_Select_DR:S_Run_Idle;
    end
    S_Select_IR:begin
      selectIR=1;
      next_state=TMS?S_Reset:S_Capture_IR;
    end
    S_Capture_IR:begin
      selectIR=1;
      next_state=TMS?S_Exit1_IR:S_Shift_IR;
    end
    S_Shift_IR:begin
      selectIR=1;
      if(TMS) next_state=S_Exit1_IR;
    end
    S_Exit1_IR:begin
      selectIR=1;
      next_state= TMS?S_Update_IR:S_Pause_IR;
    end
    S_Pause_IR:begin
      selectIR=1;
      if(TMS) next_state=S_Exit2_IR;
    end
    S_Exit2_IR:
    begin
      selectIR=1;
      next_state=TMS?S_Update_IR:S_Shift_IR;
    end
    S_Update_IR:begin
      selectIR=1;
      next_state=TMS?S_Select_IR:S_Run_Idle;
    end
default   next_state=S_Reset;
endcase
end
endmodule

module ASIC_with_TAP(sum,c_out,a,b,c_in,TDO,TDI,TMS,TCK);
parameter                      BSR_size = 14;
parameter                      IR_size = 3;
parameter                      size = 4;
output       [size-1:0]        sum;
output                         c_out;
input        [size-1:0]        a,b;
input                          c_in;
output                         TDO;
input                          TDI,TMS,TCK;
wire         [BSR_size-1:0]    BSC_Interface;
wire                           reset_bar,
                               selectIR,enableTDO,
                               shiftIR,clockIR,updateIR,
                               shiftDR,clockDR,updateDR;
wire                           test_mode,select_BR;                               
wire                           TDR_out;
wire         [IR_size-1:0]     Dummy_data=3'b001;
wire         [IR_size-1:0]     instruction;
wire                           IR_Scan_out;
wire                           BSR_scan_out;
wire                           BR_scan_out;
assign                         TDO=enableTDO?selectIR?IR_Scan_out:TDR_out:1'bz;
assign                         TDR_out=select_BR?BR_scan_out:BSR_scan_out;
ASIC M0(.sum(BSC_Interface[13:10]),.c_out(BSC_Interface[9]),.a(BSC_Interface[8:5]),.b(BSC_Interface[4:1]),.c_in(BSC_Interface[0]));
Bypass_Register M1(.scan_out(BR_scan_out),.scan_in(TDI),.shiftDR(shift_BR),.clockDR(clock_BR));
Boundary_Scan_Register M2(.data_out({sum,c_out,BSC_Interface[8:5],BSC_Interface[4:1],BSC_Interface[0]}),.data_in({BSC_Interface[13:0],BSC_Interface[9],a,b,c_in}),.scan_out(BSR_scan_out),.scan_in(TDI),.shiftDR(shiftDR),.mode(test_mode),.clockDR(clock_BSC_Reg),.updateDR(update_BSC_Reg));
Instruction_Register M3(.data_out(instruction),.data_in(Dummy_data),.scan_out(IR_Scan_out),.scan_in(TDI),.shiftIR(shiftIR),.clockIR(clockIR),.updateIR(updateIR),.reset_bar(reset_bar));
Instruction_Decoder M4(.mode(test_mode),.select_BR(select_BR),.shift_BR(shift_BR),.clock_BR(clock_BR),.shift_BSC_Reg(shift_BSC_Reg),.clock_BSC_Reg(clock_BSC_Reg),.update_BSC_Reg(update_BSC_Reg),.instruction(instruction),.shiftDR(shiftDR),.clockDR(clockDR),.updateDR(updateDR));
TAP_Controller M5(.reset_bar(reset_bar),.selectIR(selectIR),.shiftIR(shiftIR),.clockIR(clockIR),.updateIR(updateIR),.shiftDR(shiftDR),.clockDR(clockDR),.updateDR(updateDR),.enableTDO(enableTDO),.TMS(TMS),.TCK(TCK));
endmodule

module ASIC(sum,c_out,a,b,c_in);
parameter               size = 4;
output       [size-1:0] sum;
output                  c_out;
input        [size-1:0] a,b;
input                   c_in;
assign   {c_out,sum}= a+b+c_in;
endmodule

module Bypass_Register(scan_out,scan_in,shiftDR,clockDR);
output                      scan_out;
input                       scan_in,shiftDR,clockDR;
reg                         scan_out;
always @(posedge clockDR) begin
  scan_out <= scan_in & shiftDR;
end
endmodule

module Instruction_Decoder(mode,select_BR,shift_BR,clock_BR,shift_BSC_Reg,clock_BSC_Reg,update_BSC_Reg,instruction,shiftDR,clockDR,updateDR);
parameter                                 IR_size = 3;
output                                    mode,select_BR,shift_BR,clock_BR;
output                                    shift_BSC_Reg,clock_BSC_Reg,update_BSC_Reg;
input                                     shiftDR,clockDR,updateDR;
input              [IR_size-1:0]          instruction;
parameter                                 BYPASS = 3'b111;
parameter                                 EXTEST = 3'b000;
parameter                                 SAMPIE_PRELOAD = 3'b010;
parameter                                 INTEST = 3'b011;
parameter                                 RUNBIST = 3'b100;
parameter                                 IDCODE = 3'b101;
reg                                       mode,select_BR,clock_BR,clock_BSC_Reg,update_BSC_Reg;
assign                                    shift_BR=shiftDR;
assign                                    shift_BSC_Reg=shiftDR;
always @(instruction or clockDR or updateDR) begin
  mode=0;
  select_BR=0;
  clock_BR=1;
  clock_BSC_Reg=1;
  update_BSC_Reg=0;
  case(instruction)
  EXTEST: begin
    mode=1;
    clock_BSC_Reg=clockDR;
    update_BSC_Reg=updateDR;
  end
  INTEST: begin
    mode=1;
    clock_BSC_Reg=clockDR;
    update_BSC_Reg=updateDR;
  end
  SAMPIE_PRELOAD:begin
    clock_BSC_Reg=clockDR;
    update_BSC_Reg=updateDR;
  end
  RUNBIST: begin
    
  end
  IDCODE:begin
    select_BR=1;
    clock_BR=clockDR;
  end
  BYPASS:begin
    select_BR=1;
    clock_BR=clockDR;
  end
  default:begin
    select_BR=1;
  end
  endcase
end
endmodule

module t_ASIC_with_TAP();
parameter                        size = 4;
parameter                        BSC_Reg_size = 14;
parameter                        IR_Reg_size = 3;
parameter                        N_ASIC_Patterns = 8;
parameter                        N_TAP_Instructions = 8;
parameter                        Pause_Time = 40;
parameter                        End_of_Test = 1500;
parameter                        time_1 = 350,time_2=550;
wire           [size-1:0]        sum;
wire           [size-1:0]        sum_fr_ASIC=M0.BSC_Interface[13:10];
wire                             c_out;
wire                             c_out_fr_ASIC=M0.BSC_Interface[9];
reg            [size-1:0]        a,b;
reg                              c_in;
wire           [size-1:0]        a_to_ASIC=M0.BSC_Interface[8:5];
wire           [size-1:0]        b_to_ASIC=M0.BSC_Interface[4:1];
wire                             c_in_to_ASIC=M0.BSC_Interface[0];
reg                              TMS,TCK;
wire                             TDI;
wire                             TDO;
reg                              load_TDI_Generator;
reg                              Error,strobe;
integer                          pattern_ptr;
reg          [BSC_Reg_size-1:0]  Array_of_ASIC_Test_Patterns[0:N_ASIC_Patterns-1];
reg          [IR_Reg_size-1:0]   Array_of_TAP_Instructions[0:N_TAP_Instructions];
reg          [BSC_Reg_size-1:0]  Pattern_Register;
reg                              enable_bypass_pattern;
ASIC_with_TAP M0(sum,c_out,a,b,c_in,TDO,TDI,TMS,TCK);
TDI_Generator M1(.to_TDI(TDI),.scan_pattern(Pattern_Register),.load(load_TDI_Generator),.enable_bypass_pattern(enable_bypass_pattern),.TCK(TCK));
TDO_Monitor M3(.to_TDI(TDI),.from_TDO(TDO),.strobe(strobe),.TCK(TCK));
initial #End_of_Test $finish;
initial begin
  TCK=0;
  forever #5 TCK=~TCK;
end
initial fork 
  //{a,b,c_in}=9'b_1010_0101_0;
  {a,b,c_in}=9'b0;
join
initial begin:Force_Error
force M0.BSC_Interface[13:10]=4'b0;
end
initial begin
  strobe=0;
  Declare_Array_of_TAP_Instructions;
  Declare_Array_of_ASIC_Test_Patterns;
  Wait_to_enter_S_Reset;
  pattern_ptr=0;
  Load_ASIC_Test_Pattern;
  Go_to_S_Run_Idle;
  Go_to_S_Select_DR;
  Go_to_S_Capture_DR;
  Go_to_S_Shift_DR;
  enable_bypass_pattern=1;
  Scan_Ten_Cycles;
  enable_bypass_pattern=0;
  Go_to_S_Exit1_DR;
  Go_to_S_Pause_DR;
  Pause;
  Go_to_S_Exit2_DR;
  /*
  Go_to_S_Shift_DR;
  Load_ASIC_Test_Pattern;
  enable_bypass_pattern=1;
  Scan_Ten_Cycles;
  enable_bypass_pattern=0;
  Go_to_S_Exit1_DR;
  Go_to_S_Pause_DR;
  Pause;
  Go_to_S_Exit2_DR;
  */
  Go_to_S_Update_DR;
  Go_to_S_Run_Idle;
end
initial #time_1 begin
  pattern_ptr=3;
  strobe=0;
  Load_TAP_Instruction;
  Go_to_S_Run_Idle;
  Go_to_S_Select_DR;
  Go_to_S_Select_IR;
  Go_to_S_Capture_IR;
  repeat(IR_Reg_size) Go_to_S_Shift_IR;
  Go_to_S_Exit1_IR;
  Go_to_S_Pause_IR;
  Pause;
  Go_to_S_Exit2_IR;
  Go_to_S_Update_IR;
  Go_to_S_Run_Idle;
end

initial #time_2 begin
  pattern_ptr=0;
  Load_TAP_Instruction;
  Go_to_S_Run_Idle;
  Go_to_S_Select_DR;
  Go_to_S_Capture_DR;
  repeat(BSC_Reg_size) Go_to_S_Shift_DR;
  Go_to_S_Pause_DR;
  Pause;
  Go_to_S_Exit2_DR;
  Go_to_S_Update_DR;
  Go_to_S_Run_Idle;
  pattern_ptr=2;
  Load_ASIC_Test_Pattern;
  Go_to_S_Select_DR;
  Go_to_S_Capture_DR;
  strobe=1;
  repeat(BSC_Reg_size) Go_to_S_Shift_DR;
  Go_to_S_Exit1_DR;
  Go_to_S_Pause_DR;
  Go_to_S_Exit2_DR;
  Go_to_S_Update_DR;
  strobe=0;
  Go_to_S_Run_Idle;
end
task Wait_to_enter_S_Reset;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Reset_TAP;
begin
  TMS=1;
  repeat(5) @(negedge TCK);
end
endtask

task Pause;
begin
  #Pause_Time;
end
endtask

task Go_to_S_Reset;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Run_Idle;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Select_DR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Capture_DR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Shift_DR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Exit1_DR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Pause_DR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Exit2_DR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Update_DR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Select_IR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Capture_IR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Shift_IR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Exit1_IR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Pause_IR;
begin
  @(negedge TCK) TMS=0;
end
endtask

task Go_to_S_Exit2_IR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Go_to_S_Update_IR;
begin
  @(negedge TCK) TMS=1;
end
endtask

task Scan_Ten_Cycles;
begin
  repeat(10) begin @(negedge TCK)
  TMS=0;
  @(posedge TCK) TMS=1;
end
end
endtask

task Load_ASIC_Test_Pattern;
begin
  Pattern_Register=Array_of_ASIC_Test_Patterns[pattern_ptr];
  @(negedge TCK) load_TDI_Generator=1;
  @(negedge TCK) load_TDI_Generator=0;
end
endtask

task Declare_Array_of_ASIC_Test_Patterns;
begin
  Array_of_ASIC_Test_Patterns[0]=14'b0100_1_1010_1010_0;
  Array_of_ASIC_Test_Patterns[1]=14'b0000_0_0000_0000_0;
  Array_of_ASIC_Test_Patterns[2]=14'b1111_1_1111_1111_1;
  Array_of_ASIC_Test_Patterns[3]=14'b0100_1_0101_0101_0;
end
endtask

parameter   BYPASS = 3'b111;
parameter   EXTEST = 3'b001;
parameter   SAMPIE_PRELOAD = 3'b010;
parameter   INTEST = 3'b011;
parameter   RUNBIST = 4'b100;
parameter   IDCODE = 4'b101;

task Load_TAP_Instruction;
begin
  Pattern_Register=Array_of_TAP_Instructions[pattern_ptr];
  @(negedge TCK) load_TDI_Generator=1;
  @(negedge TCK) load_TDI_Generator=0;
end
endtask

task Declare_Array_of_TAP_Instructions;
begin
  Array_of_TAP_Instructions[0]=BYPASS;
  Array_of_TAP_Instructions[1]=EXTEST;
  Array_of_TAP_Instructions[2]=SAMPIE_PRELOAD;
  Array_of_TAP_Instructions[3]=INTEST;
  Array_of_TAP_Instructions[4]=RUNBIST;
  Array_of_TAP_Instructions[5]=IDCODE;
end
endtask
endmodule

module  TDI_Generator(to_TDI,scan_pattern,load,enable_bypass_pattern,TCK);
parameter                             BSC_Reg_size = 14;
output                                to_TDI;
input      [BSC_Reg_size-1:0]         scan_pattern;
input                                 load,enable_bypass_pattern,TCK;
reg        [BSC_Reg_size-1:0]         TDI_Reg;
wire                                  enableTDO=t_ASIC_with_TAP.M0.enableTDO;
assign                                to_TDI=TDI_Reg[0];
always @(posedge TCK) begin
  if(load) TDI_Reg<=scan_pattern;
  else if(enableTDO || enable_bypass_pattern)
  TDI_Reg <= TDI_Reg > 1;
end
endmodule

module TDO_Monitor(to_TDI,from_TDO,strobe,TCK);
parameter                        BSC_Reg_size = 14;
output                           to_TDI;
input                            from_TDO,strobe,TCK;
reg         [BSC_Reg_size-1:0]   TDI_Reg,Pattern_Buffer_1,Pattern_Buffer_2,Capture_Pattern,TDO_Reg;
reg                              Error;
parameter                        test_width = 5;
wire                             enableTDO=t_ASIC_with_TAP.M0.enableTDO;
wire       [test_width-1:0]      Expected_out=Pattern_Buffer_2[BSC_Reg_size-1:BSC_Reg_size-test_width];
wire       [test_width-1:0]      ASIC_out=TDO_Reg[BSC_Reg_size-1:BSC_Reg_size-test_width];
initial begin
  Error=0;
end
always @(negedge enableTDO) begin
  if(strobe==1)
  Error=|(Expected_out^ASIC_out);
end
always @(posedge TCK) begin
  if(enableTDO)begin
    Pattern_Buffer_1<={to_TDI,Pattern_Buffer_1[BSC_Reg_size-1:0]};
    Pattern_Buffer_2<={Pattern_Buffer_1[0],Pattern_Buffer_2[BSC_Reg_size-1:1]};
    TDO_Reg <= {from_TDO,TDO_Reg[BSC_Reg_size-1:1]};
  end
end
endmodule
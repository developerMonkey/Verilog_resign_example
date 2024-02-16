module FIFO_Buffer(Data_out,stack_full,stack_almost_full,stack_half_full,stack_almost_empty,stack_empty,Data_in,write_to_stack,read_from_stack,clk,rst);
parameter stack_width = 32; //堆栈和数据通道的宽度
parameter stack_height = 8; //堆栈的高度
parameter stack_ptr_width = 3;//访问对战的指针宽度
parameter AE_level = 2;//几乎要空
parameter AF_level = 6;//几乎要满
parameter HF_level = 4;//半满
output [stack_width-1:0] Data_out;//来自FIFO的数据通道
output stack_full,stack_almost_full,stack_half_full;//状态标志
output stack_almost_empty,stack_empty;

input [stack_width-1:0] Data_in;//进入FIFO的数据通道
input write_to_stack,read_from_stack;//可控制写入堆栈的标志
input clk,rst;

reg [stack_ptr_width-1:0] read_ptr,write_ptr;//指针间读写间隙的地址
reg [stack_ptr_width:0]   ptr_gap;
reg [stack_width-1:0] Data_out;
reg [stack_width-1:0] stack[stack_height-1:0];//存储器阵列
//堆栈状态信号
assign stack_full=(ptr_gap == stack_height);
assign stack_almost_full = (ptr_gap == AF_level);
assign stack_half_full = (ptr_gap == HF_level);
assign stack_almost_empty = (ptr_gap == AE_level);
assign stack_empty = (ptr_gap == 0);
always @(posedge clk or posedge rst) begin
    if(rst)begin
      Data_out <= 0;
      read_ptr <= 0;
      write_ptr <= 0;
      ptr_gap <= 0;
    end
    else if(write_to_stack && (!stack_full) && (!read_from_stack))
    begin
      Data_out <= stack[read_ptr];
      read_ptr <= read_ptr+1;
      ptr_gap <= ptr_gap-1;
    end
    else if(write_to_stack && read_from_stack && stack_empty)
    begin
      stack[write_ptr] <= Data_in;
      write_ptr <= write_ptr+1;
      ptr_gap <= ptr_gap+1;
    end
    else if(write_to_stack && read_from_stack && stack_full)
    begin
      Data_out <= stack[read_ptr];
      read_ptr <= read_ptr+1;
      ptr_gap <= ptr_gap-1;
    end
    else if(write_to_stack && read_from_stack && (!stack_full)&& (!stack_empty))
    begin
      Data_out <= stack[read_ptr];
      stack[write_ptr] <= Data_in;
      read_ptr <= read_ptr+1;
      write_ptr <= write_ptr+1;
    end
end
endmodule

module t_FIFO_Buffer();
parameter stack_width = 32;
parameter stack_height = 8;
parameter stack_ptr_width = 4;
wire [stack_width-1:0] Data_out;
wire                   write;
wire                   stack_full,stack_almost_full,stack_half_full;
wire                   stack_almost_empty,stack_empty;
reg  [stack_width-1:0] Data_in;
reg                    write_to_stack,read_from_stack;
reg                    clk,rst;
wire [stack_width-1:0] stack0,stack1,stack2,stack3,stack4,stack5,stack6,stack7;
assign stack0=M1.stack[0];
assign stack1=M1.stack[1];
assign stack2=M1.stack[2];
assign stack3=M1.stack[3];
assign stack4=M1.stack[4];
assign stack5=M1.stack[5];
assign stack6=M1.stack[6];
assign stack7=M1.stack[7];
FIFO_Buffer M1(Data_out,stack_full,stack_almost_full,stack_half_full,stack_almost_empty,stack_empty,Data_in,write_to_stack,read_from_stack,clk,rst);
initial #300 $finish;
initial begin
    rst=1;
    #2 rst=0;
end
initial begin
    clk=0;
    forever begin
        #4 clk=~clk;
    end
end
//数据跳变
initial begin
    Data_in=32'hFFFF_AAAA;
    @(posedge write_to_stack);
    repeat(24)@(negedge clk) Data_in=~Data_in;
end
//写入FIFO
initial fork
    begin
      #8 write_to_stack=0;
      
    end
    begin
      #16 write_to_stack=1;
      #140  write_to_stack=0;
    end
    begin
      #224 write_to_stack=1;
     
    end
    
join
//从FIFO中读取
initial fork
    begin
      #8 read_from_stack=0;
      
    end
    begin
      #64 read_from_stack=1;
      #40 read_from_stack=0;
    end
    begin
      #144 read_from_stack=1;
      #8  read_from_stack=0;
    end
    begin
      #176 read_from_stack=1;
      #56  read_from_stack=0;
    end
join
endmodule

module Ser_Par_Conv_32(Data_out,write,Data_in,En,clk,rst);
output [31:0]  Data_out;
output         write;
input          Data_in;
input          En,clk,rst;

parameter      S_idle=0;
parameter      S_1=1;

reg            state,next_state;
reg     [4:0]  cnt;
reg     [31:0]       Data_out;
reg            shift,incr;

always @(posedge clk or posedge rst)
if(rst)begin
    state <= S_idle;
    cnt <= 0;
end
else
state <= next_state;

always @(state or En or write)
begin 
    shift = 0;
    incr  = 0;
    next_state = state;
    case(state)
    S_idle:
    if(En)begin
        next_state = S_1;
        shift = 1;
    end
    S_1:
    if(!write)begin 
        shift = 1;
        incr = 1;
    end
    else if(En)
    begin 
        shift = 1;
        incr = 1;
    end
    else begin 
        next_state=S_idle;
        incr = 1;
    end
    endcase
end
always @(posedge clk or posedge rst) begin
    if(rst) begin cnt <= 0;end
    else if(incr) cnt <= cnt+1;
end
always @(posedge clk or posedge rst) begin
    if(rst) 
    begin 
        Data_out <= 0;
    end 
    else if(shift) 
    begin 
        Data_out <= {Data_in,Data_out[31:1]};
    end
end
assign write = (cnt ==31);
initial begin
    $display("write=%d",write);
    $display("Data_out=%d",Data_out);
    $display("state=%d",state);
end

endmodule

module write_synchronizer(write_synch,write_to_FIFO,clock,reset);
output     write_synch;
input      write_to_FIFO;
input      clock,reset;
reg        meta_synch,write_synch;

always @(negedge clock) 
if(reset == 1)begin
    meta_synch <= 0;
    write_synch <= 0;
end
else begin
  meta_synch <= write_to_FIFO;
  write_synch <= write_synch ? 0:meta_synch;
end
initial begin
    $display("write_synch=%d",write_synch);
end
endmodule

module t_FIFO_Clock_Domain_Synch();
parameter stack_width=32;
parameter stack_height=8;
parameter stack_ptr_width = 3;
defparam M1.stack_width=32;
defparam M1.stack_height=8;
defparam M1.stack_ptr_width=3;
wire [stack_width-1:0]  Data_out,Data_32_bit;
wire                   stack_full,stack_almost_full,stack_half_full;
wire                   stack_almost_empty,stack_empty;
wire                   write_synch;
reg                    Data_in;
reg                    read_from_stack;
reg                    En;
reg                    clk_write,clk_read,rst;
wire   [31:0]          stack0,stack1,stack2,stack3;
wire   [31:0]          stack4,stack5,stack6,stack7;

assign stack0=M1.stack[0];
assign stack1=M1.stack[1];
assign stack2=M1.stack[2];
assign stack3=M1.stack[3];
assign stack4=M1.stack[4];
assign stack5=M1.stack[5];
assign stack6=M1.stack[6];
assign stack7=M1.stack[7];

reg [stack_width-1:0] Data_1,Data_2;
always @(negedge clk_read) begin
    if(rst)begin
      Data_2 <= 0;
      Data_1 <= 0;
    end
    else 
    begin
      Data_1 <= Data_32_bit;
      Data_2 <= Data_1;
    end 
end
Ser_Par_Conv_32 M00(Data_out,write,Data_in,En,clk,rst);
write_synchronizer M0 (write_synch,write_to_FIFO,clock,reset);
FIFO_Buffer M1 (Data_out,stack_full,stack_almost_full,stack_half_full,stack_almost_empty,stack_empty,Data_2,write_synch,read_from_stack,clk,rst);
initial #10000 $finish;
initial fork rst=1;#8 rst=0;join
initial begin
    clk_write=0;
    forever #4 clk_write=~clk_write;
end
initial begin
    clk_read=0;
    forever #3 clk_read=~clk_read;
end

initial fork 
    #1 En=0;
    #48 En=1;
    #2534  En=0;
    #3944 En=1;
join

initial fork
    #6 read_from_stack=0;
    #2700 read_from_stack=1;
    #2706 read_from_stack=0;
    #3980 read_from_stack=1;
    #3986 read_from_stack=0;
    #6000 read_from_stack=1;
    #6006 read_from_stack=0;
    #7776 read_from_stack=1;
    #7782 read_from_stack=0;
    //write_synch;
join
initial begin
    #1 Data_in=0;
    @(posedge En) Data_in=1;
    @(posedge write);
    repeat(6) begin
      repeat(16)@(negedge clk_write) Data_in=0;
      repeat(16)@(negedge clk_write) Data_in=1;
      repeat(16)@(negedge clk_write) Data_in=1;
      repeat(16)@(negedge clk_write) Data_in=0;

    end
end
initial begin
    $dumpfile("t_FIFO_Clock_Domain_Synch.vcd");        //生成的vcd文件名称
    $dumpvars(0, t_FIFO_Clock_Domain_Synch);    //tb模块名称
end
endmodule
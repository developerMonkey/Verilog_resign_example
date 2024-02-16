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

module Ser_Par_Conv_32_tb;
output [31:0]  Data_out;
output         write;


reg          Data_in;
reg          En;
reg          clk;
reg          rst;
integer      i;
Ser_Par_Conv_32 SP1(Data_out,write,Data_in,En,clk,rst);
initial begin

    En=1;
    clk=0;
    rst=1;
    for (i =0 ;i<20 ;i=i+1 ) begin
        #5 Data_in= $urandom_range(0, 1); 
        #5 En= $urandom_range(0, 1); 
        #5 clk= $urandom_range(0, 1); 
        #5 rst= $urandom_range(0, 1);
    end
    //defparam SP1.En=1;
    $finish;
end

always @(Data_in) begin
    //defparam SP1.En=1'b1;
    // 可以添加监视逻辑，例如打印输入数据
    $display("Input Data: %0d", Data_in);
end

initial begin
    $dumpfile("Ser_Par_Conv_32_tb.vcd");        //生成的vcd文件名称
    $dumpvars(0, Ser_Par_Conv_32_tb);    //tb模块名称
end
endmodule
module Add_prop_gen(sum,c_out,a,b,c_in);
output   [3:0]    sum;
output            c_out;
input             a,b;
input             c_in;
reg      [3:0]    carrychain;
integer           i;
wire     [3:0]    g=a & b;//进位产生，连续赋值，按位与
wire     [3:0]    p=a ^ b;//进位产生，连续赋值，按位异或
always @(a or b or c_in or p or g) //事件 "或"
    begin:carry_generation  //习惯用法
    integer i;
    carrychain[0]=g[0] + (p[0] & c_in);//仿真要求
    for (i = 0;i<=3 ;i=i+1 ) begin  //
        carrychain[i]=g[i] | (p[i] & carrychain[i-1]);
    end
    end

wire [4:0] shiftedcarry={carrychain,c_in};//串联
wire [3:0] sum=p ^ shiftedcarry;//求和运算
wire c_out=shiftedcarry[4];//进位输出
endmodule
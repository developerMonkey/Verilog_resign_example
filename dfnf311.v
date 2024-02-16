`timescale 1ns / 1ps
`celldefine 
module dfnf311(Q,Q_b,DATA1,CLK2);
//负沿触发的有Q和QB输出的触发器
input                    DATA1,CLK2;
output                   Q,Q_b;
reg                      notify;
parameter                vlib_flat_module = 1;
U_FD_N_NO inst1(Q_int,DATA1,CLK2,notify);
buf inst2(Q,Q_int);
not inst3(Q_b,Q_int);
specify
    specparam Area_Cost=4268.16;
    (negedge CLK2 => (Q+:DATA1))=(0.525:1.129:2.889,0.749:1.525:3.948);
    specparam RiseScale$CLK2$Q=0.00094:0.00205:0.00540;
    specparam FallScale$CLK2$Q=0.00086:0.00165:0.00397;
    (negedge CLK2 => (Q_b-:DATA1))=(0.590:1.243:3.207,0.425:0.914:2.616);
    specparam RiseScale$CLK2$Q_b=0.00120:0.00248:0.00658;
    specparam FallScale$CLK2$Q_b=0.00140:0.00289:0.00248;
    specparam inputCap$CLK2=40.18,
              inputCap$DATA1=24.11;
    specparam inputLoad$CLK2=0.009:0.021:0.053,
              inputLoad$DATA1=0.005:0.013:0.032;   
    specparam t_SETUP$DATA1=0.76:0.92:1.68,
              t_HOLD$DATA1=0.44:0.74:0.46,
              t_PW_H$CLK2=0.37:0.67:1.99,
              t_PW_L$CLK2=0.37:0.67:1.99;
    $setuphold(negedge CLK2,DATA1,t_SETUP$DATA1,t_HOLD$DATA1,notify);
    $width(posedge CLK2,t_PW_H$CLK2,0,notify);
    $width(negedge CLK2,t_PW_H$CLK2,0,notify);
    `ifdef not_cadence specparam MaxLoad='MAX_LOAD_1X;
    `endif                           
endspecify
endmodule
`endcelldefine

primitive U_FD_N_NO(Q,D,CP,NOTIFIER_REG);
output Q;
input NOTIFIER_REG,D,CP;
reg   Q;
table
  //D  CP       NOTIFIER_REG :  Qt  :Qt+1  
    1  (10)       ?       : ? :1; //带时钟的数据
    0  (10)       ?       : ? :0;
    1  (1x)       ?       : 1 :1;//减少不利因素
    0  (1x)       ?       : 0 :0;
    1  (x0)       ?       : 1 :1;
    0  (x0)       ?       : 0 :0;
    ?  (0x)       ?       : ? :-;//上升沿上无变化
    ?  (?1)       ?       : ? :-;
    *   ?         ?       : ? :-; //数据的无效沿
    ?   ?         *       : ? : x; //所有跳变
endtable  
endprimitive
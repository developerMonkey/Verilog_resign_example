//寄存器综合
module shifter_1(sig_d,new_signal,data_in,clock,reset);
output               sig_d,new_signal;
input                data_in,clock,reset;
reg                  sig_a,sig_b,sig_c,sig_d,new_signal;
always @(posedge reset or posedge clock) begin
    if(reset == 1'b1)
    begin
      sig_a <= 0;
      sig_b <= 0;
      sig_c <= 0;
      sig_d <= 0;
      $display("sig_a=%b,sig_b=%b,sig_c=%b,sig_d=%b",sig_a,sig_b,sig_c,sig_d);
    end
    else 
    begin
      sig_a <= data_in;
      sig_b <= sig_a;
      sig_c <= sig_b;
      sig_d <= sig_c;
      new_signal <= (~sig_a) & sig_b;
      $display("sig_a=%d,sig_b=%d,sig_c=%d,sig_d=%d,new_signal=%d",sig_a,sig_b,sig_c,sig_d,new_signal);
    end
    
end
initial begin
    
end
endmodule

module shifter_1_tb;
wire               sig_d,new_signal;
reg                data_in,clock,reset;
shifter_1 ss1(sig_d,new_signal,data_in,clock,reset);
initial begin
    data_in = 1'b1;
    clock =2'b10;
    reset = 1'b1;
end
initial begin
    #300 $finish;
end
endmodule
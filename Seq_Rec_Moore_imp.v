module Seq_Rec_Moore_imp(D_out,D_in,clock,reset);
output            D_out;
input             D_in;
input             clock,reset;
reg               last_bit,this_bit,flag;
wire              D_out;

always begin:wrapper_for_synthesis @(posedge clock) begin :machine
  if(reset == 1)begin
    last_bit <= 0;
    disable  machine;
  end
  else begin
    this_bit <= D_in;
    forever @ (posedge clock) begin
        if(reset == 1) begin
            flag <= 0;
            disable machine;
        end
        else begin
          last_bit <= this_bit;
          this_bit <= D_in;
          flag <= 1;
          
        end
    end           
  end
end 

end
assign D_out = (flag && (this_bit == last_bit));
initial begin
    $display("last_bit = %b,flag =%b",last_bit,flag);
end

endmodule

module Seq_Rec_Moore_imp_tb;
wire            D_out;
reg             D_in;
reg             clock,reset;

Seq_Rec_Moore_imp SR1(D_out,D_in,clock,reset);
initial begin
    D_in = 1'b1;
    clock = 1'b0;
    reset = 1'b0;
    $display("D_out = %b",D_out);
end
initial begin
    $dumpfile("Seq_Rec_Moore_imp_tb.vcd");        //生成的vcd文件名称
    $dumpvars(0, Seq_Rec_Moore_imp_tb); 
    #300 $finish;
end
endmodule
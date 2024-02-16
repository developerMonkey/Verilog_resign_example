module Add_Accum_1(accum,overflow,data,enable,clk,reset);
output   [3:0]  accum;
output          overflow;
input    [3:0]  data;
input           enable,clk,reset;
reg             accum,overflow;
always @(posedge clk or negedge reset) begin
    if(reset==0)
    begin
      accum <= 0;
      overflow <= 0;
    end
    else if(enable)
    begin
      {overflow,accum} <= accum+data;
    end
    
end
endmodule

module Add_Accum_2(accum,overflow,data,enable,clk,reset_b);
output   [3:0]  accum;
output          overflow;
input    [3:0]  data;
input           enable,clk,reset_b;
wire     [3:0]  sum;
reg             accum;
assign          {overflow,sum} = accum+data;
always @(posedge clk or negedge reset_b) begin
    if(reset_b==0)
    begin
      accum <= 0;
    end
    else if(enable)
    accum <= sum;
end
endmodule
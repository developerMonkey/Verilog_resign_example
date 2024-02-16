module Latch_Race_1(D_out,D_in);
output   D_out;
input    D_in;
reg      D_out;
reg      En;
always @(D_in) begin
    En=D_in;
end
always @(D_in or En) begin
    if(En == 0)
    D_out=D_in;
end
endmodule

module Latch_Race_2(D_out,D_in);
output   D_out;
input    D_in;
reg      D_out;
reg      En;
always @(D_in or En) begin
    if(En == 0)
    D_out=D_in;
end

always @(D_in) begin
    En=D_in;
end
endmodule

module Latch_Race_3(D_out,D_in);
output   D_out;
input    D_in;
reg      D_out;
wire      En;
buf #1(En,D_in);
always @(D_in or En) begin
    if(En == 0)
    D_out=D_in;
end
endmodule

module Latch_Race_4(D_out,D_in);
output   D_out;
input    D_in;
reg      D_out;
wire      En;
buf #1(En,D_in);
always @(D_in or En) begin
    #3 if(En == 0)
    D_out=D_in;
end
endmodule
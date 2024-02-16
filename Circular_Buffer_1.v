module Circular_Buffer_1(cell_3,cell_2,cell_1,cell_0,Data_in,clock,reset);
parameter buff_size = 4;
parameter word_size = 8;
output [word_size-1:0] cell_3,cell_2,cell_1,cell_0;
input [word_size-1:0] Data_in;
input clock,reset;
reg [buff_size-1:0] Buff_Array[word_size-1:0];
wire cell_3=Buff_Array[3],cell_2=Buff_Array[2];
wire cell_1=Buff_Array[1],cell_0=Buff_Array[0];
integer k;

always @(posedge clock) begin
    if(reset == 1) 
      for(k=0;k<=buff_size-1;k=k+1)
      Buff_Array[k]<=0;
    else for(k=0;k<=buff_size-1;k=k+1)begin
      Buff_Array[k] <= Buff_Array[k-1];
      Buff_Array[k] <= Data_in;
    end
end
endmodule

module Circular_Buffer_2(cell_3,cell_2,cell_1,cell_0,Data_in,clock,reset);
parameter buff_size = 4;
parameter word_size = 8;
output [word_size-1:0] cell_3,cell_2,cell_1,cell_0;
input [word_size-1:0] Data_in;
input clock,reset;
reg [buff_size-1:0] Buff_Array[word_size-1:0];
wire cell_3=Buff_Array[3],cell_2=Buff_Array[2];
wire cell_1=Buff_Array[1],cell_0=Buff_Array[0];
integer k;
parameter write_ptr_width = 2;
parameter max_write_ptr = 3;
reg [write_ptr_width-1:0] write_ptr;
always @(posedge clock) begin
    if(reset == 1)
    begin
      write_ptr <= 0;
      for (k=0;k<=buff_size-1;k=k+1 ) begin
        Buff_Array[k] <= 0;
      end
    end
    else begin
      Buff_Array[write_ptr] <= Data_in;
      if(write_ptr < max_write_ptr)
      write_ptr <= write_ptr+1;
      else
      write_ptr <= 0;
    end
end
endmodule

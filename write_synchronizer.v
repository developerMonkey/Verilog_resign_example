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

module write_synchronizer_tb;
wire     write_synch;
reg        write_to_FIFO;
reg        clock,reset;
reg        meta_synch;
integer i;
write_synchronizer w1(write_synch,write_to_FIFO,clock,reset);
initial begin
    #5 write_to_FIFO=1;
    #10 clock=1;
    #5 reset=1;
    for ( i=0 ;i<20 ;i=i+1 ) begin
        #5 write_to_FIFO=$urandom_range(0, 1);
        #10 clock=$urandom_range(0, 1);
        #5 reset=$urandom_range(0, 1);
    end
end

always @(posedge clock) begin
    if (clock==1) begin
        $display("write_synch=%d",write_synch);
    end
end
initial begin
    $dumpfile("write_synchronizer_tb.vcd");        //生成的vcd文件名称
    $dumpvars(0,write_synchronizer_tb); 
    #500 $finish;
end

endmodule
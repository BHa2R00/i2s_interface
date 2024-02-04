`include "../rtl/i2s_pcm16sle.v"

`timescale 1ns/100ps

module i2s_pcm16sle_tb;
	
reg [511:0] tb_msg;
`define write_msg(b) begin $write(b); tb_msg = b; end

	reg enable;
	reg rstn, clk;
	
	reg bclk, lrclk;

	wire [4:0] align = 1;

	wire full_1;
	reg push_1, pop_1;
	wire signed [15:0] rx_pcm_1;
	wire rx_1;
	wire tx_1;
	wire signed [15:0] tx_pcm_1;
	reg sel_rx_1;

i2s_mono u_1(
	. full(full_1), 
	. push(push_1), .pop(pop_1), 
	. bclk(bclk), .lrclk(lrclk), 
	. rx_pcm(rx_pcm_1), 
	. rx(rx_1), 
	. tx(tx_1), 
	. tx_pcm(tx_pcm_1), 
	. align(align), 
	. sel_rx(sel_rx_1), 
	. enable(enable), 
	. rstn(rstn), .clk(clk) 
);

	wire full_2;
	reg push_2, pop_2;
	wire signed [15:0] rx_pcm_2;
	wire rx_2;
	wire tx_2;
	wire signed [15:0] tx_pcm_2;
	wire sel_rx_2 = ~sel_rx_1;

i2s_mono u_2(
	. full(full_2), 
	. push(push_2), .pop(pop_2), 
	. bclk(bclk), .lrclk(lrclk), 
	. rx_pcm(rx_pcm_2), 
	. rx(rx_2), 
	. tx(tx_2), 
	. tx_pcm(tx_pcm_2), 
	. align(align), 
	. sel_rx(sel_rx_2), 
	. enable(enable), 
	. rstn(rstn), .clk(clk) 
);

assign rx_1 = tx_2;
assign rx_2 = tx_1;

initial clk = 0;
always #4.46 clk = ~clk;

initial lrclk = 0;
always@(negedge bclk) begin
	repeat(32) @(negedge bclk);
	lrclk = ~lrclk;
end

initial bclk = 0;
always #160.77171 bclk = ~bclk;

`define rand_wait(p) begin repeat($urandom_range(5, 5+p)) @(posedge clk); end
`define rand_rise(r) begin r = 1'b0; `rand_wait(100) r = 1'b1; end
`define rand_fall(r) begin r = 1'b1; `rand_wait(100) r = 1'b0; end

task init;
	rstn = 0;
	enable = 0;
	push_1 = $urandom_range(0,1);
	pop_1 = $urandom_range(0,1);
	push_2 = $urandom_range(0,1);
	pop_2 = $urandom_range(0,1);
	sel_rx_1 = $urandom_range(0,1);
endtask

reg signed [15:0] tx_data;
always@(posedge lrclk or negedge lrclk) begin
	tx_data = (1<<8)*$sin(36*$time*2*3.1415926);
end
assign tx_pcm_1 = tx_data;
assign tx_pcm_2 = tx_data;

always@(posedge clk) begin
	if(sel_rx_1) begin
		if(full_1) pop_1 <= ~pop_1;
		if(full_2) push_2 <= ~push_2;
	end
	else begin
		if(full_1) push_1 <= ~push_1;
		if(full_2) pop_2 <= ~pop_2;
	end
end

task test1;
	`write_msg("test1 start\n")
	`rand_wait(5) 
	sel_rx_1 = $urandom_range(0,1);
	`rand_rise(enable)
	repeat($urandom_range(5, 500)) @(negedge lrclk);
	`rand_fall(enable)
	`rand_wait(5) 
	`write_msg("test1 end\n")
endtask

initial begin
	init;
	`rand_rise(rstn)
	repeat(1) test1;
	`rand_fall(rstn)
	$finish;
end

initial begin
  $fsdbDumpfile("../work/i2s_pcm16sle_tb.fsdb");
  $fsdbDumpvars(0, i2s_pcm16sle_tb);
end

endmodule

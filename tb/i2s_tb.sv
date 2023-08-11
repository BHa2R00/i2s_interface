`timescale 1ns / 100ps

module i2s_tb;

reg rstn, clk;
reg lrclk;

reg u1_i2s_master_enable;
reg u1_i2s_sdin;
wire [31:0] u1_i2s_dout_l, u1_i2s_dout_r;
wire u1_i2s_sdout;
reg [31:0] u1_i2s_din_l, u1_i2s_din_r;
reg u1_i2s_bclk_i, u1_i2s_lrclk_i;
wire u1_i2s_bclk_o, u1_i2s_lrclk_o;
reg [19:0] u1_i2s_bdiv;
reg [7:0] u1_i2s_lrdiv;
i2s u1_i2s(
	.master_enable(u1_i2s_master_enable), 
	.sdin(u1_i2s_sdin), 
	.dout_l(u1_i2s_dout_l), .dout_r(u1_i2s_dout_r), 
	.sdout(u1_i2s_sdout), 
	.din_l(u1_i2s_din_l), .din_r(u1_i2s_din_r), 
	.bclk_i(u1_i2s_bclk_i), .lrclk_i(u1_i2s_lrclk_i), 
	.bclk_o(u1_i2s_bclk_o), .lrclk_o(u1_i2s_lrclk_o), 
	.bdiv(u1_i2s_bdiv), .lrdiv(u1_i2s_lrdiv), 
	.rstn(rstn), .clk(clk)
);

reg u0_i2s_master_enable;
reg u0_i2s_sdin;
wire [31:0] u0_i2s_dout_l, u0_i2s_dout_r;
wire u0_i2s_sdout;
reg [31:0] u0_i2s_din_l, u0_i2s_din_r;
reg u0_i2s_bclk_i, u0_i2s_lrclk_i;
wire u0_i2s_bclk_o, u0_i2s_lrclk_o;
reg [19:0] u0_i2s_bdiv;
reg [7:0] u0_i2s_lrdiv;
i2s u0_i2s(
	.master_enable(u0_i2s_master_enable), 
	.sdin(u0_i2s_sdin), 
	.dout_l(u0_i2s_dout_l), .dout_r(u0_i2s_dout_r), 
	.sdout(u0_i2s_sdout), 
	.din_l(u0_i2s_din_l), .din_r(u0_i2s_din_r), 
	.bclk_i(u0_i2s_bclk_i), .lrclk_i(u0_i2s_lrclk_i), 
	.bclk_o(u0_i2s_bclk_o), .lrclk_o(u0_i2s_lrclk_o), 
	.bdiv(u0_i2s_bdiv), .lrdiv(u0_i2s_lrdiv), 
	.rstn(rstn), .clk(clk)
);

always #33.3 clk = ~clk;
always @(*) u0_i2s_bclk_i = u1_i2s_bclk_o;
always @(*) u0_i2s_lrclk_i = u1_i2s_lrclk_o;
always @(*) u1_i2s_sdin = u0_i2s_sdout;
always @(*) u0_i2s_sdin = u1_i2s_sdout;
always @(*) lrclk = u1_i2s_lrclk_o;
always @(negedge rstn or posedge lrclk) begin
	if(!rstn) begin
		u1_i2s_din_l <= 32'b10110111011110111110111111011111;
		u0_i2s_din_l <= 32'b01001000100001000001000000100000;
	end
	else begin
		u1_i2s_din_l <= 
			(u1_i2s_din_l == 32'b10110111011110111110111111011111) ? 32'b01001000100001000001000000100000 : 
			32'b10110111011110111110111111011111;
		u0_i2s_din_l <= 
			(u0_i2s_din_l == 32'b01001000100001000001000000100000) ? 32'b10110111011110111110111111011111 : 
			32'b01001000100001000001000000100000;
	end
end

always @(negedge rstn or negedge lrclk) begin
	if(!rstn) begin
		u1_i2s_din_r <= 32'b11111011111101111101111011101101;
		u0_i2s_din_r <= 32'b00000100000010000010000100010010;
	end
	else begin
		u1_i2s_din_r <= 
			(u1_i2s_din_r == 32'b11111011111101111101111011101101) ? 32'b00000100000010000010000100010010 : 
			32'b11111011111101111101111011101101;
		u0_i2s_din_r <= 
			(u0_i2s_din_r == 32'b00000100000010000010000100010010) ? 32'b11111011111101111101111011101101 : 
			32'b00000100000010000010000100010010;
	end
end

initial begin
	rstn = 0;
	clk = 0;
	//u1_i2s_master init
	u1_i2s_master_enable = 1'b1;
	u1_i2s_bclk_i = 0;
	u1_i2s_lrclk_i = 0;
	u1_i2s_bdiv = 20'd7;
	u1_i2s_lrdiv = 8'd95;
	//u1_i2s_master init end
	//u0_i2s_master init
	u0_i2s_master_enable = 1'b0;
	u0_i2s_bdiv = 20'd7;
	u0_i2s_lrdiv = 8'd95;
	//u0_i2s_master init end
	#3000
	rstn = 1;
	#3000000
	rstn = 0;
	#3000
	$finish(2);
end

initial begin
	$dumpfile("../work/i2s_tb.vcd");
	$dumpvars(0,i2s_tb);
end

endmodule

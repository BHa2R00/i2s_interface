`timescale 1ns / 100ps

module iis_tb;

integer tb_ph;
initial tb_ph = 0;

reg clk_112m;
initial clk_112m = 0;
always #4.45 clk_112m = ~clk_112m;
reg rstn;

wire bclk, lrclk;

wire u0_iis_tx_data_l_full, u0_iis_tx_data_r_full;
wire u0_iis_rx_data_l_empty, u0_iis_rx_data_r_empty;
wire u0_iis_tx;
wire [31:0] u0_iis_rx_data_l, u0_iis_rx_data_r;
reg [31:0] u0_iis_tx_data_l, u0_iis_tx_data_r;
reg u0_iis_tx_data_fill, u0_iis_tx_data_clear;
reg u0_iis_rx;
reg u0_iis_rx_data_drain, u0_iis_rx_data_clear;
iis u0_iis(
	.rx(u0_iis_rx), 
	.rx_data_r_full(), .rx_data_r_empty(u0_iis_rx_data_r_empty), 
	.rx_data_l_full(), .rx_data_l_empty(u0_iis_rx_data_l_empty), 
	.rx_data_l_count(), .rx_data_r_count(), 
	.rx_data_depth(3'd5), 
	.rx_data_drain(u0_iis_rx_data_drain), .rx_data_clear(u0_iis_rx_data_clear), 
	.rx_data_l(u0_iis_rx_data_l), .rx_data_r(u0_iis_rx_data_r), 
	.enable_rx(1'b1), .rx_bpol(1'b1), .rx_lrpol(1'b1), 	// rx_bpol=1 -- read bit at rising edge, lrpol=1 -- left channel start at rising edge
	.tx(u0_iis_tx), 
	.tx_data_r_full(u0_iis_tx_data_r_full), .tx_data_r_empty(), 
	.tx_data_l_full(u0_iis_tx_data_l_full), .tx_data_l_empty(), 
	.tx_data_l_count(), .tx_data_r_count(), 
	.tx_data_depth(3'd5), 
	.tx_data_fill(u0_iis_tx_data_fill), .tx_data_clear(u0_iis_tx_data_clear), 
	.tx_data_l(u0_iis_tx_data_l), .tx_data_r(u0_iis_tx_data_r), 
	.enable_tx(1'b1), .tx_bpol(1'b0), .tx_lrpol(1'b1), 	// tx_bpol=1 -- send bit at rising edge, lrpol=1 -- left channel start at rising edge
	.msb_delay_bits(4'd1), 			// msb delay bits, 0 -- left-justified, 1 -- standard 
	.bclk_o(bclk), .lrclk_o(lrclk), 
	.bclk_i(), .lrclk_i(), 
	.bdiv(32'd13), .lrbdiv(32'd32), 
	.enable_master(1'b1), 
	.enable(1'b1), 
	.rstn(rstn), .clk(clk_112m), .test_se(1'b0) 
);

wire u1_iis_tx_data_l_full, u1_iis_tx_data_r_full;
wire u1_iis_rx_data_l_empty, u1_iis_rx_data_r_empty;
wire u1_iis_tx;
wire [31:0] u1_iis_rx_data_l, u1_iis_rx_data_r;
reg [31:0] u1_iis_tx_data_l, u1_iis_tx_data_r;
reg u1_iis_tx_data_fill, u1_iis_tx_data_clear;
reg u1_iis_rx;
reg u1_iis_rx_data_drain, u1_iis_rx_data_clear;
iis u1_iis(
	.rx(u1_iis_rx), 
	.rx_data_r_full(), .rx_data_r_empty(u1_iis_rx_data_r_empty), 
	.rx_data_l_full(), .rx_data_l_empty(u1_iis_rx_data_l_empty), 
	.rx_data_l_count(), .rx_data_r_count(), 
	.rx_data_depth(3'd5), 
	.rx_data_drain(u1_iis_rx_data_drain), .rx_data_clear(u1_iis_rx_data_clear), 
	.rx_data_l(u1_iis_rx_data_l), .rx_data_r(u1_iis_rx_data_r), 
	.enable_rx(1'b1), .rx_bpol(1'b1), .rx_lrpol(1'b1), 	// rx_bpol=1 -- read bit at rising edge, lrpol=1 -- left channel start at rising edge
	.tx(u1_iis_tx), 
	.tx_data_r_full(u1_iis_tx_data_r_full), .tx_data_r_empty(), 
	.tx_data_l_full(u1_iis_tx_data_l_full), .tx_data_l_empty(), 
	.tx_data_l_count(), .tx_data_r_count(), 
	.tx_data_depth(3'd5), 
	.tx_data_fill(u1_iis_tx_data_fill), .tx_data_clear(u1_iis_tx_data_clear), 
	.tx_data_l(u1_iis_tx_data_l), .tx_data_r(u1_iis_tx_data_r), 
	.enable_tx(1'b1), .tx_bpol(1'b0), .tx_lrpol(1'b1), 	// tx_bpol=1 -- send bit at rising edge, lrpol=1 -- left channel start at rising edge
	.msb_delay_bits(4'd1), 			// msb delay bits, 0 -- left-justified, 1 -- standard 
	.bclk_o(), .lrclk_o(), 
	.bclk_i(bclk), .lrclk_i(lrclk), 
	.bdiv(32'd13), .lrbdiv(32'd32), 
	.enable_master(1'b0), 
	.enable(1'b1), 
	.rstn(rstn), .clk(clk_112m), .test_se(1'b0) 
);

always@(*) u1_iis_rx = u0_iis_tx;
always@(*) u0_iis_rx = u1_iis_tx;
initial u0_iis_tx_data_l = 32'b10110111011110111110111111011111;
initial u0_iis_tx_data_r = 32'b11111011111101111101111011101101;
initial u1_iis_tx_data_l = 32'b10110111011110111110111111011111;
initial u1_iis_tx_data_r = 32'b11111011111101111101111011101101;
initial u0_iis_tx_data_fill = 1'b0;
initial u0_iis_rx_data_drain = 1'b0;
initial u1_iis_tx_data_fill = 1'b0;
initial u1_iis_rx_data_drain = 1'b0;
always@(posedge clk_112m) if(rstn) begin
	if(u0_iis_tx_data_fill) u0_iis_tx_data_fill = 1'b0;
	else begin
		if(~u0_iis_tx_data_l_full && ~u0_iis_tx_data_r_full && ~u0_iis_tx_data_clear) begin
			u0_iis_tx_data_fill = 1'b1;
			u0_iis_tx_data_l = (u0_iis_tx_data_l == 32'b10110111011110111110111111011111) ? 32'b01001000100001000001000000100000 : 32'b10110111011110111110111111011111;
			u0_iis_tx_data_r = (u0_iis_tx_data_r == 32'b11111011111101111101111011101101) ? 32'b00000100000010000010000100010010 : 32'b11111011111101111101111011101101;
		end
	end
	if(u1_iis_tx_data_fill) u1_iis_tx_data_fill = 1'b0;
	else begin
		if(~u1_iis_tx_data_l_full && ~u1_iis_tx_data_r_full && ~u1_iis_tx_data_clear) begin
			u1_iis_tx_data_fill = 1'b1;
			u1_iis_tx_data_l = (u1_iis_tx_data_l == 32'b11111011111101111101111011101101) ? 32'b00000100000010000010000100010010 : 32'b11111011111101111101111011101101;
			u1_iis_tx_data_r = (u1_iis_tx_data_r == 32'b10110111011110111110111111011111) ? 32'b01001000100001000001000000100000 : 32'b10110111011110111110111111011111;
		end
	end
	if(u0_iis_rx_data_drain) u0_iis_rx_data_drain = 1'b0;
	else begin
		if(~u0_iis_rx_data_l_empty && ~u0_iis_rx_data_r_empty) u0_iis_rx_data_drain = 1'b1;
	end
	if(u1_iis_rx_data_drain) u1_iis_rx_data_drain = 1'b0;
	else begin
		if(~u1_iis_rx_data_l_empty && ~u1_iis_rx_data_r_empty) u1_iis_rx_data_drain = 1'b1;
	end
end
initial begin
	u0_iis_tx_data_clear = 1'b1;
	u0_iis_rx_data_clear = 1'b1;
	u1_iis_tx_data_clear = 1'b1;
	u1_iis_rx_data_clear = 1'b1;
	#35000;
	u0_iis_tx_data_clear = 1'b0;
	u0_iis_rx_data_clear = 1'b0;
	u1_iis_tx_data_clear = 1'b0;
	u1_iis_rx_data_clear = 1'b0;
end

initial begin
	rstn = 0;
	#3000
	rstn = 1;
	for(tb_ph=1;tb_ph<=20;tb_ph++) begin
		#100000
		$display("%d ns",tb_ph*100);
	end	
	rstn = 0;
	#3000
	$finish(2);
end

initial begin
	$dumpfile("../work/iis_tb.fst");
	$dumpvars(0,iis_tb);
end

endmodule

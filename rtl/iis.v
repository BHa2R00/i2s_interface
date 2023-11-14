module iis(
	input rx, 
	output rx_data_r_full, rx_data_r_empty, 
	output rx_data_l_full, rx_data_l_empty, 
	output [1:0] rx_data_l_count, rx_data_r_count, 
	input [1:0] rx_data_depth, 
	input rx_data_drain, rx_data_clear, 
	output [31:0] rx_data_l, rx_data_r, 
	input enable_rx, rx_bpol, rx_lrpol, 	// rx_bpol=1 -- read bit at rising edge, lrpol=1 -- left channel start at rising edge
	output reg tx, 
	output tx_data_r_full, tx_data_r_empty, 
	output tx_data_l_full, tx_data_l_empty, 
	output [1:0] tx_data_l_count, tx_data_r_count, 
	input [1:0] tx_data_depth, 
	input tx_data_fill, tx_data_clear, 
	input [31:0] tx_data_l, tx_data_r, 
	input enable_tx, tx_bpol, tx_lrpol, 	// tx_bpol=1 -- send bit at rising edge, lrpol=1 -- left channel start at rising edge
	input [3:0] msb_delay_bits, // msb delay bits, 0 -- left-justified, 1 -- standard 
	output bclk_o, lrclk_o, 
	input bclk_i, lrclk_i, 
	input [31:0] bdiv, lrbdiv, 
	input enable_master, 
	input enable, 
	input rstn, clk, test_se 
);

reg bclk_r, lrclk_r;
wire bclk = enable_master ? bclk_r : bclk_i;
wire lrclk = enable_master ? lrclk_r : lrclk_i;
reg [31:0] bcnt, lrbcnt;
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		bcnt <= 32'd0;
		bclk_r <= 1'b0;
	end
	else if(enable && enable_master) begin
		if(bcnt == 32'd0) begin
			bcnt <= bdiv;
			bclk_r <= ~bclk_r;
		end
		else bcnt <= bcnt - 32'd1;
	end
end
always@(negedge rstn or negedge bclk) begin
	if(!rstn) begin
		lrbcnt <= 32'd0;
		lrclk_r <= 1'b0;
	end
	else if(enable && enable_master) begin
		if(lrbcnt == 32'd0) begin
			lrbcnt <= lrbdiv;
			lrclk_r <= ~lrclk_r;
		end
		else lrbcnt <= lrbcnt - 32'd1;
	end
end
assign bclk_o = enable_master ? bclk : tx_bpol;
assign lrclk_o = enable_master ? lrclk : tx_lrpol;

wire tx_bclk = tx_bpol ? ~bclk : bclk;
wire rx_bclk = rx_bpol ? bclk : ~bclk;
wire tx_lrclk = tx_lrpol ? lrclk : ~lrclk;
wire rx_lrclk = rx_lrpol ? lrclk : ~lrclk;

wire tx_fifo_l_drain = tx_lrpol ? ~lrclk : lrclk;
wire tx_fifo_r_drain = tx_lrpol ? lrclk : ~lrclk;
wire [31:0] tx_fifo_l_q, tx_fifo_r_q;
fifo324 tx_fifo_l(
	.clear(tx_data_clear), 
	.full(tx_data_l_full), .empty(tx_data_l_empty), 
	.count(tx_data_l_count), 
	.depth(tx_data_depth), 
	.q(tx_fifo_l_q), 
	.d(tx_data_l), 
	.rstn(rstn), .fill(tx_data_fill), .drain(tx_fifo_l_drain), .clk(clk), .test_se(test_se) 
);
fifo324 tx_fifo_r(
	.clear(tx_data_clear), 
	.full(tx_data_r_full), .empty(tx_data_r_empty), 
	.count(tx_data_r_count), 
	.depth(tx_data_depth), 
	.q(tx_fifo_r_q), 
	.d(tx_data_r), 
	.rstn(rstn), .fill(tx_data_fill), .drain(tx_fifo_r_drain), .clk(clk), .test_se(test_se) 
);
wire rx_fifo_l_fill = rx_lrpol ? ~lrclk : lrclk;
wire rx_fifo_r_fill = rx_lrpol ? lrclk : ~lrclk;
reg [31:0] rx_fifo_l_d, rx_fifo_r_d;
fifo324 rx_fifo_l(
	.clear(rx_data_clear), 
	.full(rx_data_l_full), .empty(rx_data_l_empty), 
	.count(rx_data_l_count), 
	.depth(rx_data_depth), 
	.q(rx_data_l), 
	.d(rx_fifo_l_d), 
	.rstn(rstn), .fill(rx_fifo_l_fill), .drain(rx_data_drain), .clk(clk), .test_se(test_se) 
);
fifo324 rx_fifo_r(
	.clear(rx_data_clear), 
	.full(rx_data_r_full), .empty(rx_data_r_empty), 
	.count(rx_data_r_count), 
	.depth(rx_data_depth), 
	.q(rx_data_r), 
	.d(rx_fifo_r_d), 
	.rstn(rstn), .fill(rx_fifo_r_fill), .drain(rx_data_drain), .clk(clk), .test_se(test_se) 
);

// tx links
reg tx_l_start, tx_l_start_drain;
reg tx_r_start, tx_r_start_drain;
reg tx_l_trans, tx_l_trans_drain;
reg tx_r_trans, tx_r_trans_drain;

// tx left start link
wire tx_l_start_fill = tx_fifo_l_drain && ~tx_data_l_empty;
wire tx_l_start_clk = test_se ? clk : tx_l_start ? tx_l_start_drain : tx_l_start_fill;
always@(negedge rstn or posedge tx_l_start_clk) begin
	if(!rstn) tx_l_start <= 1'b0;
	else if(enable && enable_tx) tx_l_start <= ~tx_l_start;
end

// tx right start link
wire tx_r_start_fill = tx_fifo_r_drain && ~tx_data_r_empty;
wire tx_r_start_clk = test_se ? clk : tx_r_start ? tx_r_start_drain : tx_r_start_fill;
always@(negedge rstn or posedge tx_r_start_clk) begin
	if(!rstn) tx_r_start <= 1'b0;
	else if(enable && enable_tx) tx_r_start <= ~tx_r_start;
end

// tx left msb delay
reg [3:0] tx_prvsb;
wire tx_prvsb_clk = test_se ? clk : (tx_l_start||tx_r_start) ? ~tx_bclk : (tx_l_start_fill||tx_r_start_fill);
always@(negedge rstn or posedge tx_prvsb_clk) begin
	if(!rstn) tx_prvsb <= 4'd0;
	else if(enable && enable_tx) begin
		if(tx_l_start||tx_r_start) tx_prvsb <= tx_prvsb + 4'd1;
		else tx_prvsb <= 4'd0;
	end
end
always@(*) tx_l_start_drain = (tx_prvsb == msb_delay_bits) && tx_l_start && ~tx_l_trans;
always@(*) tx_r_start_drain = (tx_prvsb == msb_delay_bits) && tx_r_start && ~tx_r_trans;

// tx left trans link
wire tx_l_trans_fill = tx_l_start_drain;
wire tx_l_trans_clk = test_se ? clk : tx_l_trans ? tx_l_trans_drain : tx_l_trans_fill;
always@(negedge rstn or posedge tx_l_trans_clk) begin
	if(!rstn) tx_l_trans <= 1'b0;
	else if(enable && enable_tx) tx_l_trans <= ~tx_l_trans;
end

// tx right trans link
wire tx_r_trans_fill = tx_r_start_drain;
wire tx_r_trans_clk = test_se ? clk : tx_r_trans ? tx_r_trans_drain : tx_r_trans_fill;
always@(negedge rstn or posedge tx_r_trans_clk) begin
	if(!rstn) tx_r_trans <= 1'b0;
	else if(enable && enable_tx) tx_r_trans <= ~tx_r_trans;
end

// tx counter 
reg [4:0] tx_sb;
wire tx_sb_clk = test_se ? clk : (tx_l_trans||tx_r_trans) ? ~tx_bclk : (tx_l_trans_fill||tx_r_trans_fill);
always@(negedge rstn or posedge tx_sb_clk) begin
	if(!rstn) tx_sb <= 5'd0;
	else if(enable && enable_tx) begin
		if(tx_l_trans||tx_r_trans) tx_sb <= tx_sb - 5'd1;
		else tx_sb <= 5'd31;
	end
end
always@(*) tx = tx_lrclk ? tx_fifo_l_q[tx_sb] : tx_fifo_r_q[tx_sb];
always@(*) tx_l_trans_drain = ((tx_sb == 5'd0) || tx_r_start_fill) && tx_l_trans;
always@(*) tx_r_trans_drain = ((tx_sb == 5'd0) || tx_l_start_fill) && tx_r_trans;

// rx links
reg rx_l_start, rx_l_start_drain;
reg rx_r_start, rx_r_start_drain;
reg rx_l_trans, rx_l_trans_drain;
reg rx_r_trans, rx_r_trans_drain;

// rx left start link
wire rx_l_start_fill = rx_fifo_l_fill && ~rx_data_l_full;
wire rx_l_start_clk = test_se ? clk : rx_l_start ? rx_l_start_drain : rx_l_start_fill;
always@(negedge rstn or posedge rx_l_start_clk) begin
	if(!rstn) rx_l_start <= 1'b0;
	else if(enable && enable_rx) rx_l_start <= ~rx_l_start;
end

// rx right start link
wire rx_r_start_fill = rx_fifo_r_fill && ~rx_data_r_full;
wire rx_r_start_clk = test_se ? clk : rx_r_start ? rx_r_start_drain : rx_r_start_fill;
always@(negedge rstn or posedge rx_r_start_clk) begin
	if(!rstn) rx_r_start <= 1'b0;
	else if(enable && enable_rx) rx_r_start <= ~rx_r_start;
end

// rx left msb delay
reg [3:0] rx_prvsb;
wire rx_prvsb_clk = test_se ? clk : (rx_l_start||rx_r_start) ? rx_bclk : (rx_l_start_fill||rx_r_start_fill);
always@(negedge rstn or posedge rx_prvsb_clk) begin
	if(!rstn) rx_prvsb <= 4'd0;
	else if(enable && enable_rx) begin
		if(rx_l_start||rx_r_start) rx_prvsb <= rx_prvsb + 4'd1;
		else rx_prvsb <= 4'd0;
	end
end
always@(*) rx_l_start_drain = (rx_prvsb == msb_delay_bits) && rx_l_start && ~rx_l_trans;
always@(*) rx_r_start_drain = (rx_prvsb == msb_delay_bits) && rx_r_start && ~rx_r_trans;

// rx left trans link
wire rx_l_trans_fill = rx_l_start_drain;
wire rx_l_trans_clk = test_se ? clk : rx_l_trans ? rx_l_trans_drain : rx_l_trans_fill;
always@(negedge rstn or posedge rx_l_trans_clk) begin
	if(!rstn) rx_l_trans <= 1'b0;
	else if(enable && enable_rx) rx_l_trans <= ~rx_l_trans;
end

// rx right trans link
wire rx_r_trans_fill = rx_r_start_drain;
wire rx_r_trans_clk = test_se ? clk : rx_r_trans ? rx_r_trans_drain : rx_r_trans_fill;
always@(negedge rstn or posedge rx_r_trans_clk) begin
	if(!rstn) rx_r_trans <= 1'b0;
	else if(enable && enable_rx) rx_r_trans <= ~rx_r_trans;
end

// rx counter 
reg [4:0] rx_sb;
wire rx_sb_clk = test_se ? clk : (rx_l_trans||rx_r_trans) ? rx_bclk : (rx_l_trans_fill||rx_r_trans_fill);
always@(negedge rstn or posedge rx_sb_clk) begin
	if(!rstn) begin
		rx_sb <= 5'd0;
		rx_fifo_l_d <= 32'd0;
		rx_fifo_r_d <= 32'd0;
	end
	else if(enable && enable_rx) begin
		if(rx_l_trans||rx_r_trans) rx_sb <= rx_sb - 5'd1;
		else rx_sb <= 5'd31;
		if(rx_lrclk) rx_fifo_l_d[rx_sb] <= rx;
		if(~rx_lrclk) rx_fifo_r_d[rx_sb] <= rx;
	end
end
always@(*) rx_l_trans_drain = ((rx_sb == 5'd0) || rx_r_start_fill) && rx_l_trans;
always@(*) rx_r_trans_drain = ((rx_sb == 5'd0) || rx_l_start_fill) && rx_r_trans;

endmodule

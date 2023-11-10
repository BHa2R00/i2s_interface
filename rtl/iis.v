module iis(
	input rx, 
	output rx_data_r_full, rx_data_r_empty, 
	output rx_data_l_full, rx_data_l_empty, 
	output [2:0] rx_data_l_count, rx_data_r_count, 
	input [2:0] rx_data_depth, 
	input rx_data_drain, rx_data_clear, 
	output [31:0] rx_data_l, rx_data_r, 
	input enable_rx, rx_bpol, rx_lrpol, 	// rx_bpol=1 -- read bit at rising edge, lrpol=1 -- left channel start at rising edge
	output reg tx, 
	output tx_data_r_full, tx_data_r_empty, 
	output tx_data_l_full, tx_data_l_empty, 
	output [2:0] tx_data_l_count, tx_data_r_count, 
	input [2:0] tx_data_depth, 
	input tx_data_fill, tx_data_clear, 
	input [31:0] tx_data_l, tx_data_r, 
	input enable_tx, tx_bpol, tx_lrpol, 	// tx_bpol=1 -- send bit at rising edge, lrpol=1 -- left channel start at rising edge
	input [3:0] msb_delay_bits, 			// msb delay bits, 0 -- left-justified, 1 -- standard 
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
always@(negedge rstn or posedge bclk) begin
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

reg [1:0] bclk_d, lrclk_d;
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		bclk_d <= 2'b00;
		lrclk_d <= 2'b00;
	end 
	else if(enable) begin
		bclk_d[1] <= bclk_d[0];
		bclk_d[0] <= bclk;
		lrclk_d[1] <= lrclk_d[0];
		lrclk_d[0] <= lrclk;
	end
end
wire bclk_01 = bclk_d == 2'b01;
wire bclk_10 = bclk_d == 2'b10;
wire lrclk_01 = lrclk_d == 2'b01;
wire lrclk_10 = lrclk_d == 2'b10;

wire tx_fifo_l_drain = tx_lrpol ? lrclk_10 : lrclk_01;
wire tx_fifo_r_drain = tx_lrpol ? lrclk_01 : lrclk_10;
wire [31:0] tx_fifo_l_q, tx_fifo_r_q;
fifo328 tx_fifo_l(
	.clear(tx_data_clear), 
	.full(tx_data_l_full), .empty(tx_data_l_empty), 
	.count(tx_data_l_count), 
	.depth(tx_data_depth), 
	.q(tx_fifo_l_q), 
	.d(tx_data_l), 
	.rstn(rstn), .fill(tx_data_fill), .drain(tx_fifo_l_drain), .clk(clk), .test_se(test_se) 
);
fifo328 tx_fifo_r(
	.clear(tx_data_clear), 
	.full(tx_data_r_full), .empty(tx_data_r_empty), 
	.count(tx_data_r_count), 
	.depth(tx_data_depth), 
	.q(tx_fifo_r_q), 
	.d(tx_data_r), 
	.rstn(rstn), .fill(tx_data_fill), .drain(tx_fifo_r_drain), .clk(clk), .test_se(test_se) 
);
wire rx_fifo_l_fill = rx_lrpol ? lrclk_10 : lrclk_01;
wire rx_fifo_r_fill = rx_lrpol ? lrclk_01 : lrclk_10;
reg [31:0] rx_fifo_l_d, rx_fifo_r_d;
fifo328 rx_fifo_l(
	.clear(rx_data_clear), 
	.full(rx_data_l_full), .empty(rx_data_l_empty), 
	.count(rx_data_l_count), 
	.depth(rx_data_depth), 
	.q(rx_data_l), 
	.d(rx_fifo_l_d), 
	.rstn(rstn), .fill(rx_fifo_l_fill), .drain(rx_data_drain), .clk(clk), .test_se(test_se) 
);
fifo328 rx_fifo_r(
	.clear(rx_data_clear), 
	.full(rx_data_r_full), .empty(rx_data_r_empty), 
	.count(rx_data_r_count), 
	.depth(rx_data_depth), 
	.q(rx_data_r), 
	.d(rx_fifo_r_d), 
	.rstn(rstn), .fill(rx_fifo_r_fill), .drain(rx_data_drain), .clk(clk), .test_se(test_se) 
);

localparam
	start = (2'd2 ^ (2'd2 >> 1)),
	trans = (2'd1 ^ (2'd1 >> 1)),
	idle = 2'd0;

reg [4:0] tx_sb, rx_sb;
reg [3:0] tx_msbcnt, rx_msbcnt;
wire tx_msb_start = tx_msbcnt == 4'd0;
wire rx_msb_start = rx_msbcnt == 4'd0;
wire tx_irq = tx_bpol ? bclk_01 : bclk_10;
wire rx_irq = rx_bpol ? bclk_01 : bclk_10;
wire tx_start = tx_msb_start && tx_irq;
wire rx_start = rx_msb_start && rx_irq;
wire tx_l_start = tx_start && (tx_lrpol ? lrclk : ~lrclk);
wire rx_l_start = rx_start && (rx_lrpol ? lrclk : ~lrclk);
wire tx_r_start = tx_start && (tx_lrpol ? ~lrclk : lrclk);
wire rx_r_start = rx_start && (rx_lrpol ? ~lrclk : lrclk);
wire tx_l_end = tx_lrpol ? lrclk_10 : lrclk_01;
wire rx_l_end = rx_lrpol ? lrclk_10 : lrclk_01;
wire tx_r_end = tx_lrpol ? lrclk_01 : lrclk_10;
wire rx_r_end = rx_lrpol ? lrclk_01 : lrclk_10;
reg [1:0] tx_l_cst, tx_r_cst, rx_l_cst, rx_r_cst;
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		tx <= 1'b0;
		tx_sb <= 5'd0;
		tx_msbcnt <= 4'd0;
		tx_l_cst <= idle;
		tx_r_cst <= idle;
		rx_fifo_l_d <= 32'd0;
		rx_fifo_r_d <= 32'd0;
		rx_sb <= 5'd0;
		rx_msbcnt <= 4'd0;
		rx_l_cst <= idle;
		rx_r_cst <= idle;
	end
	else if(enable) begin
		if(enable_rx) begin	
			case(rx_l_cst)
				idle: begin
					if(rx_r_end && ~rx_data_l_full) begin
						rx_sb <= 5'd31;
						rx_msbcnt <= msb_delay_bits;
						rx_fifo_l_d <= 32'd0;
						rx_l_cst <= start;
					end
				end
				start: begin
					if(rx_l_start) begin
						rx_sb <= rx_sb - 5'd1;
						rx_fifo_l_d[rx_sb] <= rx;
						rx_l_cst <= trans;
					end
					else if(rx_irq) rx_msbcnt <= rx_msbcnt - 4'd1;
				end
				trans: begin
					if(rx_irq) begin
						rx_fifo_l_d[rx_sb] <= rx;
						if(rx_sb == 5'd0 || rx_l_end) rx_l_cst <= idle;
						else rx_sb <= rx_sb - 5'd1;
					end
				end
				default: begin
					rx_fifo_l_d <= rx_fifo_l_d;
					rx_sb <= rx_sb;
					rx_msbcnt <= rx_msbcnt;
					rx_l_cst <= idle;
				end
			endcase
			case(rx_r_cst)
				idle: begin
					if(rx_l_end && ~rx_data_r_full) begin
						rx_sb <= 5'd31;
						rx_msbcnt <= msb_delay_bits;
						rx_fifo_r_d <= 32'd0;
						rx_r_cst <= start;
					end
				end
				start: begin
					if(rx_r_start) begin
						rx_sb <= rx_sb - 5'd1;
						rx_fifo_r_d[rx_sb] <= rx;
						rx_r_cst <= trans;
					end
					else if(rx_irq) rx_msbcnt <= rx_msbcnt - 4'd1;
				end
				trans: begin
					if(rx_irq) begin
						rx_fifo_r_d[rx_sb] <= rx;
						if(rx_sb == 5'd0 || rx_r_end) rx_r_cst <= idle;
						else rx_sb <= rx_sb - 5'd1;
					end
				end
				default: begin
					rx_fifo_r_d <= rx_fifo_r_d;
					rx_sb <= rx_sb;
					rx_msbcnt <= rx_msbcnt;
					rx_r_cst <= idle;
				end
			endcase
		end
		if(enable_tx) begin
			case(tx_l_cst)
				idle: begin
					if(tx_r_end && ~tx_data_l_empty) begin
						tx_sb <= 5'd31;
						tx_msbcnt <= msb_delay_bits;
						tx_l_cst <= start;
					end
				end
				start: begin
					if(tx_l_start) begin
						tx_l_cst <= trans;
						tx <= tx_fifo_l_q[tx_sb];
						tx_sb <= tx_sb - 5'd1;
					end
					else if(tx_irq) tx_msbcnt <= tx_msbcnt - 4'd1;
				end
				trans: begin
					if(tx_irq) begin
						tx <= tx_fifo_l_q[tx_sb];
						if(tx_sb == 5'd0 || tx_l_end) tx_l_cst <= idle;
						else tx_sb <= tx_sb - 5'd1;
					end
				end
				default: begin
					tx <= tx;
					tx_sb <= tx_sb;
					tx_msbcnt <= tx_msbcnt;
					tx_l_cst <= idle;
				end
			endcase
			case(tx_r_cst)
				idle: begin
					if(tx_l_end && ~tx_data_r_empty) begin
						tx_sb <= 5'd31;
						tx_msbcnt <= msb_delay_bits;
						tx_r_cst <= start;
					end
				end
				start: begin
					if(tx_r_start) begin
						tx_r_cst <= trans;
						tx <= tx_fifo_r_q[tx_sb];
						tx_sb <= tx_sb - 5'd1;
					end
					else if(tx_irq) tx_msbcnt <= tx_msbcnt - 4'd1;
				end
				trans: begin
					if(tx_irq) begin
						tx <= tx_fifo_r_q[tx_sb];
						if(tx_sb == 5'd0 || tx_r_end) tx_r_cst <= idle;
						else tx_sb <= tx_sb - 5'd1;
					end
				end
				default: begin
					tx <= tx;
					tx_sb <= tx_sb;
					tx_msbcnt <= tx_msbcnt;
					tx_r_cst <= idle;
				end
			endcase	
		end
	end
end

endmodule

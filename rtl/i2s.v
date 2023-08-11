module i2s (
	input master_enable, 
	input sdin, 
	output reg [31:0] dout_l, dout_r, 
	output sdout, 
	input [31:0] din_l, din_r, 
	input bclk_i, lrclk_i, 
	output bclk_o, lrclk_o, 
	input [19:0] bdiv, 
	input [7:0] lrdiv, 
	output reg [2:0] cst, nst, 
	input rstn, clk
);

reg bclk;
reg [19:0] bcnt;
always @(negedge rstn or posedge clk) begin
	if(!rstn) begin
		bcnt <= 20'd0;
		bclk <= 1'b0;
	end
	else begin
		if(master_enable) begin
			if(bcnt == 20'd0) begin
				bcnt <= bdiv;
				bclk <= ~bclk;
			end
			else bcnt <= bcnt - 20'd1;
		end
		else bclk <= bclk_i;
	end
end
assign bclk_o = bclk;

reg bclk_d;
always @(negedge rstn or posedge clk) begin
	if(!rstn) bclk_d <= 1'b0;
	else bclk_d <= bclk;
end
wire bclk_01 = ~bclk_d & bclk;
wire bclk_10 = bclk_d & ~bclk;

reg lrclk;
reg [7:0] lrcnt;
always @(negedge rstn or posedge clk) begin
	if(!rstn) begin
		lrcnt <= 8'd0;
		lrclk <= 1'b0;
	end
	else begin
		if(master_enable) begin
			if(bclk_10) begin
				if(lrcnt == 8'd0) begin
					lrcnt <= lrdiv;
					lrclk <= ~lrclk;
				end
				else lrcnt <= lrcnt - 8'd1;
			end
		end
		else lrclk <= lrclk_i;
	end
end
assign lrclk_o = lrclk;

reg lrclk_d;
always @(negedge rstn or posedge clk) begin
	if(!rstn) lrclk_d <= 1'b0;
	else lrclk_d <= lrclk;
end
wire lrclk_01 = ~lrclk_d & lrclk;
wire lrclk_10 = lrclk_d & ~lrclk;

localparam
	start_l = 3'd5, channel_l = 3'd4, idle_l = 3'd3, 
	start_r = 3'd2, channel_r = 3'd1, idle_r = 3'd0;
reg [4:0] channel_cnt;
always @(negedge rstn or posedge clk) begin
	if(!rstn) cst <= idle_r;
	else cst <= nst;
end
always @(*) begin
	case(cst)
		idle_l: nst = lrclk_01 ? start_r : cst;
		start_r: nst = bclk_10 ? channel_r : cst;
		channel_r: nst = bclk_10 & (channel_cnt == 5'd31) ? idle_r : cst;
		idle_r: nst = lrclk_10 ? start_l : cst;
		start_l: nst = bclk_10 ? channel_l : cst;
		channel_l: nst = bclk_10 & (channel_cnt == 5'd31) ? idle_l : cst;
		default: nst = cst;
	endcase
end
always @(negedge rstn or posedge clk) begin
	if(!rstn) channel_cnt <= 5'd31;
	else if(bclk_10) 
		channel_cnt <= ((cst == channel_l) | (cst == channel_r)) ? 5'd1 + channel_cnt : 5'd0;
end
assign sdout = 
	(cst == channel_l) ? din_l[channel_cnt] : 
	(cst == channel_r) ? din_r[channel_cnt] :
	1'b0;
always @(negedge rstn or posedge clk) begin
	if(!rstn) begin
		dout_l <= 32'd0;
		dout_r <= 32'd0;
	end
	else begin
		case(nst)
			channel_l: dout_l[channel_cnt] <= sdin;
			channel_r: dout_r[channel_cnt] <= sdin;
			default: {dout_l, dout_r} <= {dout_l, dout_r};
		endcase
	end
end

endmodule

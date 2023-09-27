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


module ahb_i2s (
	input din_l_dam_ack, din_r_dam_ack, 
	output din_l_dam_req, din_r_dam_req, 
	input dout_l_dam_ack, dout_r_dam_ack, 
	output dout_l_dam_req, dout_r_dam_req, 
	input sdin, 
	output reg sdout, 
	input bclk_i, lrclk_i, 
	output bclk_o, lrclk_o, 
	input we, sel, 
	output [31:0] rdata, 
	input [31:0] wdata, addr,
	input rstn, clk
);

reg [31:0] dout_l, dout_r;
reg [31:0] din_l, din_r;
reg din_dma_mode, dout_dma_mode;
reg [15:0] bdiv;
reg [7:0] lrdiv;
reg [2:0] cst, nst;
reg master;
reg enable; 

reg bclk;
reg [15:0] bcnt;
always @(negedge rstn or posedge clk) begin
	if(!rstn) begin
		bcnt <= 16'd0;
		bclk <= 1'b0;
	end
	else if(enable) begin
		if(master) begin
			if(bcnt == 16'd0) begin
				bcnt <= bdiv;
				bclk <= ~bclk;
			end
			else bcnt <= bcnt - 16'd1;
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
	else if(enable) begin
		if(master) begin
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
	else if(enable) cst <= nst;
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
always@(negedge rstn or posedge clk) begin
	if(!rstn) sdout <= 1'b0;
	else if(enable) begin
		case(cst)
			channel_l: sdout <= din_l[channel_cnt];
			channel_r: sdout <= din_r[channel_cnt];
			default: sdout <= sdout;
		endcase
	end
end
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		dout_l <= 32'd0;
		dout_r <= 32'd0;
	end
	else if(enable) begin
		if(bclk_10)
			case(nst)
				channel_l: dout_l[channel_cnt] <= sdin;
				channel_r: dout_r[channel_cnt] <= sdin;
				default: {dout_l, dout_r} <= {dout_l, dout_r};
			endcase
	end
end

wire din_l_drain = (cst == idle_l);
reg din_l_full, din_l_fill;
wire din_l_ck = din_l_full ? din_l_drain : (din_dma_mode ? din_l_dam_ack : din_l_fill);
always@(negedge rstn or posedge din_l_ck) begin
	if(!rstn) din_l_full <= 1'b0;
	else din_l_full <= ~din_l_full;
end
assign din_l_dam_req = din_l_full;

wire din_r_drain = (cst == idle_r);
reg din_r_full, din_r_fill;
wire din_r_ck = din_r_full ? din_r_drain : (din_dma_mode ? din_r_dam_ack : din_r_fill);
always@(negedge rstn or posedge din_r_ck) begin
	if(!rstn) din_r_full <= 1'b0;
	else din_r_full <= ~din_r_full;
end
assign din_r_dam_req = din_r_full;

wire dout_l_fill = (cst == idle_l);
reg dout_l_full, dout_l_drain;
wire dout_l_ck = dout_l_full ? (dout_dma_mode ? dout_l_dam_ack : dout_l_drain) : dout_l_fill;
always@(negedge rstn or posedge dout_l_ck) begin
	if(!rstn) dout_l_full <= 1'b0;
	else dout_l_full <= ~dout_l_full;
end
assign dout_l_dam_req = dout_l_full;

wire dout_r_fill = (cst == idle_r);
reg dout_r_full, dout_r_drain;
wire dout_r_ck = dout_r_full ? (dout_dma_mode ? dout_r_dam_ack : dout_r_drain) : dout_r_fill;
always@(negedge rstn or posedge dout_r_ck) begin
	if(!rstn) dout_r_full <= 1'b0;
	else dout_r_full <= ~dout_r_full;
end
assign dout_r_dam_req = dout_r_full;

wire sel_ctrl 		= sel && (addr == 32'h00000000);
wire sel_dout_l 	= sel && (addr == 32'h00000001);
wire sel_dout_r 	= sel && (addr == 32'h00000002);
wire sel_din_l 		= sel && (addr == 32'h00000003);
wire sel_din_r 		= sel && (addr == 32'h00000004);

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		din_l_fill <= 1'b0;
		din_r_fill <= 1'b0;
		dout_l_drain <= 1'b0;
		dout_r_drain <= 1'b0;
		din_l <= 32'h00000000;
		din_r <= 32'h00000000;
	end
	else if(we) begin
		if(sel_ctrl) begin
			{
			enable,
			master,
			din_dma_mode,dout_dma_mode,
			din_l_fill,din_r_fill,dout_l_drain,dout_r_drain,
			lrdiv,bdiv
			} <= wdata;
		end
		else begin
			din_l_fill <= 1'b0;
			din_r_fill <= 1'b0;
			dout_l_drain <= 1'b0;
			dout_r_drain <= 1'b0;
			if(sel_din_l) din_l <= wdata;
			else if(sel_din_r) din_r <= wdata;
		end
	end
	else begin
		din_l_fill <= 1'b0;
		din_r_fill <= 1'b0;
		dout_l_drain <= 1'b0;
		dout_r_drain <= 1'b0;
	end
end

assign rdata = 
	sel_ctrl ? {
		enable,
		master,
		din_dma_mode,dout_dma_mode,
		din_l_full,din_r_full,dout_l_full,dout_r_full,
		lrdiv,bdiv
		} : 
	sel_dout_l ? dout_l : 
	sel_dout_r ? dout_r : 
	sel_din_l ? din_l : 
	sel_din_r ? din_r : 
	32'h00000000;

endmodule

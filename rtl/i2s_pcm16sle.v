module i2s_mono(
	output full, 
	output reg [1:0] cst, nst, 
	input push, pop, 
	input bclk, lrclk, 
	output reg signed [15:0] rx_pcm, 
	input rx, 
	output tx, 
	input signed [15:0] tx_pcm, 
	input [4:0] align, // left = 16, standard = 15, right: depends
	input sel_rx, 
	input enable, 
	input rstn, clk 
);

reg sel_tx;
reg signed [5:0] bth;
reg [16:0] pcm;
wire for_enable = bth < 16;
wire for_end = bth < 0;
assign tx = pcm[16];
wire [16:0] ash_pcm = {pcm[15:0], rx};
wire signed [5:0] bth0 = 31 - {1'b0, align};

`ifndef GRAY
	`define GRAY(X) (X^(X>>1))
`endif
localparam [1:0]
	st_bth	= `GRAY(3),
	st_bit	= `GRAY(2),
	st_load	= `GRAY(1),
	st_idle	= `GRAY(0);
reg bclk_d, lrclk_d, push_d, pop_d;
always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		bclk_d <= 1'b0;
		lrclk_d <= 1'b0;
		push_d <= 1'b0;
		pop_d <= 1'b0;
	end
	else if(enable) begin
		bclk_d <= bclk;
		lrclk_d <= lrclk;
		push_d <= push;
		pop_d <= pop;
	end
end
wire bclk_01 = {bclk_d, bclk} == 2'b01;
wire bclk_10 = {bclk_d, bclk} == 2'b10;
wire lrclk_x = lrclk_d ^ lrclk;
wire push_x = push_d ^ push;
wire pop_x = pop_d ^ pop;
always@(negedge rstn or posedge clk) begin
	if(!rstn) cst <= st_idle;
	else if(enable) cst <= nst;
end
always@(*) begin
	case(cst)
		st_idle: nst = (sel_tx ? push_x : pop_x) ? st_load : cst;
		st_load: nst = lrclk_x ? st_bit : cst;
		st_bit: nst = bclk_10 ? (for_end ? st_idle : st_bth) : cst;
		st_bth: nst = bclk_01 ? st_bit : cst;
		default: nst = st_idle;
	endcase
end

assign full = cst == st_idle;

always@(negedge rstn or posedge clk) begin
	if(!rstn) sel_tx <= 1'b0;
	else if(enable) begin
		case(nst)
			st_idle: sel_tx <= ~sel_rx;
			default: sel_tx <= sel_tx;
		endcase
	end
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) bth <= 0;
	else if(enable) begin
		case(nst)
			st_load: bth <= bth0;
			st_bth: if(bclk_10) bth <= bth - 1;
			default: bth <= bth;
		endcase
	end
	else bth <= 0;
end

always@(negedge rstn or posedge clk) begin
	if(!rstn) begin
		pcm <= 0;
		rx_pcm <= 0;
	end
	else if(enable) begin
		case(nst)
			st_load: begin
				if(sel_tx) pcm[15:0] <= tx_pcm;
				else rx_pcm <= pcm[15:0];
			end
			st_bit, st_bth: begin
				if(sel_tx) begin
					if(bclk_10 && for_enable) pcm <= ash_pcm;
				end
				else begin
					if(bclk_01 && for_enable) pcm <= ash_pcm;
				end
			end
			default: begin
				pcm <= pcm;
				rx_pcm <= rx_pcm;
			end
		endcase
	end
	else begin
		pcm <= 0;
		rx_pcm <= 0;
	end
end

endmodule

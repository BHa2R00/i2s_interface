module fifo328(
	input clear, 
	output full, empty, 
	output [2:0] count, 
	input [2:0] depth, 
	output [31:0] q, 
	input [31:0] d, 
	input rstn, fill, drain, clk, test_se 
);

reg [2:0] a1, a0;
assign count = a1 - a0;
assign full = count == depth;
assign empty = count == 3'd0;
wire [2:0] lst_a0 = a0 - 3'd1;
wire [2:0] a = a1 ^ (a1<<1);
wire [2:0] lst_a = lst_a0 ^ (lst_a0<<1);
reg [31:0] r[0:7];
wire clk1 = test_se ? clk : fill;
always@(negedge rstn or posedge clk1) begin
	if(!rstn) begin
		a1 <= 3'd0;
		r[0] <= 32'd0; 
		r[1] <= 32'd0; 
		r[2] <= 32'd0; 
		r[3] <= 32'd0; 
		r[4] <= 32'd0; 
		r[5] <= 32'd0; 
		r[6] <= 32'd0; 
		r[7] <= 32'd0; 
	end
	else if(!full) begin
		r[a] <= d;
		a1 <= clear ? 3'd0 : a1 + 3'd1;
	end
end
wire clk0 = test_se ? clk : drain;
always@(negedge rstn or posedge clk0) begin
	if(!rstn) a0 <= 3'd0;
	else if(!empty) a0 <= clear ? 3'd0 : a0 + 3'd1;
end
assign q = r[lst_a];

endmodule

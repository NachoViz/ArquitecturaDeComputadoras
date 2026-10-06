module ff(
	input clk,
	input ar,
	input d,
	output reg q
);

	always@ ( posedge clk or negedge ar) begin
		if(!ar)
			q <= 0;
		else 
			q <= d;

	end
endmodule

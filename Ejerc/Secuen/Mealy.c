module top_module ( input clk, input reset, input in, output y ); 

localparam S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
reg [1:0] state;

always @(posedge clk) begin
    if (reset) begin
        state <= S0;
    end else begin
        case (state)
            S0: state <= in ? S1 : S0;
            S1: state <= in ? S1 : S2;
            S2: state <= in ? S3 : S0;
            S3: state <= in ? S1 : S2; // overlap: reuse trailing "1" instead of resetting to S0
            default: state <= S0;
        endcase
    end
end

// Mealy output: asserted combinationally on the S3 --in=1--&gt; transition
assign y = (state == S3 && in);


endmodule

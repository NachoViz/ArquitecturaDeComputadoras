module top_module (
    input clk,
    input reset,
    input up_down,
    output reg [3:0] count
);

    always @(posedge clk) begin
        if (reset)
            count <= 4'd0;
        else if (up_down)
            count <= count + 1'b1;
        else
            count <= count - 1'b1;
    end

endmodule
